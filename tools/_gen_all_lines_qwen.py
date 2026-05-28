#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Unified voice-line generator for the full cast.

Walks every CallData .tres file, identifies each DialogueLine,
looks up the matching Character resource (by speaker name + aliases),
and generates voice audio via Qwen3-TTS-MLX-Base using the
character's single default reference clip + a per-mood --instruct
directive.

Single-reference-per-character architecture: we no longer source
multiple emotional reference clips per speaker — Qwen3-Instruct
controls the emotional register via natural-language directive on a
single neutral reference. The reference clip just defines the voice
timbre.

Outputs land at audio/dialogue/<slug>/<call_num>_<sub_resource_id>.wav,
loudness-normalised to -16 LUFS so all clips sit at the same level.
Idempotent — re-runs skip lines whose audio already exists.

The unknown.tres character reuses mrs_bray's reference clip (shared
startled-stranger archetype) — see read_character_ref().
"""
from __future__ import annotations

import re
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CHAR_DIR = REPO / "data" / "characters"
CALLS_DIR = REPO / "data" / "calls"
VOICE_REFS = REPO / "audio" / "voice_refs"
OUT_BASE = REPO / "audio" / "dialogue"

MODEL = "mlx-community/Qwen3-TTS-12Hz-1.7B-Base-bf16"

# Per-mood directive + exaggeration. Drives Qwen3-Instruct's emotional
# adaptation when applied on top of a neutral reference clip.
MOOD_PRESETS: dict[str, tuple[str, float]] = {
    "default":  ("calm, conversational", 1.0),
    "anxious":  ("anxious, voice tightening, words rushing, breathless", 1.4),
    "frantic":  ("frantic, voice breaking, screaming, desperate", 1.8),
    "grave":    ("slow, picking every word, delivering bad news with practical kindness, controlled sadness", 1.2),
    "urgent":   ("clipped, focused, terse, quiet urgency, never raised", 1.2),
    "worried":  ("worried, voice strained with dread underneath", 1.3),
    "relieved": ("warm, gentle, quiet relief", 1.0),
    "shocked":  ("quiet shock, dawning realisation, voice trailing", 1.3),
}

# unknown reuses mrs_bray's reference for the shared "startled stranger"
# voice archetype.
SHARED_REFS: dict[str, str] = {
    "unknown": "mrs_bray",
}


_SUB_RE = re.compile(r'^\[sub_resource type="Resource" id="(.+)"\]$')
_FIELD_RE = re.compile(r'^(speaker|text|voice_text|mood) = (.+)$')


def parse_dialogue_lines(tres_path: Path) -> list[dict]:
    blocks: list[dict] = []
    current: dict | None = None
    for ln in tres_path.read_text().splitlines():
        if ln.startswith("[sub_resource"):
            m = _SUB_RE.match(ln)
            if m:
                if current and current.get("text") is not None:
                    blocks.append(current)
                current = {"id": m.group(1), "speaker": "", "text": None, "voice_text": "", "mood": ""}
            continue
        if ln.startswith("[") and current is not None:
            if current.get("text") is not None:
                blocks.append(current)
            current = None
            continue
        if current is None:
            continue
        if ln.strip() == "":
            continue
        m = _FIELD_RE.match(ln)
        if not m:
            continue
        key, value = m.group(1), m.group(2)
        if value.startswith("&"):
            value = value[1:]
        current[key] = value.strip().strip('"')
    if current and current.get("text") is not None:
        blocks.append(current)
    # Filter for DialogueLine-shaped sub_resources (anything with a `text` field)
    return [b for b in blocks if b.get("text") is not None]


def load_character_map() -> dict[str, str]:
    """Return {speaker_name_or_alias: slug}."""
    out: dict[str, str] = {}
    for tres in sorted(CHAR_DIR.glob("*.tres")):
        slug = tres.stem
        text = tres.read_text()
        name_match = re.search(r'^name = "(.*?)"$', text, re.M)
        if not name_match:
            continue
        out[name_match.group(1)] = slug
        alias_block = re.search(r'aliases = Array\[StringName\]\(\[(.*?)\]\)', text)
        if alias_block:
            for m in re.finditer(r'&"(.*?)"', alias_block.group(1)):
                out[m.group(1)] = slug
    return out


def auto_normalize(display_text: str) -> str | None:
    """Apply text-cleanup rules. Returns None for fully-parenthetical
    stage directions that should be skipped entirely."""
    t = display_text.strip()
    if re.fullmatch(r"\(.*\)", t):
        return None
    t = re.sub(r"…", ",", t)
    t = re.sub(r"\.{3,}", ",", t)
    def collapse(m: re.Match) -> str:
        return "?" if "?" in m.group(0) else "!"
    t = re.sub(r"[?!]{2,}", collapse, t)
    t = re.sub(r"\s*\([^)]*\)", "", t)
    return t.strip()


def read_character_ref(slug: str) -> tuple[Path, str]:
    voice_slug = SHARED_REFS.get(slug, slug)
    wav = VOICE_REFS / voice_slug / "default.wav"
    txt = (VOICE_REFS / voice_slug / "default.txt").read_text().strip()
    return wav, txt


def generate_line(slug: str, ref_wav: Path, ref_text: str,
                  line_id: str, mood: str, tts_text: str) -> str:
    """Return 'ok', 'skip', or 'fail'."""
    out_dir = OUT_BASE / slug
    out_dir.mkdir(parents=True, exist_ok=True)
    final_path = out_dir / f"{line_id}.wav"
    if final_path.exists():
        return "skip"

    instruct, exag = MOOD_PRESETS.get(mood or "default", MOOD_PRESETS["default"])
    cmd = [
        "mlx_audio.tts.generate",
        "--model", MODEL,
        "--ref_audio", str(ref_wav),
        "--ref_text", ref_text,
        "--text", tts_text,
        "--instruct", instruct,
        "--exaggeration", str(exag),
        "--output_path", str(out_dir),
        "--file_prefix", line_id,
    ]
    start = time.monotonic()
    result = subprocess.run(cmd, capture_output=True, text=True)
    elapsed = time.monotonic() - start
    if result.returncode != 0:
        print(f"FAILED in {elapsed:.1f}s: {result.stderr.strip()[-200:]}")
        return "fail"

    suffixed = out_dir / f"{line_id}_000.wav"
    if not suffixed.exists():
        print(f"FAILED in {elapsed:.1f}s: expected {suffixed.name} not produced")
        return "fail"
    suffixed.rename(final_path)

    # Loudness normalise to -16 LUFS so every clip sits at the same level.
    tmp = out_dir / f"{line_id}.norm.wav"
    norm_cmd = [
        "ffmpeg", "-y", "-i", str(final_path),
        "-af", "loudnorm=I=-16:LRA=11:TP=-1.5",
        "-ar", "24000", "-ac", "1", "-sample_fmt", "s16",
        "-loglevel", "error",
        str(tmp),
    ]
    if subprocess.run(norm_cmd).returncode == 0:
        tmp.replace(final_path)
    print(f"ok in {elapsed:.1f}s")
    return "ok"


def main() -> int:
    char_map = load_character_map()
    print(f"Speaker → slug map ({len(char_map)} entries):")
    seen_slugs = sorted(set(char_map.values()))
    for slug in seen_slugs:
        names = [n for n, s in char_map.items() if s == slug]
        print(f"  {slug:<10}  ← {names}")
    print()

    ref_cache: dict[str, tuple[Path, str]] = {}
    counts = {"ok": 0, "skip": 0, "fail": 0, "no_char": 0, "stage_dir": 0}

    call_paths = sorted(CALLS_DIR.glob("*.tres"))
    for tres_path in call_paths:
        call_num = tres_path.stem.split("_")[0]
        lines = parse_dialogue_lines(tres_path)
        print(f"\n== {tres_path.name} — {len(lines)} dialogue lines ==")
        for line in lines:
            speaker = line["speaker"]
            slug = char_map.get(speaker)
            if slug is None:
                print(f"  [{line['id']:<22}] no character for speaker '{speaker}'")
                counts["no_char"] += 1
                continue

            voice_text = line.get("voice_text") or ""
            tts_text = voice_text if voice_text else auto_normalize(line["text"])
            if not tts_text:
                print(f"  [{line['id']:<22}] {slug:<10} stage direction — skip")
                counts["stage_dir"] += 1
                continue

            if slug not in ref_cache:
                ref_cache[slug] = read_character_ref(slug)
            ref_wav, ref_text = ref_cache[slug]

            mood = line.get("mood") or "default"
            line_id = f"{call_num}_{line['id']}"
            print(f"  [{line['id']:<22}] {slug:<10} mood={mood:<8} ", end="", flush=True)
            status = generate_line(slug, ref_wav, ref_text, line_id, mood, tts_text)
            counts[status] += 1

    total = sum(counts.values())
    print(f"\nDone: ok={counts['ok']} skip={counts['skip']} fail={counts['fail']} "
          f"no_char={counts['no_char']} stage_dir={counts['stage_dir']} total={total}")
    return 0 if counts['fail'] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
