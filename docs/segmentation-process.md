# Segmenting the source into clips (17-clip output)

This documents the process actually used to cut the "Friend Like Me"
showcase mezzanine into the 17 clips at
[`02_ai_input/friendlikeme_showcase/segments_8s/`](../02_ai_input/friendlikeme_showcase/segments_8s/)
(`clip_001.mov` … `clip_017.mov`, each ~8s).

## Which script version is final

**Final version: [`scripts/segment_toolkit/`](../scripts/segment_toolkit/)** (unversioned —
lives directly under `scripts/`, not under `scripts/_archive/`).

Everything under `scripts/_archive/segment_toolkit_v3/` through `_v10/` and
`"v8 or 9"` is a superseded iteration kept for reference only. Do not use
them — the toolkit was rewritten multiple times to fix issues (overlap
handling, tolerance windows, PowerShell port, etc.) and only the top-level
`scripts/segment_toolkit/` folder reflects the working, validated version.

The final toolkit contains:

| File | Purpose |
|---|---|
| `detect_beats.py` | Auto-detects musical beats from the source video, writes an editable `beats.csv` |
| `segment.ps1` | Windows PowerShell cutter — reads the beats CSV, cuts the video into beat-aligned clips |
| `segment.sh` | Bash equivalent of `segment.ps1` (macOS/Linux/Git Bash/WSL) |
| `README.md` | Full usage reference for the toolkit |

## What actually produced the 17 clips

Source: [`01_mezzanine/showcase_2026-07-18/Showcase-FriendLikeMe-20260718.mov`](../01_mezzanine/showcase_2026-07-18/Showcase-FriendLikeMe-20260718.mov)
(the "Around the World" competition run — the master performance).

Beats file: [`audio/beats_friendlikeme.csv`](../audio/beats_friendlikeme.csv)
(227 rows — auto-detected beats, hand-edited).

Command (PowerShell, run from repo root):

```powershell
.\scripts\segment_toolkit\segment.ps1 `
    -InputVideo Showcase-FriendLikeMe-20260718.mov (in 01_mezzanine\showcase_2026-07-18\) `
    -BeatsCsv   audio\beats_friendlikeme.csv `
    -OutDir     02_ai_input\friendlikeme_showcase
```

This single run always produces **three** parallel sets — `segments_4s/`,
`segments_6s/`, `segments_8s/` — because `segment.ps1` calls `Cut-Set` for
targets 4, 6, and 8 unconditionally (lines 208–210 of `segment.ps1`). The
**17-clip set is `segments_8s/`** (the 4s set produced more, shorter clips;
the 6s set produced an intermediate count — see manifest row counts below).

| Set | Clips produced |
|---|---|
| `segments_4s/` | 34 |
| `segments_6s/` | 23 |
| `segments_8s/` | **17** ← the one referenced |

## Repeatable steps (start to finish)

### 0. Prerequisites (one-time)

```powershell
python3 -m venv .venv
.venv\Scripts\activate
pip install librosa soundfile numpy
```

FFmpeg/ffprobe must be on `PATH`. The source must already be a DNxHR/ProRes
mezzanine in `01_mezzanine/` (see the top-level `README.md` §"Transcoding to
DNxHR mezzanine" if starting from a raw `00_originals/` file) — segmentation
never touches `00_originals/`.

### 1. Detect beats (once per song)

```powershell
python scripts\segment_toolkit\detect_beats.py `
    01_mezzanine\showcase_2026-07-18\Showcase-FriendLikeMe-20260718.mov `
    --out audio\beats_friendlikeme.csv
