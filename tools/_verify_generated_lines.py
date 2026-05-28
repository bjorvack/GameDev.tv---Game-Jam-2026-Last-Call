#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""Sanity check: transcribe every generated voice clip and compare
the result against the source DialogueLine text. Flags lines where
the TTS got the words wrong.

For each clip in audio/dialogue/<slug>/<call_num>_<sub_id>.wav, look
up the matching DialogueLine in data/calls/<call_file>.tres, then
whisper-transcribe the audio. Reports a per-line similarity score
based on word-token overlap after light normalisation (lowercase,
strip punctuation, collapse whitespace).

Output sections:
  - OK     — high overlap, clip says what it should
  - WARN   — moderate overlap, might be slight misread
  - FAIL   — low overlap, clip likely says the wrong thing
  - SKIP   — no audio file generated for this line
"""
from __future__ import annotations

import re
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CHAR_DIR = REPO / "data" / "characters"
CALLS_DIR = REPO / "data" / "calls"
DIALOGUE_BASE = REPO / "audio" / "dialogue"
TRANSCRIPTS = Path(tempfile.mkdtemp(prefix="voice_verify_"))


_SUB_RE = re.compile(r'^\[sub_resource type="Resource" id="(.+)"\]$')
_FIELD_RE = re.compile(r'^(speaker|text|voice_text|mood) = (.+)$')


def parse_lines(tres_path: Path) -> list[dict]:
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
        if current is None or not ln.strip():
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
    return [b for b in blocks if b.get("text") is not None]


def load_char_map() -> dict[str, str]:
    out: dict[str, str] = {}
    for tres in sorted(CHAR_DIR.glob("*.tres")):
        slug = tres.stem
        text = tres.read_text()
        nm = re.search(r'^name = "(.*?)"$', text, re.M)
        if not nm:
            continue
        out[nm.group(1)] = slug
        ab = re.search(r'aliases = Array\[StringName\]\(\[(.*?)\]\)', text)
        if ab:
            for m in re.finditer(r'&"(.*?)"', ab.group(1)):
                out[m.group(1)] = slug
    return out


def normalize_for_compare(s: str) -> list[str]:
    s = s.lower()
    s = re.sub(r"…", " ", s)
    s = re.sub(r"[^a-z0-9' ]", " ", s)
    return [w for w in s.split() if w]


def jaccard(a: list[str], b: list[str]) -> float:
    if not a and not b:
        return 1.0
    if not a or not b:
        return 0.0
    sa = set(a)
    sb = set(b)
    return len(sa & sb) / len(sa | sb)


def length_ratio_penalty(a: list[str], b: list[str]) -> float:
    """Detect looping — if `got` is much longer than `expected`,
    the TTS likely repeated a word. Returns a multiplier in [0, 1]."""
    if not a:
        return 1.0
    ratio = len(b) / len(a)
    if ratio <= 1.5:
        return 1.0
    if ratio >= 3.0:
        return 0.0
    return (3.0 - ratio) / 1.5


def whisper_transcribe(wav: Path) -> str:
    cmd = [
        "whisper", str(wav),
        "--model", "base",
        "--language", "English",
        "--task", "transcribe",
        "--output_format", "txt",
        "--output_dir", str(TRANSCRIPTS),
        "--verbose", "False",
    ]
    subprocess.run(cmd, capture_output=True)
    out = TRANSCRIPTS / f"{wav.stem}.txt"
    return out.read_text().strip() if out.exists() else ""


def main() -> int:
    char_map = load_char_map()
    results: list[tuple[str, str, str, str, float]] = []  # (status, file, expected, got, score)

    for tres_path in sorted(CALLS_DIR.glob("*.tres")):
        call_num = tres_path.stem.split("_")[0]
        for line in parse_lines(tres_path):
            slug = char_map.get(line["speaker"])
            if slug is None:
                continue
            line_id = f"{call_num}_{line['id']}"
            wav = DIALOGUE_BASE / slug / f"{line_id}.wav"
            expected = line.get("voice_text") or line["text"]
            if not wav.exists():
                results.append(("SKIP", str(wav.relative_to(REPO)), expected, "", 0.0))
                continue
            got = whisper_transcribe(wav)
            ne = normalize_for_compare(expected)
            ng = normalize_for_compare(got)
            score = jaccard(ne, ng) * length_ratio_penalty(ne, ng)
            if score >= 0.7:
                status = "OK"
            elif score >= 0.4:
                status = "WARN"
            else:
                status = "FAIL"
            results.append((status, str(wav.relative_to(REPO)), expected, got, score))

    counts = {"OK": 0, "WARN": 0, "FAIL": 0, "SKIP": 0}
    for status, *_ in results:
        counts[status] += 1

    for status in ("FAIL", "WARN", "SKIP", "OK"):
        rows = [r for r in results if r[0] == status]
        if not rows:
            continue
        print(f"\n=== {status} ({len(rows)}) ===")
        for _, fname, expected, got, score in rows:
            print(f"  [{score:.2f}] {fname}")
            print(f"        expected: {expected!r}")
            print(f"        got     : {got!r}")
    print(f"\nSummary: OK={counts['OK']} WARN={counts['WARN']} "
          f"FAIL={counts['FAIL']} SKIP={counts['SKIP']} "
          f"total={sum(counts.values())}")
    return 0 if counts["FAIL"] == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
