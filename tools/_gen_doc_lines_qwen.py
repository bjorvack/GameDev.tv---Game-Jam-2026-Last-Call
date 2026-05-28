#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""One-shot Doc-Wheeler-line voice generator for Qwen3-TTS-MLX.

Mirrors the structure of tools/_gen_daniel_lines_qwen.py but with
Doc Wheeler's much smaller scope (7 lines across calls 04 and 05)
and his different mood spectrum (default / grave / urgent — never
frantic; Doc never raises his voice).

Each generation: locate the matching mood-specific Heflin-… no,
*Hersholt* reference clip in audio/voice_refs/doc/, attach the
mood-appropriate emotion directive, and let mlx_audio.tts.generate
clone Hersholt's prosody onto the line text. Outputs land at:

    audio/dialogue/doc/<call_num>_<sub_resource_id>.wav

where the existing VoiceResolver picks them up via the same path
convention used for Daniel.

Idempotent: re-runs skip lines whose audio already exists. Delete a
WAV to force a single line to regen.

Generation params per mood — exaggeration kept low compared to
Daniel's frantic settings, because Doc's emotional intensity comes
from sentence brevity and word choice, not volume.
"""
from __future__ import annotations

import re
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CHAR_DIR = REPO / "audio" / "voice_refs" / "doc"
OUT = REPO / "audio" / "dialogue" / "doc"
OUT.mkdir(parents=True, exist_ok=True)

MODEL = "mlx-community/Qwen3-TTS-12Hz-1.7B-Base-bf16"

# Per-mood preset: (reference_wav_filename, exaggeration, instruct).
# Exaggeration kept low for Doc — his urgency is in sentence
# brevity, not raised volume. The reference clips (Jean Hersholt
# from Dr. Christian, 1937 + 1938) already carry the right baseline
# weariness, kindness, and clipped delivery; the directive nudges
# rather than overrides.
MOODS: dict[str, tuple[str, float, str]] = {
    "default": (
        "default.wav",
        1.0,
        "calm, weary, kindly, conversational, professional",
    ),
    "grave": (
        "grave.wav",
        1.2,
        "slow, picking every word, delivering bad news with practical kindness, controlled sadness, never raising voice",
    ),
    "urgent": (
        "urgent.wav",
        1.2,
        "clipped, focused, terse, quiet urgency, fatherly authority, never raised",
    ),
}

# Per-line: (call_num, sub_resource_id) → (mood, tts_text).
# Doc's lines don't need v3-textboost edits — natural punctuation
# (em-dashes, ellipses, periods) already shape the prosody. When
# tts_text matches the .tres display text, no voice_text override
# is written.
LINES: dict[tuple[str, str], tuple[str, str]] = {
    # Call 04 — Reverend Carter calling Doc to come to the Chapel
    ("04", "connected_pickup"): ("default", "Wheeler."),
    ("04", "connected_0"):      ("default", "On my way, Reverend."),
    # Call 05 — Daniel calling, Doc tells him his mother has turned
    ("05", "connected_pickup"): ("default", "Wheeler."),
    ("05", "connected_0"):      ("grave",   "Daniel… your mother came in Thursday with chest pains."),
    ("05", "connected_1"):      ("grave",   "I told her to call me at the first sign it came back."),
    ("05", "connected_2"):      ("urgent",  "Son — get home. Fast."),
    ("05", "wrong_doc_0"):      ("default", "Wheeler."),
}

CALL_PATHS: dict[str, Path] = {
    "04": REPO / "data" / "calls" / "04_reverend_doc.tres",
    "05": REPO / "data" / "calls" / "05_daniel_doc.tres",
}


def _escape_tres_string(value: str) -> str:
    return value.replace("\\", "\\\\").replace('"', '\\"')


def _read_block_field(body: list[str], field: str) -> str | None:
    prefix = f"{field} = "
    for ln in body:
        if ln.startswith(prefix):
            raw = ln[len(prefix):]
            if raw.startswith("&"):
                raw = raw[1:]
            return raw.strip().strip('"')
    return None


def _upsert_field(body: list[str], field: str, value: str, insert_after: str) -> bool:
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
    raw = path.read_text()
    lines = raw.splitlines()
    target_header = f'[sub_resource type="Resource" id="{sub_id}"]'

    in_target = False
    body_start = -1
    body_end = -1
    for i, ln in enumerate(lines):
        if not in_target:
            if ln == target_header:
                in_target = True
                body_start = i + 1
            continue
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
    final_path = OUT / f"{line_id}.wav"
    if final_path.exists():
        print("    skip (exists)")
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
            print(f"  edit {tres.name}::{sub_id}  mood={mood}")
        print(f"{line_id}  mood={mood}")
        if generate_audio(line_id, mood, tts_text):
            ok += 1
        else:
            fail += 1
    print(f"\nDone: {ok}/{ok + fail} clips generated, {tres_edits} .tres edits.")
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
