# crop_motion_reference.ps1 - Produce 3 candidate crops of motion_reference_4s.mp4
# so you can pick the one that best captures the practice couple's travel.
#
# The source is 1920x1080. We produce:
#   crop_center.mp4  - Middle 60% width, lower 80% height (cuts off ceiling)
#   crop_left.mp4    - Left-center 60% width, lower 80% height (if couple moves left)
#   crop_right.mp4   - Right-center 60% width, lower 80% height (if couple moves right)
#
# Watch all 3 in Media Player, pick the one where the couple stays in frame
# most of the time. Upload that one to Flow, replacing the current version.
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

# Source is 1920x1080. Crop parameters below use ffmpeg's crop=w:h:x:y format.
# w=1152 (60% of 1920), h=864 (80% of 1080), then scaled to 720p.
$w = 1152
$h = 864

# Three horizontal starting positions
$crops = @(
    @{ name = "crop_center.mp4"; x = 384;  y = 216 },  # center: x=(1920-1152)/2=384
    @{ name = "crop_left.mp4";   x = 128;  y = 216 },  # left-center
    @{ name = "crop_right.mp4";  x = 640;  y = 216 }   # right-center
)

Write-Host ""
Write-Host "Producing 3 candidate crops of motion_reference_4s.mp4..."
Write-Host ""

foreach ($c in $crops) {
    $out = Join-Path $outDir $c.name
    Write-Host ("Building {0} (crop {1}x{2} at x={3},y={4})" -f $c.name, $w, $h, $c.x, $c.y)

    $filter = "crop=${w}:${h}:$($c.x):$($c.y),scale=-2:720"

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
Write-Host "  crop_center.mp4  - middle 60% of frame"
Write-Host "  crop_left.mp4    - left-center 60% of frame"
Write-Host "  crop_right.mp4   - right-center 60% of frame"
Write-Host ""
Write-Host "Watch all 3 in Media Player. Pick the one where the couple"
Write-Host "stays in frame throughout the 4 seconds."
Write-Host ""
Write-Host "Then in Flow: delete the current motion_reference_4s.mp4 from"
Write-Host "Videos and upload your chosen crop instead."
