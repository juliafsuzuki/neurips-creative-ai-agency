# Dancing with Genie — Choreographed Movements Meet AI

A 2-minute, 17-second AI-augmented dance video artwork submitted to the
[NeurIPS 2026 Creative AI Track](https://neurips.cc/Conferences/2026/CallForCreativeAI)
(theme: **Agency**). It transforms a recorded live ballroom performance into
an AI-generated reimagined world: the original American Rhythm choreography
is preserved exactly as danced, while costumes, architecture, landscapes,
lighting, and special effects are regenerated around the dancers.

- **Artist:** Julia Fumie Suzuki — Securely Wellbeing AI, Truly Human AI (Bloomfield Hills, MI)
- **Theme:** Agency
- **Medium:** Competitive ballroom (American Rhythm) performance video + generative AI augmentation
- **Watch:** [youtu.be/ZUP3pySTDcQ](https://youtu.be/ZUP3pySTDcQ)
- **Paper:** [`05_final/Dancing with Genie - Choreographed Movements Meet AI vF.pdf`](05_final/Dancing%20with%20Genie%20-%20Choreographed%20Movements%20Meet%20AI%20vF.pdf)
- **Supplementary artifacts:** [Google Drive](https://drive.google.com/drive/folders/1jtSoXBnm1ZeL022Ld7Wz0BitHPVp9sEt)
- **Prior work:** [*Story of Hope*](https://youtu.be/tTJropXp5nw) (2025), the AI-generated short film this artwork extends

This README serves two audiences. If you're here for the **concept and
creative framing**, read [About this artwork](#about-this-artwork) and
[Theme: Agency](#theme-agency) below. If you're here to **reproduce the
technical pipeline**, skip to [What's in this folder](#whats-in-this-folder).

---

## About this artwork

> *Dancing with Genie: Choreography Meets AI* is a 2-minute, 17-second
> AI-augmented dance video artwork that transforms a recorded live ballroom
> dance performance into an AI-generated reimagined world. The audience sees
> the original American Rhythm choreography preserved while costumes,
> architecture, landscapes, lighting, and special effects are regenerated
> around the dancers, accompanied by the original *Friend Like Me* soundtrack.
>
> — abstract, *Dancing with Genie* (Suzuki, 2026a)

The source is the artist's American Rhythm showcase performance of *Friend
Like Me* from Disney's *Aladdin*, recorded July 18, 2026, in which the artist
performed Princess Jasmine while her dance partner performed Genie. The
artwork asks whether human dance figures and choreography can remain intact
while AI regenerates the surrounding visual world — human agency preserves
the choreography and directs the creative vision, while generative AI
transforms everything around it.

**How it was made, in one paragraph:** the source video was transcoded to
DNxHR HQ, its audio was extracted and analyzed for beat/tempo with librosa,
and the video was segmented into 17 beat-aligned clips of roughly eight
seconds (see [Segmenting a source video into clips](#segmenting-a-source-video-into-clips)).
One clip (007) contained a choreographic misstep and was corrected in CapCut
instead of sent through generative video; the other 16 clips were each
transformed individually with **Google Flow**'s video-to-video generation,
using the recorded performance as motion/structural conditioning so the
choreography carried through unchanged while prompts delegated costumes,
architecture, sky, moon, dunes, and environmental motion to the model. The
regenerated clips were assembled in **CapCut** against the original *Friend
Like Me* audio track. **Nano Banana Pro** generated the submission thumbnail.
**Claude Code** supported repository management and documentation (this
README included). **Perplexity** served as a research thought partner
throughout.

| Tool | Role |
|---|---|
| librosa | Beat/tempo detection driving where clips are cut |
| Google Flow | Video-to-video generation — regenerates the world around the dancers |
| CapCut | Final assembly/audio sync; also the corrective edit for clip 007 |
| Nano Banana Pro | Submission thumbnail image generation |
| Claude Code | Repository management, pipeline scripting, documentation |
| Perplexity | Research thought partner |

---

## Theme: Agency

The artwork adopts a philosophical view of agency as the capacity to act
intentionally, considered across five dimensions (Schlosser, 2019), and asks
which of them should be retained, shared, delegated, or refused when AI
enters an existing human creative practice — competitive ballroom, where
agency (intention, choice, causal power, self-direction, responsibility) was
already distributed among dancers, instructors, choreographers, judges, and
audiences long before AI arrived.

| Dimension | Status | Note |
|---|---|---|
| Intentionality | **Retained** | Every regeneration served an artistic intention the artist established; AI did not determine the artwork's purpose. |
| Choice | **Negotiated** | Imperfections became opportunities — e.g. clip 007 tested whether AI-assisted correction could better realize intended choreography. |
| Causal Power | **Shared** | AI had latitude over costumes, objects, architecture, landscapes, and environmental motion — not over the choreography itself. |
| Self-Direction | **Shared, with a boundary** | AI directed the imaginative visual world; the artist directed the danced world and overall creative vision. |
| Responsibility | **Retained by the human artist** | AI generated possibilities; the artist prompted, evaluated, selected, rejected, and refined every result. |

The central metaphor is **Genie** from *Aladdin*: extraordinary transformative
power within defined constraints, valuable only when guided by human
intention and exercised responsibly. As the paper puts it — *"Like Genie, AI
can grant extraordinary wishes, but it cannot determine which wishes are
worth granting."* The key takeaway: as generative AI democratizes what can
be made, expertise shifts toward judging what *should* be made, what should
stay authentically human, and where that line belongs — authorship is
expressed as much through what's retained, shared, delegated, and refused as
through what's created.

---

## Author

**Julia Fumie Suzuki** is an artist and competitive ballroom dancer, data and
AI leader, and wellbeing strategist working at the intersection of AI,
creativity, and human wellbeing. She is the founder of Securely Wellbeing and
Truly Human AI. Her prior creative work includes the AI-generated short film
*[Story of Hope](https://youtu.be/tTJropXp5nw)* (2025), which explored
generative AI's ability to create ballroom dance figures and choreography and
whose limitations in reliably reproducing specific choreography this artwork
directly addresses by grounding generation in an authentic human performance.
She brings 14 years of consulting experience at Accenture and holds
professional certifications from Google Cloud, NVIDIA, Microsoft, and AWS.

---

## Citation

If you reference this work, please cite:

```
Suzuki, J. F. (2026a). Dancing with Genie: Choreography Meets AI
[AI-augmented dance video artwork]. YouTube. https://youtu.be/ZUP3pySTDcQ

Suzuki, J. F. (2026b). Project Genie: Dancing with Genie – Source Code.
GitHub. https://github.com/juliafsuzuki/neurips-creative-ai-agency

Suzuki, J. F. (2026c). Project Genie: Supplementary Deliverables and
Artifacts (2026 NeurIPS Creative AI Track – Agency).
https://drive.google.com/drive/folders/1jtSoXBnm1ZeL022Ld7Wz0BitHPVp9sEt
```

Full reference list, including the Schlosser (2019) agency framework and the
prior-work citation for *Story of Hope*, is in the paper
(`05_final/Dancing with Genie - Choreographed Movements Meet AI vF.pdf`).

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
| `05_final/` | The exact bundle submitted to NeurIPS: final video, thumbnail, paper PDF | The one media folder published in full on GitHub |
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

**What happened next (outside this repo's scripts):** of the 17 `segments_8s/`
clips, clip 007 contained a choreographic misstep and was corrected directly
in CapCut rather than sent through generative video. The remaining 16 clips
were each uploaded to Google Flow individually for video-to-video generation,
then all 17 (16 AI-regenerated + 1 CapCut-corrected) were assembled in CapCut
against the original *Friend Like Me* audio into the `05_final/` deliverable.
See [About this artwork](#about-this-artwork) for the creative rationale.

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
| `05_final/Thumbnail Image For Artwork.jpeg` | **submission thumbnail** (Nano Banana Pro) | JPEG, 2752×1536 | — |
| `05_final/Dancing with Genie - Choreographed Movements Meet AI vF.pdf` | **NeurIPS paper** | PDF, 3 pages | — |

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
        │  Google Flow (video-to-video) / Nano Banana Pro (images) / etc.
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

The `.gitignore` file is already configured to include your **scripts,
docs, and the `05_final/` submission bundle** but exclude the **giant
working media files** upstream of it. When you're ready to push to GitHub:

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
- [x] Artist statement (Section 3, "How the Theme of Agency Is Addressed," in the paper — no separate `docs\artist-statement.md` was written)
- [x] Technical description of the AI methods used (Section 2, "The Roles of AI and ML," in the paper)
- [x] Still image / thumbnail (`05_final\Thumbnail Image For Artwork.jpeg`)
- [x] Author / affiliation metadata (Section 5, "Author Biography," in the paper; see [Author](#author) above)

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
