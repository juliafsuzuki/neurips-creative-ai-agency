# segment.ps1 — PowerShell port of segment.sh
#
# Cut a mezzanine video into three parallel beat-aligned sets:
#   segments_4s/ , segments_6s/ , segments_8s/
#
# Scope: Project Genie / NeurIPS 2026 submission uses the "Friend Like Me"
# showcase only. Master is "Around the World — Friend Like Me"; donor is
# "Dress Rehearsal — Friend Like Me". Both share the same song and
# therefore the same beat CSV. "A Whole New World" is out of scope.
#
# Each clip STARTS on a beat marked keep=1 in the CSV. Its end is the beat
# whose distance from (start + target_duration) is smallest. Real clip
# durations vary slightly around 4s / 6s / 8s but every cut lands on a
# musical beat — ideal for Veo 3.1 (which accepts 4/6/8s inputs).
#
# Requirements: PowerShell 5+ , ffmpeg and ffprobe on PATH.
# Uses stream-copy by default (frame-accurate on ProRes/DNxHR mezzanines
# because every frame is a keyframe). Use -Codec prores or -Codec dnxhr
# to force a re-encode on long-GOP sources.
#
# Usage examples (run from repo root):
#   .\scripts\segment_toolkit\segment.ps1 `
#       -Input   01_mezzanine\showcase_2026-07-18\Showcase-FriendLikeMe-20260718.mov `
#       -Beats   audio\beats_friendlikeme.csv `
#       -OutDir  02_ai_input\friendlikeme_showcase
#
#   .\scripts\segment_toolkit\segment.ps1 `
#       -Input   01_mezzanine\rehearsal_2026-07-15\<rehearsal_filename>.mov `
#       -Beats   audio\beats_friendlikeme.csv `
#       -OutDir  02_ai_input\friendlikeme_rehearsal

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [Alias('Input')]
    [string]$InputVideo,

    [Parameter(Mandatory=$true, Position=1)]
    [Alias('Beats')]
    [string]$BeatsCsv,

    [Parameter(Mandatory=$true, Position=2)]
    [string]$OutDir,

    [ValidateSet('copy','prores','dnxhr')]
    [string]$Codec = 'copy',

    # Accept clips whose real duration is within [1 - Tolerance, 1 + Tolerance] * target
    [double]$Tolerance = 0.40
)

$ErrorActionPreference = 'Stop'

# --- Validate inputs ---
if (-not (Test-Path -LiteralPath $InputVideo)) {
    throw "Input video not found: $InputVideo"
}
if (-not (Test-Path -LiteralPath $BeatsCsv)) {
    throw "Beats CSV not found: $BeatsCsv"
}

# --- Ensure output dir exists, resolve to absolute ---
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path -LiteralPath $OutDir).Path

# --- Load kept beat times, sorted and deduplicated ---
$beats = Import-Csv -LiteralPath $BeatsCsv |
    Where-Object { [int]$_.keep -eq 1 } |
    ForEach-Object { [double]$_.time_seconds } |
    Sort-Object -Unique

if ($beats.Count -lt 2) {
    throw "Need at least 2 kept beats in $BeatsCsv (found $($beats.Count))"
}

