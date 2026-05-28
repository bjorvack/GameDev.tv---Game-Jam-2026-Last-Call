#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""One-shot Daniel-line voice generator for Qwen3-TTS-MLX.

Successor to tools/_gen_daniel_lines.py (which targeted F5-TTS-MLX).
Two passes per line:

  1. Annotate the call .tres file in place — set DialogueLine.mood
     when non-default, set voice_text when the v3-boosted TTS text
     differs from the display text. These edits persist the mood/
     voice mapping so the runtime VoiceResolver and any future
     pipeline can reproduce results from the source data alone.

  2. Generate the WAV via `mlx_audio.tts.generate`, using the per-
     mood preset (matching reference clip + exaggeration + emotion
     instruction). Files land at:

         audio/dialogue/daniel/<call_num>_<sub_resource_id>.wav

     which the existing VoiceResolver maps automatically.

Idempotent: re-runs skip lines whose audio already exists. To regen
a single line, delete its WAV and re-run.

Generation params per mood
==========================

The directives + exaggeration come from the demo iteration where we
landed on "v3-textboost" as the best balance. Mood-matched reference
clips (Heflin in matching emotional register) give the model a
strong prosody prior; the directive nudges the delivery; the
exaggeration boost adds the punch the directive alone left short.
"""
from __future__ import annotations

import re
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CHAR_DIR = REPO / "audio" / "voice_refs" / "daniel"
OUT = REPO / "audio" / "dialogue" / "daniel"
OUT.mkdir(parents=True, exist_ok=True)

MODEL = "mlx-community/Qwen3-TTS-12Hz-1.7B-Base-bf16"

# Per-mood preset: (reference_wav_filename, exaggeration, instruct).
# The reference's prosody is the dominant prior on Qwen3-TTS; the
# instruct nudges; exaggeration amplifies the result. Locked in via
# A/B testing — see audio/voice_refs/TODO.md "Generation params".
MOODS: dict[str, tuple[str, float, str]] = {
    "default": (
        "default.wav",
        1.0,
        "calm, weary, quiet, controlled, resigned",
    ),
    "anxious": (
        "anxious.wav",
        1.3,
        "panicked, voice tightening, words rushing, desperate",
    ),
    "frantic": (
        "frantic.wav",
        2.0,
        "frantic, voice breaking, screaming",
    ),
}

# Per-line: (call_num, sub_resource_id) → (mood, tts_text)
#
# `tts_text` is what gets fed to Qwen3 verbatim — already includes
# the v3-textboost edits (selective ALL-CAPS, exclamations, em-dashes).
# When `tts_text` differs from the DialogueLine's display `text`, the
# script writes it to `voice_text` in the .tres so future regens and
# the runtime see the same value.
#
# Default-mood lines that don't need text boosting keep tts_text
# identical to display text — no voice_text override gets written.
LINES: dict[tuple[str, str], tuple[str, str]] = {
    # Call 02 — routine call to mother, edges into worry
    ("02", "opening_0"):     ("anxious", "Operator — please!"),
    ("02", "opening_1"):     ("default", "I need to reach Mrs. Hayes on 7th and Vine — my mother. She missed her morning call and I've been on the road all day."),
    ("02", "opening_2"):     ("default", "I'm two hours out on Highway 40."),
    ("02", "connected_1"):   ("anxious", "She, she must've gone to the market."),
    ("02", "connected_2"):   ("anxious", "I'll try again from the next stop. Thanks, operator."),
    ("02", "generic_1"):     ("default", "Sorry, wrong number."),
    ("02", "timer_0"):       ("anxious", "Operator?! Operator, PLEASE. I'll call back."),
    ("02", "wrong_doc_1"):   ("default", "Doc — sorry, wrong line. I'm trying to reach Mom."),
    ("02", "wrong_patty_1"): ("default", "Patty — wrong line, sorry. Have you seen Mom today?"),
    # Call 05 — Doc tells Daniel his mother has turned
    ("05", "opening_0"):     ("anxious", "Operator, it's Daniel Hayes. Pulled off at the diesel stop, marker 88."),
    ("05", "opening_1"):     ("anxious", "Try Mom again — 7th and Vine. PLEASE."),
    ("05", "connected_explain"): ("anxious", "Doc — it's Daniel. Mom's NOT answering. I'm on Hwy 40, two hours out. Did she—"),
    ("05", "timer_0"):       ("frantic", "Operator?! I'm LOSING SIGNAL! Try again — PLEASE!"),
    ("05", "first_leg_1"):   ("frantic", "Damn. DAMN IT!"),
    ("05", "first_leg_2"):   ("anxious", "Operator — try Doc Wheeler! She had a check-up Thursday. He might know."),
    ("05", "generic_1"):     ("anxious", "Sorry — wrong line."),
    ("05", "wrong_doc_1"):   ("anxious", "Doc — sorry, wrong line. Operator, I asked for MOM. 7th and Vine, please."),
    ("05", "wrong_sheriff_1"): ("anxious", "Sheriff — wrong line, sorry. I'm trying to reach my mom."),
    # Call 07 — frantic plea to the Reverend
    ("07", "opening_0"):     ("frantic", "OPERATOR! The Chapel, Reverend Carter!"),
    ("07", "opening_1"):     ("frantic", "Hurry! PLEASE!"),
    ("07", "connected_explain"): ("frantic", "REVEREND, it's Daniel! Mom's not picking up and Doc says she's BAD. Can you—"),
    ("07", "timer_0"):       ("frantic", "Operator?! OPERATOR! PLEASE!"),
    ("07", "generic_1"):     ("anxious", "Sorry — wrong line."),
    ("07", "wrong_doc_1"):   ("frantic", "DOC, I need the Chapel! The Reverend!"),
    # Call 10 — hospital, breath catches between lines
    ("10", "opening_0"):     ("frantic", "Operator… PLEASE!"),
    ("10", "opening_1"):     ("anxious", "County General. I'm in the parking lot."),
    ("10", "opening_2"):     ("frantic", "I NEED to know if I can still—"),
    ("10", "connected_choke"): ("anxious", "Is she—"),
    ("10", "generic_1"):     ("anxious", "Sorry — operator, the hospital. PLEASE."),
    ("10", "wrong_hayes_1"): ("frantic", "NO! The hospital, operator. The HOSPITAL!"),
}

CALL_PATHS: dict[str, Path] = {
    "02": REPO / "data" / "calls" / "02_daniel_hayes.tres",
    "05": REPO / "data" / "calls" / "05_daniel_doc.tres",
    "07": REPO / "data" / "calls" / "07_daniel_reverend.tres",
    "10": REPO / "data" / "calls" / "10_daniel_hospital.tres",
}


def _escape_tres_string(value: str) -> str:
    """Escape a string for inclusion in a .tres double-quoted value.
    Backslashes first, then quotes."""
    return value.replace("\\", "\\\\").replace('"', '\\"')


def _read_block_field(body: list[str], field: str) -> str | None:
    """Return the value of a field in a sub_resource block, or None
    if not present. Strips surrounding quotes and StringName `&` prefix."""
    prefix = f"{field} = "
    for ln in body:
        if ln.startswith(prefix):
            raw = ln[len(prefix):]
            if raw.startswith("&"):
                raw = raw[1:]
            return raw.strip().strip('"')
    return None


def _upsert_field(body: list[str], field: str, value: str, insert_after: str) -> bool:
    """Set or insert a `field = value` line in `body`. Returns True if
    body was modified. If the field already exists with the same value,
    no-op."""
    prefix = f"{field} = "
    new_line = f"{prefix}{value}"
    for i, ln in enumerate(body):
        if ln.startswith(prefix):
            if ln == new_line:
                return False
            body[i] = new_line
            return True
    insert_after_prefix = f"{insert_after} = "
    for i, ln in enumerate(body):
        if ln.startswith(insert_after_prefix):
            body.insert(i + 1, new_line)
            return True
    body.append(new_line)
    return True


def update_tres_block(path: Path, sub_id: str, mood: str, tts_text: str) -> bool:
    """Edit one sub_resource block in a .tres file:
       - Set `mood = &"<mood>"` when mood != default.
       - Set `voice_text = "<tts_text>"` when tts_text differs from
         the existing display `text` field.
    Returns True when the file was modified."""
    raw = path.read_text()
    lines = raw.splitlines()
    target_header = f'[sub_resource type="Resource" id="{sub_id}"]'

    in_target = False
    header_idx = -1
    body_start = -1
    body_end = -1
    for i, ln in enumerate(lines):
        if not in_target:
            if ln == target_header:
                in_target = True
                header_idx = i
                body_start = i + 1
            continue
        # Inside target block: stops at next [section] or blank line.
        if ln.startswith("[") or ln.strip() == "":
            body_end = i
            break
    if not in_target:
        print(f"  WARN: sub_resource {sub_id} not found in {path.name}")
        return False
    if body_end == -1:
        body_end = len(lines)

    body = list(lines[body_start:body_end])
    display_text = _read_block_field(body, "text") or ""
    modified = False

    if mood != "default":
        if _upsert_field(body, "mood", f'&"{mood}"', insert_after="text"):
            modified = True

    if tts_text != display_text:
        escaped = _escape_tres_string(tts_text)
        if _upsert_field(body, "voice_text", f'"{escaped}"', insert_after="text"):
            modified = True

    if not modified:
        return False
    new_lines = lines[:body_start] + body + lines[body_end:]
    path.write_text("\n".join(new_lines) + ("\n" if raw.endswith("\n") else ""))
    return True


def generate_audio(line_id: str, mood: str, tts_text: str) -> bool:
    """Call mlx_audio.tts.generate for one line. Returns True on
    success or pre-existing output, False on failure."""
    final_path = OUT / f"{line_id}.wav"
    if final_path.exists():
        print(f"    skip (exists)")
        return True

    ref_file, exag, instruct = MOODS[mood]
    ref_path = CHAR_DIR / ref_file
    ref_text = (CHAR_DIR / f"{ref_file[:-4]}.txt").read_text().strip()

    cmd = [
        "mlx_audio.tts.generate",
        "--model", MODEL,
        "--ref_audio", str(ref_path),
        "--ref_text", ref_text,
        "--text", tts_text,
        "--instruct", instruct,
        "--exaggeration", str(exag),
        "--output_path", str(OUT),
        "--file_prefix", line_id,
    ]
    start = time.monotonic()
    result = subprocess.run(cmd, capture_output=True, text=True)
    elapsed = time.monotonic() - start
    if result.returncode != 0:
        print(f"    FAILED in {elapsed:.1f}s: {result.stderr.strip()[-400:]}")
        return False

    # mlx_audio adds a _000 suffix by default; rename to drop it so the
    # VoiceResolver's <call>_<sub_id>.wav convention is matched exactly.
    suffixed = OUT / f"{line_id}_000.wav"
    if suffixed.exists():
        suffixed.rename(final_path)
        print(f"    ok in {elapsed:.1f}s")
        return True
    print(f"    FAILED in {elapsed:.1f}s: expected {suffixed.name} not produced")
    return False


def main() -> int:
    tres_edits = 0
    ok = 0
    fail = 0
    for (call_num, sub_id), (mood, tts_text) in LINES.items():
        line_id = f"{call_num}_{sub_id}"
        tres = CALL_PATHS[call_num]
        if update_tres_block(tres, sub_id, mood, tts_text):
            tres_edits += 1
            print(f"  edit {tres.name}::{sub_id}  mood={mood}  voice_text={'(set)' if tts_text else '(unset)'}")
        print(f"{line_id}  mood={mood}")
        if generate_audio(line_id, mood, tts_text):
            ok += 1
        else:
            fail += 1
    print(f"\nDone: {ok}/{ok + fail} clips generated, {tres_edits} .tres edits.")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
