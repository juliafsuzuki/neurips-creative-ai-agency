#!/usr/bin/env bash
# segment.sh — Cut a mezzanine video into three parallel beat-aligned sets:
#   segments_4s/, segments_6s/, segments_8s/
#
# Scope: Project Genie / NeurIPS 2026 submission uses the "Friend Like Me"
# showcase only. Master performance is "Around the World — Friend Like Me";
# donor performance is "Dress Rehearsal — Friend Like Me". Both share the
# same song and therefore the same beat CSV. The "A Whole New World"
# showcase is out of scope.
#
# Each clip STARTS on a beat marked keep=1 in the CSV. Its end is the beat
# whose distance from (start + target_duration) is smallest. This means real
# clip durations will vary slightly around 4s / 6s / 8s but every cut lands
# on a musical beat — ideal for Veo 3.1 (which accepts 4/6/8s inputs).
#
# Usage:
#   ./segment.sh INPUT.mov beats.csv [--codec prores|dnxhr|copy]
#
# Requirements: ffmpeg, awk, sort. Uses stream-copy by default (fast, lossless)
# but only truly frame-accurate when the mezzanine has dense keyframes — which
# ProRes 422 and DNxHR do by design (every frame is a keyframe). If you use
# --codec copy on a long-GOP source (H.264/H.265), cuts snap to the nearest
# keyframe. Use --codec prores or --codec dnxhr to force frame-accurate cuts
# with a re-encode.

set -euo pipefail

usage() {
    cat >&2 <<EOF
Usage: $0 INPUT.mov beats.csv [--codec prores|dnxhr|copy] [--outdir DIR]

Options:
  --codec   copy (default, lossless on ProRes/DNxHR), prores, or dnxhr
  --outdir  Where to write segments_4s/ , segments_6s/ , segments_8s/
            (default: current working directory)

Examples (Friend Like Me showcase, run from repo root):
  $0 01_mezzanine/showcase_2026-07-18/FriendLikeMe_AroundTheWorld_mezzanine.mov \\
     audio/beats_friendlikeme.csv \\
     --outdir 02_ai_input/friendlikeme_showcase

  $0 01_mezzanine/rehearsal_2026-07-15/FriendLikeMe_DressRehearsal_mezzanine.mov \\
     audio/beats_friendlikeme.csv \\
     --outdir 02_ai_input/friendlikeme_rehearsal
EOF
    exit 1
}

if [[ $# -lt 2 ]]; then
    usage
fi

INPUT="$1"
BEATS_CSV="$2"
shift 2

CODEC="copy"
OUTDIR="."

while [[ $# -gt 0 ]]; do
    case "$1" in
        --codec)
            CODEC="${2:-}"
            [[ -z "$CODEC" ]] && usage
            shift 2
            ;;
        --outdir)
            OUTDIR="${2:-}"
            [[ -z "$OUTDIR" ]] && usage
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            ;;
    esac
done

mkdir -p "$OUTDIR"
# Resolve to absolute so the awk plan and ffmpeg calls are unambiguous.
OUTDIR="$(cd "$OUTDIR" && pwd)"

if [[ ! -f "$INPUT" ]]; then
    echo "Input not found: $INPUT" >&2
    exit 1
fi

if [[ ! -f "$BEATS_CSV" ]]; then
    echo "Beat CSV not found: $BEATS_CSV" >&2
    exit 1
fi

# ---- Extract kept beat times, sorted, deduplicated ----
BEATS_TMP="$(mktemp)"
trap 'rm -f "$BEATS_TMP"' EXIT

awk -F',' '
    NR == 1 { next }                          # skip header
    $3 + 0 == 1 { printf "%.3f\n", $2 + 0 }   # keep=1 rows only
' "$BEATS_CSV" | sort -n -u > "$BEATS_TMP"

BEAT_COUNT=$(wc -l < "$BEATS_TMP" | tr -d ' ')
if [[ "$BEAT_COUNT" -lt 2 ]]; then
    echo "Need at least 2 kept beats in $BEATS_CSV (found $BEAT_COUNT)" >&2
    exit 1
fi

# ---- Video duration (seconds) ----
DURATION=$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$INPUT")

echo "Input:      $INPUT"
echo "Duration:   ${DURATION}s"
echo "Kept beats: $BEAT_COUNT"
echo "Codec:      $CODEC"
echo "Output dir: $OUTDIR"
echo

# ---- Codec flags ----
case "$CODEC" in
    copy)
        VCODEC_ARGS=(-c copy)
        EXT="mov"
        ;;
    prores)
        # ProRes 422 (profile 3) — frame-accurate, mezzanine quality
        VCODEC_ARGS=(-c:v prores_ks -profile:v 3 -c:a pcm_s16le)
        EXT="mov"
        ;;
    dnxhr)
        # DNxHR HQ — frame-accurate, mezzanine quality
        VCODEC_ARGS=(-c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p -c:a pcm_s16le)
        EXT="mov"
        ;;
    *)
        echo "Unknown codec: $CODEC (use copy|prores|dnxhr)" >&2
        exit 1
        ;;
