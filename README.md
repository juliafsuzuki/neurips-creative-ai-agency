# NeurIPS 2026 Creative AI Track — "Agency"

Ballroom dance performance artwork augmented by Google AI, for submission to
the [NeurIPS 2026 Creative AI Track](https://neurips.cc/Conferences/2026/CallForCreativeAI).

- **Artist:** Julia Suzuki (Truly Human AI)
- **Theme:** Agency
- **Medium:** Competitive ballroom (Rhythm / Smooth) performance video + generative AI augmentation

---

## What's in this folder

Think of these folders as **stations on an assembly line**. Your iPhone footage
enters at station 00 and moves right, one station at a time, until it becomes
your final NeurIPS submission at station 05.

| Folder | What it holds | Rule |
|---|---|---|
| `00_originals/` | Untouched iPhone `.MOV` files, straight off the camera | **Never edit — treat as read-only** |
| `01_mezzanine/` | High-quality DNxHR editing copies | Everything downstream reads from here |
| `02_ai_input/` | Clips you've trimmed/prepped to feed into Google AI | |
| `03_ai_output/` | Whatever Google AI (Veo, Gemini, etc.) gives back | |
| `04_edit/` | Your editing project (DaVinci Resolve, Premiere, etc.) | |
| `05_final/` | The final video you upload to NeurIPS | |
| `audio/` | Music, voiceover, sound effects | |
| `stills/` | Reference images, thumbnails, submission photos | |
| `docs/` | Artist statement, technical description, notes | |
| `scripts/` | Command recipes and archived batch scripts | |

**Why the numbers?** They keep folders in the correct order when you look at
them in File Explorer, so you always see the pipeline flow at a glance.

**Why is `00_originals/` sacred?** Camera originals are the only thing you
cannot regenerate. If an edit or AI step damages a clip, you can always go
back to `00_originals/` and start over. So don't edit them in place, and back
this folder up somewhere safe (external drive, Google Drive, etc.).

---

## First-time setup (Windows)

You only do this once.

### 1. Install ffmpeg

Open **PowerShell** (press Windows key, type "PowerShell", press Enter) and run:

```powershell
winget install "FFmpeg (Essentials Build)"
```

Close and reopen PowerShell so it picks up the new install. Verify it worked:

```powershell
ffmpeg -version
```

You should see version info. If you get "ffmpeg is not recognized", restart
your computer once and try again.

### 2. That's it

Everything else is one-command recipes below.

---

## Transcoding to DNxHR mezzanine (recommended: one direct ffmpeg command)

For a small project like this (a handful of source files), the most reliable
approach is to run ffmpeg **directly** for each file. This avoids the pipe
deadlock issues we hit with a PowerShell wrapper script.

### For HDR / HLG footage (iPhone with HDR turned on)

Fill in the two paths, then paste as one block into PowerShell:

```powershell
ffmpeg -hide_banner -y `
  -i "PATH_TO_SOURCE.MOV" `
  -map_metadata 0 `
  -vf "format=yuv422p10le" `
  -c:v dnxhd -profile:v dnxhr_hqx `
  -color_primaries bt2020 -color_trc arib-std-b67 -colorspace bt2020nc `
  -c:a pcm_s16le -ar 48000 `
  "PATH_TO_OUTPUT.mov"
```

### For SDR footage (iPhone with HDR turned off, or older iPhones)

```powershell
ffmpeg -hide_banner -y `
  -i "PATH_TO_SOURCE.MOV" `
  -map_metadata 0 `
  -vf "format=yuv422p" `
  -c:v dnxhd -profile:v dnxhr_hq `
  -color_primaries bt709 -color_trc bt709 -colorspace bt709 `
  -c:a pcm_s16le -ar 48000 `
  "PATH_TO_OUTPUT.mov"
```

### Not sure whether your file is HDR or SDR?

Run this on the source file first — it will print `color_transfer=arib-std-b67`
(HDR/HLG), `smpte2084` (HDR10/PQ), or `bt709`/blank (SDR):

```powershell
ffprobe -v error -select_streams v:0 -show_entries stream=color_transfer -of default=noprint_wrappers=1 "PATH_TO_SOURCE.MOV"
```

### Verify the output after encoding

```powershell
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,width,height,pix_fmt,duration -of default=noprint_wrappers=1 "PATH_TO_OUTPUT.mov"
```

You should see something like:
```
codec_name=dnxhd
profile=DNXHR HQX
width=1920
height=1080
pix_fmt=yuv422p10le
duration=158.100000
```

If you see `moov atom not found` — the encode was interrupted and the file is
corrupt. Delete it and re-run the ffmpeg command.

---

## Files already produced

| File | Source | Format | Length |
|---|---|---|---|
| `01_mezzanine/rehearsal_2026-07-15/Rehersal-FriendLikeMe-20260715.mov` | rehearsal | DNxHR HQX (HDR/HLG, yuv422p10le) | 2:38 |
| `01_mezzanine/showcase_2026-07-18/Showcase-FriendLikeMe-20260718.mov` | showcase | DNxHR HQ (SDR, yuv422p) | ~length |

---

## The pipeline at a glance

```
[iPhone HEVC/HDR]                 00_originals\
        │
        │  direct ffmpeg command (DNxHR, preserves HDR)
        ▼
[Editing master]                  01_mezzanine\
        │
        │  trim / crop / resize for AI
        ▼
[AI input clips]                  02_ai_input\
        │
        │  Google Veo / Gemini / etc.
        ▼
[AI output clips]                 03_ai_output\
        │
        │  edit + composite in your NLE
        ▼
[Edit project]                    04_edit\
        │
        │  final export
        ▼
[NeurIPS deliverable]             05_final\
```

Only the final export in `05_final\` should be a compressed delivery format
(H.264 / H.265). Everything upstream stays in high-quality DNxHR so each step
doesn't degrade the image.

---

## Storage note

DNxHR files are **big** — about 6.6 GB per minute of 4K footage, or roughly
1.5 GB per minute of 1080p. A 5-minute routine becomes 30 GB (4K) or ~8 GB
(1080p). Plan for 500 GB to 1 TB of space for the whole project. An external
SSD (Samsung T7, SanDisk Extreme) is the sweet spot if your PC's internal
drive is tight.

**Don't put this folder in iCloud, Dropbox, or Google Drive sync.** Those
services will try to upload every giant file and may corrupt files that are
being written to. Use them only for `docs\` and `05_final\`.

---

## Uploading to GitHub

The `.gitignore` file is already configured to include your **scripts and
docs** but exclude the **giant media files**. When you're ready to push to
GitHub:

```powershell
cd C:\Users\julia\NeurIPS-CreativeAI-Agency
git init
git add .
git commit -m "Initial commit: project scaffold + working mezzanine pipeline"
# Then create a private repo on github.com and follow their push instructions
```

Only the process (README, .gitignore, scripts/recipes, docs) will go to GitHub.
The video files stay on your local drive and are never uploaded, so the repo
stays small.

---

## Submission checklist (fill in as you go)

The [NeurIPS Creative AI Track](https://neurips.cc/Conferences/2026/CallForCreativeAI)
typically requires:

- [ ] Final video deliverable (goes in `05_final\`)
- [ ] Artist statement (`docs\artist-statement.md`)
- [ ] Technical description of the AI methods used (`docs\technical-description.md`)
- [ ] Still image / thumbnail (goes in `stills\`)
- [ ] Author / affiliation metadata

Check the official Call for Creative AI page for this year's exact
requirements and deadlines before submitting.

---

## About the archived scripts

Earlier versions of this project used a PowerShell batch script
(`scripts/transcode-mezzanine.ps1`) to auto-transcode every file in
`00_originals/`. The script proved unreliable on Windows due to a
PowerShell / ffmpeg pipe deadlock — encodes would hang and produce files
missing the finalizing `moov` atom (they looked complete on disk but were
unplayable).

The direct-ffmpeg recipe above is the current recommended workflow. The old
scripts are preserved in `scripts/_archive/` for reference only. Don't use
them.
