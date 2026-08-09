# make_previews.ps1 - Generate lightweight H.264 previews of every clip
#
# Purpose: DNxHR mezzanine clips do not play in most consumer players
# (VLC, Windows Media Player) without extra codecs. This script produces
# a parallel 'previews\' folder next to each 'segments_*s\' folder with
# small H.264 MP4 previews that play in literally any browser or player.
#
# The DNxHR originals are UNTOUCHED and remain the canonical source for
# Veo/Flow upload. Previews are for human review only.
#
# Usage (from repo root):
#   .\scripts\segment_toolkit\make_previews.ps1 `
#       -InputDir  02_ai_input\friendlikeme_showcase
#
# Options:
#   -InputDir   Folder that contains segments_4s\, segments_6s\, segments_8s\
#   -Height     Preview vertical resolution in pixels (default 540 = qHD).
#               Options: 360 (tiny), 540 (default), 720 (bigger).
#   -Crf        H.264 quality knob, 18-28 (default 23). Lower = better.

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$InputDir,

    [int]$Height = 540,
    [int]$Crf    = 23
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $InputDir)) {
    throw "InputDir not found: $InputDir"
}

$InputDir = (Resolve-Path -LiteralPath $InputDir).Path

# Find all segments_*s subfolders
$setDirs = Get-ChildItem -LiteralPath $InputDir -Directory -Filter 'segments_*s'
if ($setDirs.Count -eq 0) {
    throw "No segments_*s subfolders found in $InputDir"
}

Write-Host ""
Write-Host "Input root: $InputDir"
Write-Host "Height:     ${Height}p"
Write-Host "CRF:        $Crf"
Write-Host ("Segment sets: {0}" -f ($setDirs.Name -join ', '))
Write-Host ""

$totalMade = 0
$totalSkipped = 0

foreach ($setDir in $setDirs) {
    $previewDir = Join-Path $setDir.FullName 'previews'
    New-Item -ItemType Directory -Force -Path $previewDir | Out-Null

    $clips = Get-ChildItem -LiteralPath $setDir.FullName -Filter 'clip_*.mov' | Sort-Object Name
    Write-Host "==> $($setDir.Name)  ($($clips.Count) clips)"

    foreach ($clip in $clips) {
        $preview = Join-Path $previewDir ($clip.BaseName + '.mp4')

        if ((Test-Path -LiteralPath $preview) -and ((Get-Item -LiteralPath $preview).Length -gt 0)) {
            Write-Host ("   [skip] {0} (already exists)" -f $clip.Name)
            $totalSkipped++
            continue
        }

        Write-Host ("   [make] {0} -> previews\{1}.mp4" -f $clip.Name, $clip.BaseName)

        $ffmpegArgs = @(
            '-hide_banner','-loglevel','error','-y',
            '-i', $clip.FullName,
            '-vf', "scale=-2:$Height",
            '-c:v','libx264',
            '-preset','veryfast',
            '-crf', "$Crf",
            '-pix_fmt','yuv420p',
            '-c:a','aac',
            '-b:a','128k',
            '-movflags','+faststart',
            $preview
        )

        & ffmpeg @ffmpegArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "ffmpeg failed for $($clip.Name) (exit $LASTEXITCODE) - continuing"
            continue
        }
        $totalMade++
    }

    Write-Host ""
}

Write-Host "Done."
Write-Host "  Made:    $totalMade preview(s)"
Write-Host "  Skipped: $totalSkipped (already existed)"
Write-Host ""
Write-Host "Open the previews folder in File Explorer for review:"
foreach ($setDir in $setDirs) {
    $p = Join-Path $setDir.FullName 'previews'
    Write-Host "  $p"
}
