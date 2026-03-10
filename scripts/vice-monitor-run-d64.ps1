[CmdletBinding()]
param(
    [string]$ImagePath = ".\citybuilder.d64",
    [string]$ProgramName = "CITYBUILDER",
    [string]$MonitorHost = "127.0.0.1",
    [int]$MonitorPort = 6510,
    [int]$BootDelaySeconds = 3,
    [int]$LaunchDelaySeconds = 5
)

$ErrorActionPreference = "Stop"

$resolvedImage = (Resolve-Path -Path $ImagePath).Path
$ncat = (Get-Command ncat.exe -ErrorAction Stop).Source

& {
    'reset 1'
    Start-Sleep -Seconds 1

    # Let the KERNAL finish its reset path before we touch BASIC memory.
    'g'
    Start-Sleep -Seconds $BootDelaySeconds

    'attach "' + $resolvedImage + '" 8'
    Start-Sleep -Seconds 1

    'loadbasic "' + $ProgramName + '" 8'
    Start-Sleep -Seconds 1

    'g 080d'
    Start-Sleep -Seconds $LaunchDelaySeconds

    'x'
} | & $ncat $MonitorHost $MonitorPort
