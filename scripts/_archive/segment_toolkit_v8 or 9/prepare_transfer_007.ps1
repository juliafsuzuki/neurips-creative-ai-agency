# prepare_transfer_007.ps1 - Prep source assets for the clip_007 partial choreography-transfer job.
#
# Task recap:
#   - clip_007 (segments_8s\clip_007.mov) is 8.167s.
#   - We replace ONLY the middle 4 seconds (0:02 - 0:06 of clip_007) using AI.
#   - The bookends (0:00 - 0:02 and 0:06 - 0:08.167) stay untouched from the master.
#   - Motion reference for the AI: 8:50 - 8:54 (4s) of the practice video.
#
# What this script produces:
#   03_flow_inputs\clip_007_transfer\
#     motion_reference_4s.mp4   <- 4s practice window, 720p H.264 (upload to Flow)
#     clip_007_middle_4s.mp4    <- 4s target window from clip_007 (for prompt reference)
#     clip_007_bookend_head.mov <- first 2.0s of clip_007 (kept as-is, DNxHR)
#     clip_007_bookend_tail.mov <- last 2.167s of clip_007 (kept as-is, DNxHR)
#     clip_007_bookend_head.mp4 <- H.264 preview of the head bookend
#     clip_007_bookend_tail.mp4 <- H.264 preview of the tail bookend
#     identity_frames\
#       identity_01.jpg  <- clip_007 @ 2.0s (start of middle window)
#       identity_02.jpg  <- clip_007 @ 3.3s
#       identity_03.jpg  <- clip_007 @ 4.7s
#       identity_04.jpg  <- clip_007 @ 6.0s (end of middle window)
#     master_audio_middle_4s.wav <- audio for the middle window, from the master
#     README.md
#
# Usage (from repo root):
#   .\scripts\segment_toolkit\prepare_transfer_007.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# ---- Inputs ----
$practiceFile = "00_originals\practice_2026_07_16\Practice Showcase - Friends Like Me - 20260716.MOV"
$clip007      = "02_ai_input\friendlikeme_showcase\segments_8s\clip_007.mov"

# ---- Output layout ----
$outDir       = "03_flow_inputs\clip_007_transfer"
$identityDir  = Join-Path $outDir "identity_frames"

# Timecodes
$practiceStart = "00:08:50"
$practiceDur   = 4.0
$middleStart   = 2.0          # start of the middle window inside clip_007
$middleDur     = 4.0          # length of the middle window
$tailStart     = 6.0          # start of the tail bookend inside clip_007
# tail duration = 8.167 - 6.0 = 2.167 (ffmpeg will just take until EOF)

# Verify inputs
foreach ($p in @($practiceFile, $clip007)) {
    if (-not (Test-Path -LiteralPath $p)) { throw "Missing input: $p" }
}
New-Item -ItemType Directory -Force -Path $outDir      | Out-Null
New-Item -ItemType Directory -Force -Path $identityDir | Out-Null

Write-Host ""
Write-Host "Preparing clip_007 partial-transfer assets..."
Write-Host "  Output: $outDir"
Write-Host ""

# ---- 1. Extract 4s practice motion reference ----
$motionRef = Join-Path $outDir "motion_reference_4s.mp4"
Write-Host "[1/7] Motion reference (practice 8:50-8:54) -> motion_reference_4s.mp4"
& ffmpeg -hide_banner -loglevel error -y `
    -ss $practiceStart -i $practiceFile -t $practiceDur `
    -vf "scale=-2:720" `
    -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p `
    -c:a aac -b:a 128k `
    -movflags +faststart `
    $motionRef
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on motion reference" }

# ---- 2. Extract the middle window of clip_007 (for reference during prompt work) ----
$middleRef = Join-Path $outDir "clip_007_middle_4s.mp4"
Write-Host "[2/7] Middle window of clip_007 (0:02-0:06) -> clip_007_middle_4s.mp4"
& ffmpeg -hide_banner -loglevel error -y `
    -ss $middleStart -i $clip007 -t $middleDur `
    -vf "scale=-2:720" `
    -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p `
    -c:a aac -b:a 128k `
    -movflags +faststart `
    $middleRef
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on middle window" }

# ---- 3. Extract clip_007 bookends as DNxHR (lossless splice later) ----
$headDnx = Join-Path $outDir "clip_007_bookend_head.mov"
$tailDnx = Join-Path $outDir "clip_007_bookend_tail.mov"
Write-Host "[3/7] Head bookend of clip_007 (0:00-0:02, DNxHR) -> clip_007_bookend_head.mov"
& ffmpeg -hide_banner -loglevel error -y `
    -ss 0 -i $clip007 -t $middleStart `
    -c copy `
    $headDnx
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on head bookend" }

Write-Host "[4/7] Tail bookend of clip_007 (0:06-end, DNxHR) -> clip_007_bookend_tail.mov"
& ffmpeg -hide_banner -loglevel error -y `
    -ss $tailStart -i $clip007 `
    -c copy `
    $tailDnx
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on tail bookend" }

