#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""One-shot Daniel-line voice generator.

Walks the four Daniel calls (02, 05, 07, 10), parses every
DialogueLine whose `speaker = "Daniel"`, applies the auto-normalisation
rules from audio/voice_refs/TODO.md, looks up the mood-specific
reference clip from audio/voice_refs/daniel/, and runs F5-TTS-MLX
to produce one WAV per line.

The (call_id, sub_resource_id) → mood mapping is hardcoded here as a
scratch substitute for proper `DialogueLine.mood` annotations, which
we'll persist in `.tres` files once the audio passes a listening
review. Lines that don't appear in the map default to the speaker's
"default" reference, matching Character.get_voice() runtime semantics.

Outputs land in /tmp/daniel_lines/ (writable scratch). Run from the
repo root via `tools/_gen_daniel_lines.py`. Idempotent — re-runs skip
files that already exist.
"""
from __future__ import annotations

import re
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CHAR_DIR = REPO / "audio" / "voice_refs" / "daniel"
OUT = Path("/tmp/daniel_lines")
OUT.mkdir(parents=True, exist_ok=True)

# F5-TTS-MLX generation parameters tuned during the Daniel demo —
# see audio/voice_refs/TODO.md "Generation params" for the rationale.
F5_STEPS = 32
F5_METHOD = "euler"
F5_SEED = 1

# Per (call_number, sub_resource_id) → mood. Lines absent from this
# table fall through to "default" — same fallback Character.get_voice()
# applies at runtime.
MOODS: dict[tuple[str, str], str] = {
    # Call 02 — routine check-in turning slightly worried.
    ("02", "connected_1"): "anxious",  # "She… she must've gone to the market."
    ("02", "opening_0"): "anxious",  # "Operator — please."
    ("02", "timer_0"): "anxious",  # "Operator? Operator, please — I'll call back."
    # Call 05 — Doc tells him his mother has turned. All non-default.
    ("05", "connected_explain"): "anxious",
    ("05", "first_leg_1"): "frantic",  # "Damn. Damn it."
    ("05", "first_leg_2"): "anxious",
    ("05", "generic_1"): "anxious",
    ("05", "opening_0"): "anxious",
    ("05", "opening_1"): "anxious",
    ("05", "timer_0"): "frantic",  # "Operator? I'm losing signal..."
    ("05", "wrong_doc_1"): "anxious",
    ("05", "wrong_sheriff_1"): "anxious",
    # Call 07 — full panic. Calls the Reverend.
    ("07", "connected_explain"): "frantic",
    ("07", "generic_1"): "anxious",  # the only composed-ish line
    ("07", "opening_0"): "frantic",
    ("07", "opening_1"): "frantic",  # "Hurry, please."
    ("07", "timer_0"): "frantic",  # "Operator?? OPERATOR."
    ("07", "wrong_doc_1"): "frantic",
    # Call 10 — hospital. Mix of frantic and breathless anxiety.
    ("10", "connected_choke"): "anxious",  # "…is she—"
    ("10", "generic_1"): "anxious",
    ("10", "opening_0"): "frantic",  # "Operator… please."
    ("10", "opening_1"): "anxious",
    ("10", "opening_2"): "frantic",  # "I need to know if I can still — "
    ("10", "wrong_hayes_1"): "frantic",
}

CALL_PATHS = {
    "02": REPO / "data" / "calls" / "02_daniel_hayes.tres",
    "05": REPO / "data" / "calls" / "05_daniel_doc.tres",
    "07": REPO / "data" / "calls" / "07_daniel_reverend.tres",
    "10": REPO / "data" / "calls" / "10_daniel_hospital.tres",
}


def auto_normalize(display_text: str) -> str | None:
    """Apply the rules from audio/voice_refs/TODO.md "Display text vs
    voice text". Returns None for fully-parenthetical lines (stage
    directions that should be skipped entirely)."""
    t = display_text.strip()
    if re.fullmatch(r"\(.*\)", t):
        return None
    # Ellipses (Unicode or three+ ASCII dots) → comma.
    t = re.sub(r"…", ",", t)
    t = re.sub(r"\.{3,}", ",", t)
    # Repeated ? / ! → single. Pick the dominant mark in the run.
    def collapse(match: re.Match) -> str:
        run = match.group(0)
        return "?" if "?" in run else "!"
    t = re.sub(r"[?!]{2,}", collapse, t)
    # Inline (parenthetical) asides → strip (rare; not common in our
    # call data but documented in TODO.md).
    t = re.sub(r"\s*\([^)]*\)", "", t)
    return t.strip()


_KEY_RE = re.compile(r"^\[sub_resource type=\"Resource\" id=\"(.+)\"\]$")
_FIELD_RE = re.compile(r"^(speaker|text|voice_text|mood) = (.+)$")


def parse_daniel_lines(call_num: str, path: Path) -> list[dict]:
    """Walk the .tres text, return each Daniel DialogueLine as a dict
    with id, speaker, text, voice_text, mood. Mood comes from the
    in-script MOODS map rather than the .tres file — when we wire
    the proper pipeline this'll read from line.mood instead."""
    blocks: list[dict] = []
    current: dict | None = None
    for raw in path.read_text().splitlines():
        m = _KEY_RE.match(raw)
        if m:
            current = {"id": m.group(1), "speaker": "", "text": "", "voice_text": "", "mood": ""}
            continue
        if current is None:
            continue
        if raw.strip() == "":
            if current["speaker"] == "Daniel":
                blocks.append(current)
            current = None
            continue
        f = _FIELD_RE.match(raw)
        if f:
            key, value = f.group(1), f.group(2)
            # StringName prefix '&"..."' or plain '"..."' → strip both.
            if value.startswith("&"):
                value = value[1:]
            current[key] = value.strip().strip('"')
    if current and current["speaker"] == "Daniel":
        blocks.append(current)
    # Layer in the hardcoded mood mapping for this script's run.
    for b in blocks:
        b["mood"] = MOODS.get((call_num, b["id"]), "default")
    return blocks


