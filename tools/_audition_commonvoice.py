#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "datasets>=2.14",
#   "soundfile>=0.12",
#   "librosa>=0.10",
#   "huggingface_hub>=0.23",
# ]
# ///
"""Audition Mozilla Common Voice clips that match Daniel's voice
casting brief, save them locally, and print their sentence text so we
can pick a reference.

Streams from `mozilla-foundation/common_voice_17_0` so we don't pull
the full corpus. Filter targets:

  - gender == "male_masculine"
  - age in {thirties, forties}
  - accent contains "United States" or "American"
  - sentence length 30-120 chars (≈ 5-10s of speech, the F5/Qwen3
    reference sweet spot)

Outputs land in /tmp/cv_candidates/ as 24 kHz mono WAVs, named by
order of acquisition with a sidecar .txt holding the verbatim
sentence. Print a summary line per saved clip so we can pick by
content + demographic.

CC0 — Common Voice is public-domain dedication, fine for game-jam
use without further attribution requirements.
"""
from __future__ import annotations

import sys
from pathlib import Path

import librosa
import soundfile as sf
from datasets import load_dataset

OUT = Path("/tmp/cv_candidates")
OUT.mkdir(exist_ok=True, parents=True)

# Targets — Daniel's casting brief
TARGET_GENDER = "male_masculine"
TARGET_AGES = {"thirties", "forties"}
US_ACCENT_HINTS = {"united states", "american english", "us english"}
MIN_SENT_LEN = 30      # ≈ 4-5s at conversational pace
MAX_SENT_LEN = 120     # ≈ 10-11s
KEEP_COUNT = 20
MAX_SCAN = 5000        # cap iterations so a barren run still terminates


def matches(sample: dict) -> bool:
    if sample.get("gender") != TARGET_GENDER:
        return False
    if sample.get("age") not in TARGET_AGES:
        return False
    accent = (sample.get("accent") or "").lower()
    if not any(hint in accent for hint in US_ACCENT_HINTS):
        return False
    sentence = sample.get("sentence", "")
    if not (MIN_SENT_LEN <= len(sentence) <= MAX_SENT_LEN):
        return False
    return True


def save_clip(sample: dict, idx: int) -> Path:
    audio = sample["audio"]
    array = audio["array"]
    sr = audio["sampling_rate"]
    if sr != 24000:
        array = librosa.resample(array, orig_sr=sr, target_sr=24000)
    wav_path = OUT / f"cv_{idx:02d}.wav"
    sf.write(wav_path, array, 24000, subtype="PCM_16")
    (OUT / f"cv_{idx:02d}.txt").write_text(sample["sentence"] + "\n")
    return wav_path


def main() -> int:
    print(f"Streaming Common Voice 17.0 (English), targeting "
          f"{TARGET_GENDER}, age {sorted(TARGET_AGES)}, US accents...\n")
    ds = load_dataset(
        "mozilla-foundation/common_voice_17_0",
        "en",
        split="train",
        streaming=True,
    )
    saved = 0
    seen = 0
    for sample in ds:
        seen += 1
        if seen > MAX_SCAN:
            break
        if not matches(sample):
            continue
        wav_path = save_clip(sample, saved)
        client = (sample.get("client_id") or "?")[:8]
        accent = sample.get("accent") or "?"
        print(f"  [{saved:02d}] {client}  age={sample['age']:10s}  "
              f"accent={accent[:30]:30s}  -> {wav_path.name}")
        print(f"        sentence: {sample['sentence']}")
        saved += 1
        if saved >= KEEP_COUNT:
            break
    print(f"\nSaved {saved} candidate(s) after scanning {seen} samples in /tmp/cv_candidates/")
    return 0 if saved > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
