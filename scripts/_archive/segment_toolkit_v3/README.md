# Beat-Aligned Segmenter for Project Genie

Cuts your ballroom mezzanine into three parallel sets of clips
(`segments_4s/`, `segments_6s/`, `segments_8s/`) where every cut lands
on a musical beat. The three sets match Veo 3.1's supported input
durations, so you can pick whichever length best fits each choreographic
phrase in Google Flow without re-cutting.

## Scope for the NeurIPS 2026 submission

This toolkit operates on the **"Friend Like Me" showcase only**. Two
performance recordings of that showcase are in scope:

- **Master:** `Around the World — Friend Like Me` (2026-07-18, competition run)
- **Donor:** `Dress Rehearsal — Friend Like Me` (2026-07-15, rehearsal)

The **"A Whole New World" showcase is out of scope** for this submission
(deadline Aug 3, 2026) and is not processed by any script here.

## Pipeline

```
mezzanine.mov ──► detect_beats.py ──► beats.csv ──► segment.sh ──► segments_{4,6,8}s/
                     (auto)         (you edit)      (cuts)
```

## One-time setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install librosa soundfile numpy
chmod +x segment.sh
```

FFmpeg must already be on your PATH (you have it from Step 1).

## Step A — Auto-detect beats

Run this against the **master** performance:

```bash
python detect_beats.py FriendLikeMe_AroundTheWorld_mezzanine.mov \
    --out beats_friendlikeme.csv
```

Prints estimated BPM and beat count. Writes the CSV with columns:

| beat_index | time_seconds | keep |
|------------|--------------|------|

"Friend Like Me" has a swung, syncopated feel — expect librosa to catch
the four-on-the-floor pulse cleanly but occasionally miss the swing
accents. That's what Step B is for.

## Step B — Edit `beats.csv`

Open in any spreadsheet or text editor.

- Set `keep=0` to drop a spurious detection (or delete the row).
- Add rows for beats librosa missed — put the time in `time_seconds`
  and set `keep=1`. Order doesn't matter; `segment.sh` sorts.
- Save as plain CSV.

Tip: play the mezzanine in VLC with `Tools ▸ Track Synchronization` open
to nudge timestamps if you're eyeballing them. Or use Audacity's
`Analyze ▸ Beat Finder` and cross-check.

## Step C — Cut the three sets

Run from the repo root, once per performance. `--outdir` chooses where
`segments_4s/`, `segments_6s/`, `segments_8s/` are written.

```bash
# Master: showcase (competition run)
scripts/segment_toolkit/segment.sh \
    01_mezzanine/showcase_2026-07-18/FriendLikeMe_AroundTheWorld_mezzanine.mov \
    audio/beats_friendlikeme.csv \
    --outdir 02_ai_input/friendlikeme_showcase

# Donor: dress rehearsal (same beat map — same song)
scripts/segment_toolkit/segment.sh \
    01_mezzanine/rehearsal_2026-07-15/FriendLikeMe_DressRehearsal_mezzanine.mov \
    audio/beats_friendlikeme.csv \
    --outdir 02_ai_input/friendlikeme_rehearsal
```

Because both recordings share `beats_friendlikeme.csv`, corresponding
clip indexes across the two folders are frame-matched — useful when you
later pair master and donor takes in Flow.

By default this uses `-c copy` (stream copy, no re-encode). Since your
mezzanine is ProRes 422 or DNxHR — where every frame is a keyframe —
cuts are already frame-accurate and lossless.

If you ever want to run this on a long-GOP source (H.264 master, GoPro
footage, etc.) and still get frame-accurate cuts, force a re-encode by
adding `--codec`:

```bash
scripts/segment_toolkit/segment.sh input.mov beats.csv \
    --outdir 02_ai_input/whatever --codec prores   # ProRes 422

scripts/segment_toolkit/segment.sh input.mov beats.csv \
    --outdir 02_ai_input/whatever --codec dnxhr    # DNxHR HQ
```

## What you get

Each `--outdir` gets three subfolders, each with numbered clips plus a
`manifest.csv`:

```
02_ai_input/friendlikeme_showcase/
  segments_4s/
    clip_001.mov
    clip_002.mov
    ...
    manifest.csv     ← clip, start_seconds, end_seconds, duration_seconds, file
  segments_6s/
    ...
  segments_8s/
    ...
```

Actual clip durations will vary within ±40% of the target (default
tolerance) because they snap to real beats. Clips that can't fit that
window are dropped rather than distorted — expect ~85–95% coverage of
the timeline depending on tempo stability.

## Recommended Flow workflow

1. Scrub each `manifest.csv` and mark which clips capture a
   choreographically meaningful moment (a spin, a break, a pose).
2. For each marked clip, decide the Veo prompt/style you'll pair with
   it (e.g. "add particle trails to the follower's dress",
   "reveal a mirrored ballroom around the couple").
3. In Flow, pick the 4s / 6s / 8s version of that moment — usually the
   longest that stays temporally coherent for the effect you're
   applying.
4. Extend within Flow only where the effect needs to bleed past 8s.

## Troubleshooting

**Too few clips generated?** The `±40%` tolerance may be dropping valid
segments if your tempo is uneven. Edit the awk block in `segment.sh`
(`0.6` and `1.4` multipliers) to widen it.

**Cuts feel late by ~1 beat?** Librosa's beat tracker sometimes locks
onto the "and" instead of the downbeat. Shift every `time_seconds`
value by the offset (e.g. subtract 0.25s in a spreadsheet), or re-run
`detect_beats.py --tightness 400` for a stricter grid.

**Audio pops at cut boundaries?** With `--codec copy` on a mezzanine
this shouldn't happen. If it does on a long-GOP source, use
`--codec prores` for a clean re-encode.
