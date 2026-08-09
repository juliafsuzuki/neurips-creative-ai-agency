#!/usr/bin/env python3
"""
detect_beats.py — Auto-detect musical beats from a video/audio file and write
an editable CSV that segment.sh will consume.

Scope: Project Genie / NeurIPS 2026 submission uses the "Friend Like Me"
showcase only. Run this against the master performance
("Around the World — Friend Like Me"); the resulting beats CSV also
applies to the donor performance ("Dress Rehearsal — Friend Like Me")
because both use the same song. The "A Whole New World" showcase is
out of scope.

Usage:
    python detect_beats.py INPUT.mov [--out beats.csv] [--tightness 100]

Output CSV columns:
    beat_index, time_seconds, keep
where `keep=1` means "use this beat as a possible cut point". Edit the CSV in
any spreadsheet or text editor to drop off-beat detections or add missed ones.

Dependencies:
    pip install librosa soundfile numpy
    (librosa handles audio extraction internally via audioread/ffmpeg)
"""
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path


def detect(input_path: Path, out_path: Path, tightness: float) -> None:
    try:
        import librosa
        import numpy as np
    except ImportError:
        sys.exit(
            "Missing dependencies. Run:\n"
            "    pip install librosa soundfile numpy"
        )

    print(f"Loading audio from {input_path} ...", flush=True)
    # librosa.load will pull the audio track out of a .mov/.mp4 via ffmpeg.
    y, sr = librosa.load(str(input_path), sr=22050, mono=True)
    duration = librosa.get_duration(y=y, sr=sr)
    print(f"  duration: {duration:.2f}s, sample rate: {sr} Hz", flush=True)

    print("Detecting tempo and beats ...", flush=True)
    tempo, beat_frames = librosa.beat.beat_track(
        y=y, sr=sr, tightness=tightness, units="frames"
    )
    beat_times = librosa.frames_to_time(beat_frames, sr=sr)

    tempo_val = float(np.asarray(tempo).item())
    print(f"  estimated tempo: {tempo_val:.1f} BPM", flush=True)
    print(f"  beats detected:  {len(beat_times)}", flush=True)

    with out_path.open("w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["beat_index", "time_seconds", "keep"])
        for i, t in enumerate(beat_times):
            w.writerow([i, f"{t:.3f}", 1])

    print(f"\nWrote {out_path}", flush=True)
    print(
        "\nNext:\n"
        f"  1. Open {out_path.name} in a spreadsheet or editor.\n"
        "  2. Set keep=0 for any spurious beats (or delete the row).\n"
        "  3. Add rows for any beats the detector missed.\n"
        "  4. Run: ./segment.sh INPUT.mov beats.csv\n"
    )


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("input", type=Path, help="Input video or audio file")
    p.add_argument("--out", type=Path, default=Path("beats.csv"),
                   help="Output CSV path (default: beats.csv)")
    p.add_argument("--tightness", type=float, default=100.0,
                   help="Beat tracker tightness (default 100; raise to 400 "
                        "for stricter tempo, lower to 25 for looser)")
    args = p.parse_args()

    if not args.input.exists():
        sys.exit(f"Input not found: {args.input}")

    detect(args.input, args.out, args.tightness)


if __name__ == "__main__":
    main()