esac

# ---- Core cutting loop ----
cut_set() {
    local target="$1"
    local outdir="${OUTDIR}/segments_${target}s"
    mkdir -p "$outdir"
    echo "==> Building $outdir (target ${target}s per clip)"

    # For every kept beat, find the kept beat closest to (start + target).
    # Emits: idx  start  end  actual_dur
    awk -v target="$target" -v total_dur="$DURATION" '
        { beats[NR] = $1 + 0 }
        END {
            n = NR
            idx = 0
            for (i = 1; i <= n; i++) {
                start = beats[i]
                # skip starts too close to end of video
                if (start > total_dur - 1.0) continue

                want = start + target
                best_j = 0
                best_diff = 1e9
                # search forward for the beat nearest to (start + target)
                for (j = i + 1; j <= n; j++) {
                    diff = beats[j] - want
                    if (diff < 0) diff = -diff
                    if (diff < best_diff) {
                        best_diff = diff
                        best_j = j
                    }
                    # once beats[j] passes want by more than best_diff, break
                    if (beats[j] > want + best_diff) break
                }
                if (best_j == 0) continue
                end = beats[best_j]
                if (end > total_dur) end = total_dur
                dur = end - start
                # only accept clips within +/- 40% of target
                if (dur < target * 0.6 || dur > target * 1.4) continue

                idx++
                printf "%03d\t%.3f\t%.3f\t%.3f\n", idx, start, end, dur
            }
        }
    ' "$BEATS_TMP" > "$outdir/_plan.tsv"

    local n_clips
    n_clips=$(wc -l < "$outdir/_plan.tsv" | tr -d ' ')
    echo "   planned clips: $n_clips"

    if [[ "$n_clips" -eq 0 ]]; then
        echo "   (no clips fit within tolerance for ${target}s — skipping)"
        return
    fi

    # Emit ffmpeg commands
    while IFS=$'\t' read -r idx start end dur; do
        out="$outdir/clip_${idx}.${EXT}"
        printf "   [%s] %6.3fs → %6.3fs  (%.3fs)  %s\n" \
            "$idx" "$start" "$end" "$dur" "$out"
        ffmpeg -hide_banner -loglevel error -y \
            -ss "$start" -to "$end" -i "$INPUT" \
            -map 0 "${VCODEC_ARGS[@]}" \
            -avoid_negative_ts make_zero \
            "$out"
    done < "$outdir/_plan.tsv"

    # Save a human-readable manifest
    {
        echo "clip,start_seconds,end_seconds,duration_seconds,file"
        awk -F'\t' -v ext="$EXT" -v outdir="$outdir" \
            '{ printf "%s,%s,%s,%s,%s/clip_%s.%s\n", $1, $2, $3, $4, outdir, $1, ext }' \
            "$outdir/_plan.tsv"
    } > "$outdir/manifest.csv"
    rm -f "$outdir/_plan.tsv"
    echo "   wrote $outdir/manifest.csv"
    echo
}

cut_set 4
cut_set 6
cut_set 8

echo "Done. Review manifests in ${OUTDIR}/segments_{4,6,8}s/manifest.csv"