def load_ref(mood: str) -> tuple[Path, str]:
    """Resolve the (wav, transcript) pair for a given mood, with
    fallback to default — mirrors Character.get_voice()."""
    wav = CHAR_DIR / f"{mood}.wav"
    txt = CHAR_DIR / f"{mood}.txt"
    if not wav.exists() or not txt.exists():
        wav = CHAR_DIR / "default.wav"
        txt = CHAR_DIR / "default.txt"
    return wav, txt.read_text().strip()


def generate_line(call_num: str, line: dict) -> bool:
    """Generate one voice line via F5-TTS-MLX subprocess. Returns
    True on success, False if the line is skipped or generation
    fails."""
    display_text = line["text"]
    override = line.get("voice_text", "").strip()
    voice_text = override if override else auto_normalize(display_text)
    if voice_text is None or voice_text == "":
        print(f"  SKIP {line['id']}: stage direction or empty")
        return False

    mood = line["mood"] or "default"
    ref_wav, ref_text = load_ref(mood)
    out_path = OUT / f"call{call_num}_{line['id']}_{mood}.wav"

    print(f"  {line['id']:<20} mood={mood}")
    print(f"    text       : {display_text}")
    if override:
        print(f"    voice_text : {voice_text} [override]")
    elif voice_text != display_text:
        print(f"    voice_text : {voice_text} [auto-normalised]")
    print(f"    ref        : {ref_wav.name}")
    print(f"    -> {out_path}")

    if out_path.exists():
        print("    skip (already exists)")
        return True

    cmd = [
        "uv", "tool", "run", "--from", "f5-tts-mlx",
        "python", "-m", "f5_tts_mlx.generate",
        "--ref-audio", str(ref_wav),
        "--ref-text", ref_text,
        "--text", voice_text,
        "--output", str(out_path),
        "--seed", str(F5_SEED),
        "--steps", str(F5_STEPS),
        "--method", F5_METHOD,
    ]
    start = time.monotonic()
    result = subprocess.run(cmd, capture_output=True, text=True)
    elapsed = time.monotonic() - start
    if result.returncode != 0:
        print(f"    FAILED in {elapsed:.1f}s: {result.stderr.strip()[-400:]}")
        return False
    # F5-TTS-MLX prints "Generated Xs of audio in Y" to stderr — grab
    # the duration for a sanity check on the result.
    duration_match = re.search(r"Generated ([\d.]+)s of audio", result.stderr)
    duration = float(duration_match.group(1)) if duration_match else 0.0
    print(f"    ok in {elapsed:.1f}s — produced {duration:.2f}s of audio")
    return True


def main() -> int:
    total = 0
    ok = 0
    for call_num, path in CALL_PATHS.items():
        lines = parse_daniel_lines(call_num, path)
        print(f"\n== call {call_num} — {len(lines)} Daniel lines ==")
        for line in lines:
            total += 1
            if generate_line(call_num, line):
                ok += 1
    print(f"\nDone: {ok}/{total} lines generated. Output in {OUT}")
    return 0 if ok == total else 1


if __name__ == "__main__":
    sys.exit(main())
