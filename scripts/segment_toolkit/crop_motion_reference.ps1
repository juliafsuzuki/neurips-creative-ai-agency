# crop_motion_reference.ps1 - Produce 3 candidate crops of motion_reference_4s.mp4
# so you can pick the one that best captures the practice couple's travel.
#
# This version AUTO-DETECTS the source video resolution and computes crop
# dimensions relative to it, so it works regardless of whether the source is
# 720p, 1080p, or other sizes.
#
# Produces:
#   crop_center.mp4  - Middle 60% of the frame (couple in middle)
#   crop_left.mp4    - Left-center 60% (couple moves leftward)
#   crop_right.mp4   - Right-center 60% (couple moves rightward)
#
# Usage (from repo root):
#   .\scripts\segment_toolkit\crop_motion_reference.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$src    = "03_flow_inputs\clip_007_transfer\motion_reference_4s.mp4"
$outDir = "03_flow_inputs\clip_007_transfer"

if (-not (Test-Path -LiteralPath $src)) {
    throw "Missing source: $src"
}

# --- Auto-detect source resolution ---
$probeOutput = & ffprobe -v error -select_streams v:0 `
    -show_entries stream=width,height `
    -of csv=p=0:s=x $src

if ($LASTEXITCODE -ne 0 -or -not $probeOutput) {
    throw "ffprobe failed on source video"
}

$parts = $probeOutput.Trim() -split 'x'
$srcW = [int]$parts[0]
$srcH = [int]$parts[1]

Write-Host ""
Write-Host "Source resolution: ${srcW}x${srcH}"

# --- Compute crop dimensions ---
# Crop to 60% width, 80% height, keep result even (ffmpeg/libx264 requires even dims)
$cropW = [int]([Math]::Floor($srcW * 0.60 / 2) * 2)
$cropH = [int]([Math]::Floor($srcH * 0.80 / 2) * 2)

# Vertical offset: crop from a bit below the top (dance uses lower part of frame)
$cropY = [int]([Math]::Floor(($srcH - $cropH) / 2 / 2) * 2)

# Horizontal starting positions
$xCenter = [int]([Math]::Floor(($srcW - $cropW) / 2 / 2) * 2)
$xLeft   = [int]([Math]::Floor($xCenter * 0.35 / 2) * 2)     # closer to left edge
$xRight  = [int]([Math]::Floor(($srcW - $cropW - $xLeft) / 2) * 2)

Write-Host ("Crop dimensions:   ${cropW}x${cropH} at y=${cropY}")
Write-Host ("  center x=${xCenter}")
Write-Host ("  left   x=${xLeft}")
Write-Host ("  right  x=${xRight}")
Write-Host ""

$crops = @(
    @{ name = "crop_center.mp4"; x = $xCenter },
    @{ name = "crop_left.mp4";   x = $xLeft   },
    @{ name = "crop_right.mp4";  x = $xRight  }
)

foreach ($c in $crops) {
    $out = Join-Path $outDir $c.name
    Write-Host ("Building {0}" -f $c.name)

    # scale keeps result at the same height as input for consistent playback
    $filter = "crop=${cropW}:${cropH}:$($c.x):${cropY}"

    & ffmpeg -hide_banner -loglevel error -y `
        -i $src `
        -vf $filter `
        -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p `
        -c:a aac -b:a 128k `
        -movflags +faststart `
        $out

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "ffmpeg failed on $($c.name)"
    }
}

Write-Host ""
Write-Host "Done. Three crops in: $outDir"
Write-Host "  crop_center.mp4  - middle of frame"
Write-Host "  crop_left.mp4    - left-center of frame"
Write-Host "  crop_right.mp4   - right-center of frame"
Write-Host ""
Write-Host "Watch all 3 in Media Player. Pick the one where the couple"
Write-Host "stays in frame throughout the 4 seconds."