# --- Probe video duration ---
$durationRaw = & ffprobe -v error -show_entries format=duration `
    -of default=noprint_wrappers=1:nokey=1 $InputVideo
if ($LASTEXITCODE -ne 0 -or -not $durationRaw) {
    throw "ffprobe failed on $InputVideo (exit $LASTEXITCODE)"
}
$duration = [double]::Parse($durationRaw, [System.Globalization.CultureInfo]::InvariantCulture)

Write-Host ""
Write-Host "Input:      $InputVideo"
Write-Host ("Duration:   {0:F3}s" -f $duration)
Write-Host "Kept beats: $($beats.Count)"
Write-Host "Codec:      $Codec"
Write-Host "Output dir: $OutDir"
Write-Host "Tolerance:  +/- $([int]($Tolerance * 100))% of target"
Write-Host ""

# --- Codec flags ---
switch ($Codec) {
    'copy'   { $vcodecArgs = @('-c','copy'); $ext = 'mov' }
    'prores' { $vcodecArgs = @('-c:v','prores_ks','-profile:v','3','-c:a','pcm_s16le'); $ext = 'mov' }
    'dnxhr'  { $vcodecArgs = @('-c:v','dnxhd','-profile:v','dnxhr_hq','-pix_fmt','yuv422p','-c:a','pcm_s16le'); $ext = 'mov' }
}

# --- Core cutting routine ---
function Cut-Set {
    param(
        [int]$Target
    )

    $setDir = Join-Path $OutDir ("segments_{0}s" -f $Target)
    New-Item -ItemType Directory -Force -Path $setDir | Out-Null

    Write-Host "==> Building $setDir (target ${Target}s per clip)"

    $minDur = $Target * (1.0 - $Tolerance)
    $maxDur = $Target * (1.0 + $Tolerance)

    # Plan the cuts: for each start beat, find the beat closest to start+Target
    $plan = @()
    for ($i = 0; $i -lt $beats.Count; $i++) {
        $start = $beats[$i]
        if ($start -gt ($duration - 1.0)) { continue }

        $want = $start + $Target
        $bestJ = -1
        $bestDiff = [double]::MaxValue

        for ($j = $i + 1; $j -lt $beats.Count; $j++) {
            $diff = [math]::Abs($beats[$j] - $want)
            if ($diff -lt $bestDiff) {
                $bestDiff = $diff
                $bestJ = $j
            }
            if ($beats[$j] -gt ($want + $bestDiff)) { break }
        }

        if ($bestJ -lt 0) { continue }

        $end = [math]::Min($beats[$bestJ], $duration)
        $dur = $end - $start
        if ($dur -lt $minDur -or $dur -gt $maxDur) { continue }

        $plan += [PSCustomObject]@{
            Start    = $start
            End      = $end
            Duration = $dur
        }
    }

    Write-Host "   planned clips: $($plan.Count)"

    if ($plan.Count -eq 0) {
        Write-Host "   (no clips fit within tolerance — skipping)"
        return
    }

    # Manifest header
    $manifestPath = Join-Path $setDir 'manifest.csv'
    "clip,start_seconds,end_seconds,duration_seconds,file" | Out-File -Encoding utf8 -FilePath $manifestPath

    # Cut clips
    $idx = 0
    foreach ($p in $plan) {
        $idx++
        $clipName = "clip_{0:D3}.{1}" -f $idx, $ext
        $clipPath = Join-Path $setDir $clipName

        $startStr = $p.Start.ToString('F3', [System.Globalization.CultureInfo]::InvariantCulture)
        $endStr   = $p.End.ToString('F3',   [System.Globalization.CultureInfo]::InvariantCulture)
        $durStr   = $p.Duration.ToString('F3', [System.Globalization.CultureInfo]::InvariantCulture)

        Write-Host ("   [{0:D3}] {1,7}s -> {2,7}s  ({3}s)  {4}" -f $idx, $startStr, $endStr, $durStr, $clipName)

        $ffmpegArgs = @(
            '-hide_banner','-loglevel','error','-y',
            '-ss', $startStr,
            '-to', $endStr,
            '-i',  $InputVideo,
            '-map','0'
        ) + $vcodecArgs + @(
            '-avoid_negative_ts','make_zero',
            $clipPath
        )

        & ffmpeg @ffmpegArgs
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "ffmpeg failed for clip $idx (exit $LASTEXITCODE) — continuing"
            continue
        }

        # Append to manifest (relative path is friendlier for git)
        $relFile = "segments_{0}s/{1}" -f $Target, $clipName
        "$idx,$startStr,$endStr,$durStr,$relFile" | Out-File -Encoding utf8 -FilePath $manifestPath -Append
    }

    Write-Host "   wrote $manifestPath"
    Write-Host ""
}

Cut-Set -Target 4
Cut-Set -Target 6
Cut-Set -Target 8

Write-Host "Done. Review manifests in:"
Write-Host "  $OutDir\segments_4s\manifest.csv"
Write-Host "  $OutDir\segments_6s\manifest.csv"
Write-Host "  $OutDir\segments_8s\manifest.csv"
