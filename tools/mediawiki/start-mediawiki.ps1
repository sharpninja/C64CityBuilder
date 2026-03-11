param(
    [int]$Port = 18080,
    [string]$ContainerName = "c64citybuilder-mediawiki"
)

$ErrorActionPreference = "Stop"

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    throw "Docker is required but was not found in PATH."
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$mediaWikiPath = (Resolve-Path $scriptDir).Path

if (-not (Test-Path (Join-Path $mediaWikiPath "LocalSettings.php"))) {
    throw "LocalSettings.php not found in $mediaWikiPath. Ensure MediaWiki is initialized before starting."
}

$existing = docker ps -a --filter "name=^/${ContainerName}$" --format "{{.ID}}"
if ($existing) {
    docker rm -f $ContainerName | Out-Null
}

Write-Host "Starting container '$ContainerName' on port $Port..."
docker run -d --name $ContainerName -p "${Port}:80" -v "${mediaWikiPath}:/var/www/html" mediawiki:1.43 | Out-Null

Start-Sleep -Seconds 2
docker exec $ContainerName sh -lc "chmod -R a+rwX /var/www/html/data /var/www/html/cache /var/www/html/images /var/www/html/LocalSettings.php" | Out-Null

$status = docker ps --filter "name=^/${ContainerName}$" --format "{{.Status}}"
if (-not $status) {
    throw "Container failed to start. Check docker logs $ContainerName."
}

Write-Host "MediaWiki is running."
Write-Host "URL: http://localhost:$Port/"
Write-Host "Container: $ContainerName ($status)"
Write-Host "To stop: docker rm -f $ContainerName"
