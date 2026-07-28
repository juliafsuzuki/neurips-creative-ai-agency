# Archived scripts

These scripts are **retired and not recommended for use**.

## Why they're here

`transcode-mezzanine.ps1` (Windows PowerShell) and `transcode-mezzanine.sh`
(bash) were the original batch transcoders for `00_originals/` → `01_mezzanine/`.

On Windows, the PowerShell version hit an intermittent deadlock between
PowerShell's I/O pipes and ffmpeg's stderr output, causing ffmpeg to hang after
starting an encode. When killed, the resulting `.mov` file was missing its
`moov` atom (the file index at the end), producing files that looked complete
on disk (correct size) but were unplayable in any tool (`moov atom not found`).

The bash version was never battle-tested against the same footage.

## What to use instead

See the top-level `README.md` in the project root — the "Transcoding to DNxHR
mezzanine" section has direct ffmpeg one-liners that work reliably for HDR/HLG
and SDR footage.

## Kept for reference

Preserving these lets us:
1. Show what was tried and why it didn't work
2. Salvage helper logic (rotation detection, HDR auto-detection) if we ever
   write a fixed batch script later