# ---- 4. H.264 previews of the bookends (playable) ----
$headMp4 = Join-Path $outDir "clip_007_bookend_head.mp4"
$tailMp4 = Join-Path $outDir "clip_007_bookend_tail.mp4"
Write-Host "[5/7] H.264 previews of bookends -> clip_007_bookend_head.mp4, _tail.mp4"
& ffmpeg -hide_banner -loglevel error -y `
    -i $headDnx -vf "scale=-2:720" -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p `
    -c:a aac -b:a 128k -movflags +faststart $headMp4
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on head preview" }
& ffmpeg -hide_banner -loglevel error -y `
    -i $tailDnx -vf "scale=-2:720" -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p `
    -c:a aac -b:a 128k -movflags +faststart $tailMp4
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on tail preview" }

# ---- 5. Extract 4 identity anchor frames across the middle window ----
# Middle window is 2.0s - 6.0s -> frames at 2.0, 3.33, 4.67, 6.0
Write-Host "[6/7] Identity anchor frames (4 stills from middle window) -> identity_frames\"
$frameTimes = @('2.0', '3.33', '4.67', '6.0')
for ($i = 0; $i -lt $frameTimes.Count; $i++) {
    $frameOut = Join-Path $identityDir ("identity_{0:D2}.jpg" -f ($i + 1))
    & ffmpeg -hide_banner -loglevel error -y `
        -ss $frameTimes[$i] -i $clip007 `
        -frames:v 1 -q:v 2 `
        $frameOut
    if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on identity frame $($i+1)" }
    Write-Host ("       identity_{0:D2}.jpg  (clip_007 @ {1}s)" -f ($i + 1), $frameTimes[$i])
}

# ---- 6. Extract master audio for the middle window ----
$midAudio = Join-Path $outDir "master_audio_middle_4s.wav"
Write-Host "[7/7] Master audio for middle window -> master_audio_middle_4s.wav"
& ffmpeg -hide_banner -loglevel error -y `
    -ss $middleStart -i $clip007 -t $middleDur `
    -vn -acodec pcm_s16le -ar 48000 -ac 2 `
    $midAudio
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed on middle audio" }

# ---- 7. Write README ----
$readmePath = Join-Path $outDir "README.md"
$readme = @'
# clip_007 Partial Choreography-Transfer Assets

## The plan

Original clip_007 (8.167s) is split into three pieces:

    [ head 0.0-2.0s ][ middle 2.0-6.0s (REPLACE) ][ tail 6.0-8.167s ]

Head and tail are kept as-is from the master. The middle 4s is regenerated by
Veo using the practice video (8:50-8:54) as the motion reference. Final clip
is assembled by concatenating: head + AI_middle + tail.

## Files

- **motion_reference_4s.mp4**  - 4s from the practice video (8:50-8:54). Upload
  to Flow as the MOTION reference. Focus is on the couple in the middle of the frame.

- **clip_007_middle_4s.mp4**   - The 4s target window from the master. This is
  what we are replacing. Watch this to see the "before" and understand the
  choreographic phrase we need Veo to redraw.

- **identity_frames/**         - Four stills from clip_007 during the middle
  window (at 2.0s, 3.33s, 4.67s, 6.0s). Upload to Flow as SUBJECT + ENVIRONMENT
  references so Veo knows who you and your partner are and what the ballroom
  looks like.

- **clip_007_bookend_head.mov** - First 2.0s of clip_007, DNxHR. Preserved as-is
  for the final splice.
- **clip_007_bookend_tail.mov** - Last 2.167s of clip_007, DNxHR. Preserved as-is
  for the final splice.
- **clip_007_bookend_head.mp4** / **_tail.mp4** - H.264 previews of the bookends
  so you can watch and confirm they cut cleanly at the splice points.

- **master_audio_middle_4s.wav** - Master audio for the 4s middle window. We
  overlay this on the Veo output so audio remains locked to Friend Like Me.

## After you have the Flow output

1. Save the Flow generation as `ai_middle_4s.mp4` in this folder.
2. Run `finalize_clip_007.ps1` (to be created next) to:
   a. Merge master_audio_middle_4s.wav onto ai_middle_4s.mp4
   b. Transcode to DNxHR to match the mezzanine
   c. Concatenate: bookend_head + ai_middle + bookend_tail -> new clip_007.mov
   d. Regenerate the H.264 preview
'@
Set-Content -LiteralPath $readmePath -Value $readme -Encoding UTF8

Write-Host ""
Write-Host "Done. Assets ready in: $outDir"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Watch motion_reference_4s.mp4 and confirm practice couple is legible."
Write-Host "  2. Watch clip_007_middle_4s.mp4 to see the target choreography."
Write-Host "  3. Watch bookend head and tail to confirm splice points are clean."
Write-Host "  4. Tell your AI helper we are ready for Flow prompt engineering."