```

Writes `beat_index, time_seconds, keep` rows using librosa's beat tracker
(default `tightness=100`).

### 2. Hand-edit the beats CSV

Open `audio/beats_friendlikeme.csv` and:
- Set `keep=0` (or delete the row) for spurious/off-beat detections.
- Add rows for beats the detector missed (`time_seconds` + `keep=1`).
- Row order doesn't matter — `segment.ps1` sorts and de-duplicates.

This hand-edited CSV (227 rows) is what actually drove the final cut — it is
not the raw librosa output.

### 3. Cut the clips

```powershell
.\scripts\segment_toolkit\segment.ps1 `
    -InputVideo 01_mezzanine\showcase_2026-07-18\Showcase-FriendLikeMe-20260718.mov `
    -BeatsCsv   audio\beats_friendlikeme.csv `
    -OutDir     02_ai_input\friendlikeme_showcase
```

Defaults used (not overridden for this output): `-Codec copy` (stream copy,
lossless/frame-accurate because the mezzanine is all-keyframe DNxHR/ProRes),
`-Tolerance 0.40` (±40% of target duration), `-Overlap tile` (clips are
non-overlapping — each next clip starts where the previous one ended).

Algorithm, per target duration (4s/6s/8s independently):
1. Start at the first kept beat.
2. Find the kept beat closest to `start + target`.
3. If the resulting duration falls within `target × [0.6, 1.4]`, keep it as
   a clip; otherwise skip forward one beat and retry.
4. In `tile` mode, the next clip starts at the previous clip's end beat (no
   overlap) — this is why clip count differs per target duration even
   though all three come from the same 227-beat map.
5. Write `clip_NNN.mov` (stream-copied) + a `manifest.csv`
   (`clip, start_seconds, end_seconds, duration_seconds, file`) per set.

### 4. Verify output

```
02_ai_input/friendlikeme_showcase/
  segments_4s/  (34 clips + manifest.csv)
  segments_6s/  (23 clips + manifest.csv)
  segments_8s/  (17 clips + manifest.csv)  ← clip_001.mov … clip_017.mov
```

Check `segments_8s/manifest.csv` — clip start/end times should be
monotonically increasing and adjacent (`clip N`'s `end_seconds` ==
`clip N+1`'s `start_seconds`), confirming non-overlapping tile mode.

## Why and how `segments_8s/previews/` was created

DNxHR `.mov` clips (what `segment.ps1` outputs) don't play in standard
players like VLC or Windows Media Player without extra codecs. A separate
helper script, `scripts/segment_toolkit/make_previews.ps1`, exists purely to
generate lightweight, universally-playable H.264 MP4 copies **for human
review** — the DNxHR originals stay untouched as the canonical files for
Veo/Flow upload.

It was run once against the whole `friendlikeme_showcase` output folder:

```powershell
.\scripts\segment_toolkit\make_previews.ps1 -InputDir 02_ai_input\friendlikeme_showcase
```

(default flags: `-Height 540 -Crf 23`). The script:

1. Scans `-InputDir` for every `segments_*s\` subfolder (found `segments_4s`,
   `segments_6s`, `segments_8s`).
2. Creates a `previews\` folder inside each.
3. For every `clip_*.mov`, runs:
   ```
   ffmpeg -i clip_NNN.mov -vf scale=-2:540 -c:v libx264 -preset veryfast \
          -crf 23 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart clip_NNN.mp4
   ```
4. Skips re-encoding any preview that already exists — safe to re-run after
   adding new clips.

This produced the 17 `clip_00N.mp4` files (~0.8–1.8MB each) in
`02_ai_input/friendlikeme_showcase/segments_8s/previews/`. The `segments_8s/`
clips themselves were cut first (via `segment.ps1`); the previews were
generated in a separate, later pass over the same output folder.

## To reproduce on the donor recording (optional)

Because both recordings use the same song, the same beats CSV applies
without re-running beat detection:

```powershell
.\scripts\segment_toolkit\segment.ps1 `
    -InputVideo 01_mezzanine\rehearsal_2026-07-15\Rehersal-FriendLikeMe-20260715.mov `
    -BeatsCsv   audio\beats_friendlikeme.csv `
    -OutDir     02_ai_input\friendlikeme_rehearsal
```

Clip indexes will be frame-matched between the showcase and rehearsal sets
since they share the same beat map.
