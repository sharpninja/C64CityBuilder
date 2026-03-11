from __future__ import annotations

import re
import statistics
from dataclasses import dataclass
from pathlib import Path

import fitz


@dataclass
class ChapterInfo:
    number: int
    start_page: int  # 1-based PDF page number
    title: str
    source: str


@dataclass
class TocChapter:
    number: int
    book_page: int
    title: str


def normalize_whitespace(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def clean_heading_title(value: str) -> str:
    value = re.split(r"[•▪●]", value, maxsplit=1)[0]
    value = value.replace("", " ")
    value = re.sub(r"\.{2,}.*$", "", value)
    return normalize_whitespace(value).strip(" -:\t.")


def slugify(value: str, fallback: str) -> str:
    normalized = normalize_whitespace(value).lower()
    slug = re.sub(r"[^a-z0-9]+", "-", normalized).strip("-")
    return slug or fallback


def detect_heading_chapters(doc: fitz.Document) -> dict[int, ChapterInfo]:
    chapters: dict[int, ChapterInfo] = {}
    chapter_pattern = re.compile(r"(?i)^chapter\s+(\d+)\b[.\-: ]*(.*)$")

    for page_index in range(doc.page_count):
        text = doc[page_index].get_text("text")
        if "contents" in text.lower() and len(re.findall(r"(?i)\bchapter\s+\d+\b", text)) > 2:
            continue

        lines = [line.strip() for line in text.splitlines() if line.strip()]
        top_lines = lines[:12]

        for line_idx, line in enumerate(top_lines):
            match = chapter_pattern.match(line)
            if not match:
                continue

            chapter_number = int(match.group(1))
            if chapter_number in chapters:
                break

            title = clean_heading_title(match.group(2))
            if not title:
                title_parts: list[str] = []
                for next_line in top_lines[line_idx + 1 : line_idx + 8]:
                    if re.match(r"(?i)^chapter\s+\d+\b", next_line):
                        break
                    if re.fullmatch(r"\d+", next_line):
                        break
                    if next_line.upper() == "INTRODUCTION":
                        break

                    cleaned_next = clean_heading_title(next_line)
                    if cleaned_next:
                        title_parts.append(cleaned_next)

                    if re.search(r"[•▪●]", next_line):
                        break
                    if len(title_parts) >= 5:
                        break

                title = normalize_whitespace(" ".join(title_parts))
            if not title:
                title = f"Chapter {chapter_number}"

            chapters[chapter_number] = ChapterInfo(
                number=chapter_number,
                start_page=page_index + 1,
                title=title,
                source="heading",
            )
            break

    return chapters


def parse_toc_chapters(doc: fitz.Document) -> dict[int, TocChapter]:
    max_search_page = min(20, doc.page_count)
    contents_page: int | None = None

    for page_number in range(1, max_search_page + 1):
        text = doc[page_number - 1].get_text("text").lower()
        if "contents" in text and "chapter" in text:
            contents_page = page_number
            break

    if contents_page is None:
        return {}

    toc_chapters: dict[int, TocChapter] = {}
    prev_book_page = -1
    current: dict[str, object] | None = None
    chapter_pattern = re.compile(r"(?i)^chapter\s+(\d+)\.?\s*(.*)$")

    toc_end = min(contents_page + 12, doc.page_count)
    for page_number in range(contents_page, toc_end + 1):
        text = doc[page_number - 1].get_text("text")
        lines = [line.strip() for line in text.splitlines() if line.strip()]

        for line in lines:
            chapter_match = chapter_pattern.match(line)
            if chapter_match:
                current = {
                    "number": int(chapter_match.group(1)),
                    "title_parts": [chapter_match.group(2).strip()] if chapter_match.group(2).strip() else [],
                }
                continue

            if current is None:
                continue

            if re.fullmatch(r"\d+", line):
                candidate_book_page = int(line)
                if candidate_book_page > prev_book_page:
                    title_parts = [part for part in current["title_parts"] if isinstance(part, str)]  # type: ignore[index]
                    title = clean_heading_title(" ".join(title_parts)) or f"Chapter {current['number']}"  # type: ignore[index]
                    number = int(current["number"])  # type: ignore[index]
                    toc_chapters[number] = TocChapter(
                        number=number,
                        book_page=candidate_book_page,
                        title=title,
                    )
                    prev_book_page = candidate_book_page
                    current = None
                else:
                    current["title_parts"].append(line)  # type: ignore[index]
            else:
                if line.lower() in {"contents", "table of contents"}:
                    continue
                current["title_parts"].append(line)  # type: ignore[index]

    return toc_chapters


def merge_chapters(doc: fitz.Document) -> list[ChapterInfo]:
    heading_chapters = detect_heading_chapters(doc)
    toc_chapters = parse_toc_chapters(doc)

    offsets: list[int] = []
    for number, heading in heading_chapters.items():
        toc = toc_chapters.get(number)
        if toc:
            offsets.append(heading.start_page - toc.book_page)

    offset = int(round(statistics.median(offsets))) if offsets else None
    merged = dict(heading_chapters)

    if offset is not None:
        for number, toc in toc_chapters.items():
            if number in merged:
                if merged[number].title.startswith("Chapter ") and toc.title:
                    merged[number].title = toc.title
                continue

            inferred_page = toc.book_page + offset
            if 1 <= inferred_page <= doc.page_count:
                merged[number] = ChapterInfo(
                    number=number,
                    start_page=inferred_page,
                    title=toc.title or f"Chapter {number}",
                    source="toc-inferred",
                )

    chapter_list = sorted(merged.values(), key=lambda item: (item.start_page, item.number))
    unique_pages: set[int] = set()
    deduped: list[ChapterInfo] = []
    for chapter in chapter_list:
        if chapter.start_page in unique_pages:
            continue
        unique_pages.add(chapter.start_page)
        deduped.append(chapter)
    return deduped


def format_page_text(text: str) -> str:
    lines = [line.rstrip() for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n")]
    compacted: list[str] = []
    blank_count = 0
    for line in lines:
        if line.strip():
            blank_count = 0
            compacted.append(line)
        else:
            blank_count += 1
            if blank_count <= 2:
                compacted.append("")
    return "\n".join(compacted).strip()


def write_markdown_for_pdf(pdf_path: Path) -> None:
    doc = fitz.open(pdf_path)
    chapters = merge_chapters(doc)
    if not chapters:
        raise RuntimeError(f"No chapter boundaries detected in {pdf_path.name}")

    output_dir = pdf_path.with_suffix("")
    output_dir.mkdir(exist_ok=True)
    for stale_file in output_dir.glob("chapter-*.md"):
        stale_file.unlink()
    stale_index = output_dir / "index.md"
    if stale_index.exists():
        stale_index.unlink()

    for index, chapter in enumerate(chapters):
        start_page = chapter.start_page
        end_page = doc.page_count if index == len(chapters) - 1 else chapters[index + 1].start_page - 1
        if end_page < start_page:
            continue

        chapter_title = chapter.title or f"Chapter {chapter.number}"
        chapter_slug = slugify(chapter_title, f"chapter-{chapter.number:02d}")
        chapter_file = output_dir / f"chapter-{chapter.number:02d}-{chapter_slug}.md"

        output_parts = [
            f"# Chapter {chapter.number}: {chapter_title}",
            "",
            f"- Source PDF: `{pdf_path.name}`",
            f"- Source page range: PDF pages {start_page} to {end_page}",
            f"- Boundary source: `{chapter.source}`",
            "",
        ]

        has_content = False
        for page_number in range(start_page, end_page + 1):
            page_text = format_page_text(doc[page_number - 1].get_text("text"))
            if not page_text:
                continue
            has_content = True
            output_parts.extend(
                [
                    f"## PDF Page {page_number}",
                    "",
                    page_text,
                    "",
                ]
            )

        if not has_content:
            output_parts.append("_No extractable text was found for this chapter range._")
            output_parts.append("")

        chapter_file.write_text("\n".join(output_parts), encoding="utf-8")

    index_lines = [
        f"# {pdf_path.stem} chapter index",
        "",
        f"Generated from `{pdf_path.name}` ({doc.page_count} PDF pages).",
        "",
        "| Chapter | Title | Start Page | End Page | Source | File |",
        "| --- | --- | ---: | ---: | --- | --- |",
    ]

    for index, chapter in enumerate(chapters):
        start_page = chapter.start_page
        end_page = doc.page_count if index == len(chapters) - 1 else chapters[index + 1].start_page - 1
        chapter_title = chapter.title or f"Chapter {chapter.number}"
        chapter_slug = slugify(chapter_title, f"chapter-{chapter.number:02d}")
        file_name = f"chapter-{chapter.number:02d}-{chapter_slug}.md"
        index_lines.append(
            f"| {chapter.number} | {chapter_title} | {start_page} | {end_page} | {chapter.source} | [{file_name}]({file_name}) |"
        )

    (output_dir / "index.md").write_text("\n".join(index_lines) + "\n", encoding="utf-8")

    print(f"Converted {pdf_path.name} -> {output_dir}")
    for chapter in chapters:
        print(
            f"  Chapter {chapter.number:02d}: page {chapter.start_page:>3} ({chapter.source}) - {chapter.title}"
        )


def main() -> None:
    pdf_files = sorted(Path(".").glob("*.pdf"))
    if not pdf_files:
        raise RuntimeError("No PDF files found in the current directory.")

    for pdf_path in pdf_files:
        write_markdown_for_pdf(pdf_path)


if __name__ == "__main__":
    main()
