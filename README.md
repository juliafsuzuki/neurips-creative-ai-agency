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
| `02_ai_input/` | Beat-aligned clips cut from the mezzanine, ready to feed into Google AI | See [Segmenting a source video into clips](#segmenting-a-source-video-into-clips) below |
| `03_ai_output/` | Whatever Google AI (Veo, Gemini, etc.) gives back | |
| `03_flow_inputs/` | Per-clip working folders for partial choreography-transfer in Flow (motion references, identity frames, bookend splices) | Media/photos here stay local — only notes (`README.md`) are tracked in git |
| `04_edit/` | Your editing project (DaVinci Resolve, Premiere, etc.) | |
| `05_final/` | The final video you upload to NeurIPS | |
| `audio/` | Music, voiceover, sound effects, beat maps (`beats_*.csv`) | |
| `stills/` | Reference images, thumbnails, submission photos | |
| `docs/` | Artist statement, technical description, process notes | |
| `paper/` | NeurIPS submission LaTeX source | |
| `scripts/` | Command recipes and archived batch scripts | See `scripts/segment_toolkit/` for the beat-segmenter |

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

## Segmenting a source video into clips

Once a performance is in `01_mezzanine/`, `scripts/segment_toolkit/` cuts it
into beat-aligned clips for `02_ai_input/`. This is the toolkit that produced
the 17 clips in `02_ai_input/friendlikeme_showcase/segments_8s/` from the
"Friend Like Me" showcase master. Full details (exact commands, algorithm,
manifest format) are in [`docs/segmentation-process.md`](docs/segmentation-process.md) —
summary below.

**Final version:** `scripts/segment_toolkit/` (the unversioned folder directly
under `scripts/`). Everything under `scripts/_archive/segment_toolkit_v*/` is
a superseded iteration kept for reference only — don't use those.

### Prerequisites (one-time)

```powershell
python3 -m venv .venv
.venv\Scripts\activate
pip install librosa soundfile numpy
```

FFmpeg/ffprobe must already be on `PATH` (from first-time setup above), and
the source must already be a DNxHR/ProRes mezzanine in `01_mezzanine/`.

### Step 1 — Detect beats (once per song)

```powershell
python scripts\segment_toolkit\detect_beats.py `
    01_mezzanine\showcase_2026-07-18\Showcase-FriendLikeMe-20260718.mov `
    --out audio\beats_friendlikeme.csv
```

Writes an editable CSV (`beat_index, time_seconds, keep`) using librosa's
beat tracker.

### Step 2 — Hand-edit the beats CSV

Open the CSV and set `keep=0` (or delete) spurious detections; add rows for
beats the detector missed. This hand-edited file — not the raw librosa
output — is what drives the cut.

### Step 3 — Cut the clips

```powershell
.\scripts\segment_toolkit\segment.ps1 `
    -InputVideo 01_mezzanine\showcase_2026-07-18\Showcase-FriendLikeMe-20260718.mov `
    -BeatsCsv   audio\beats_friendlikeme.csv `
    -OutDir     02_ai_input\friendlikeme_showcase
```

One run always produces three parallel sets — `segments_4s/`, `segments_6s/`,
`segments_8s/` — matching Veo 3.1's supported input durations. Each clip
starts on a kept beat and ends on the beat closest to `start + target`,
stream-copied losslessly (mezzanine is all-keyframe). The 17-clip set
referenced above is `segments_8s/`.

### Step 4 — Verify output

Each `segments_*s/` folder gets numbered clips plus a `manifest.csv`
(`clip, start_seconds, end_seconds, duration_seconds, file`). Confirm clip
boundaries are adjacent and monotonically increasing.

### Human-review previews

DNxHR `.mov` clips don't play in common players (VLC, Windows Media Player)
without extra codecs, so `scripts/segment_toolkit/make_previews.ps1` generates
a parallel `previews/` folder next to each `segments_*s/` folder with small,
universally-playable H.264 MP4s (540p, CRF 23) — one per clip. The DNxHR
originals are untouched and remain the canonical files for Veo/Flow upload;
previews exist purely so a human can scrub clips in any player. Run it with:

```powershell
.\scripts\segment_toolkit\make_previews.ps1 -InputDir 02_ai_input\friendlikeme_showcase
```

It skips any preview that already exists, so it's safe to re-run after
adding new clips. This is how
`02_ai_input/friendlikeme_showcase/segments_8s/previews/` was created.

---

## Files already produced

| File | Source | Format | Length |
|---|---|---|---|
| `01_mezzanine/rehearsal_2026-07-15/Rehersal-FriendLikeMe-20260715.mov` | rehearsal | DNxHR HQX (HDR/HLG, yuv422p10le) | 2:38 |
| `01_mezzanine/showcase_2026-07-18/Showcase-FriendLikeMe-20260718.mov` | showcase | DNxHR HQ (SDR, yuv422p) | ~length |
| `05_final/Dancing with Genie - Choreographed Movements Meet AI.mp4` | **final NeurIPS 2026 submission** | H.264, 1920×1080 | 2:17 |
| `03_ai_output/Image/Thumbnail Image For Artwork.jpeg` | **submission thumbnail** | JPEG, 2752×1536 | — |

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

Only the process (README, .gitignore, scripts/recipes, docs) goes to GitHub.
Working media (originals, mezzanine, AI input/output) stays on your local
drive and is never uploaded, so the repo stays small — the one deliberate
exception is the final submitted deliverable in `05_final/`, which is small
enough and worth publishing alongside the process that produced it.

---

## Submission checklist (fill in as you go)

The [NeurIPS Creative AI Track](https://neurips.cc/Conferences/2026/CallForCreativeAI)
typically requires:

- [x] Final video deliverable (`05_final\Dancing with Genie - Choreographed Movements Meet AI.mp4`)
- [ ] Artist statement (`docs\artist-statement.md`)
- [ ] Technical description of the AI methods used (`docs\technical-description.md`)
- [x] Still image / thumbnail (`03_ai_output\Image\Thumbnail Image For Artwork.jpeg` — an AI-generated image kept alongside its siblings rather than moved into `stills\`)
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
