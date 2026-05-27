#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""
Style Unification — img2img wash through local FLUX2.

For each PNG in INPUT_DIR (top level only, no recursion), runs
mflux-generate-flux2 with that image as the init, a target-style prompt
loaded from STYLE_DIR/style.txt, and a moderate --image-strength so the
composition is preserved while palette, lighting and brushwork are
pulled toward the canonical style. Results land in OUTPUT_DIR with the
same filename.

STYLE_DIR has two roles:

    1. Documentation / mood board for the human author — drop reference
       PNGs in there for eyeballing. The script does NOT consume the
       reference images directly (mflux2 only takes one init image at a
       time, no multi-reference conditioning), but they're the source
       material the human used to craft the style.txt.

    2. Source of truth for the wash prompt: STYLE_DIR/style.txt becomes
       the textual prompt passed to FLUX2. If the file is missing, a
       built-in fallback prompt is used that matches the palette /
       Olly-Moss treatment from tools/generate_sprite.sh.

Optional per-image sidecar prompts: for any <input>.png, if there is a
sibling <input>.subject.txt in INPUT_DIR, its contents are appended to
the style prompt as "Subject: <text>". This is useful when an image
shouldn't drift away from its specific content during the wash.

Usage:
    tools/style_unify.py <input_dir> <style_dir> <output_dir>
        [--strength 0.6] [--seed 1] [--guidance 3.5]
        [--quantize 4] [--force] [--dry-run]

By default this skips inputs whose output already exists in OUTPUT_DIR
so the script is safely re-runnable on partial batches; pass --force to
overwrite.
"""
from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

# Mflux2 image-strength semantics: 0.0 = ignore init (pure text-to-image),
# 1.0 = adhere strictly to init (== copy). 0.6 keeps the input's
# composition and overall shapes intact while allowing meaningful palette
# / brushwork shift toward the prompt — the "wash" sweet spot for this
# project after empirical testing on the existing prop renders.
DEFAULT_STRENGTH = 0.6

# Fallback style prompt — mirrors STYLE_TAIL from tools/generate_sprite.sh
# so a fresh STYLE_DIR without a style.txt still produces results in the
# canonical project palette. Authors should commit a style.txt in their
# STYLE_DIR for finer control.
FALLBACK_STYLE_PROMPT = (
    "Hand-illustrated graphic poster in the style of Olly Moss alternate-"
    "movie-poster art and Eyvind Earle — bold, cinematic, moody. Flat "
    "fields of colour, screen-print grain, no photorealism, no 3D "
    "rendering, no cute cartoon style, no childish illustration, no "
    "children's book look. Strict palette: deep teal night #0F2A33 "
    "background, mid teal shadow #173E4A, warm wood brown #5A3A22, "
    "amber lamp light #E8B86A, bone-paper #F1E4C8 only for any text, "
    "aged red #C14B4B reserved for telephone cables only, mint #7AAE9A "
    "for tiny indicator lamps only. Exactly one warm amber light source "
    "from the upper right."
)


def load_style_prompt(style_dir: Path) -> str:
    style_file = style_dir / "style.txt"
    if style_file.is_file():
        text = style_file.read_text().strip()
        if text:
            return text
    print(
        f"[style_unify] no {style_file.relative_to(Path.cwd())} found — "
        f"falling back to built-in palette/Olly-Moss prompt",
        file=sys.stderr,
    )
    return FALLBACK_STYLE_PROMPT


def load_subject_hint(input_png: Path) -> str | None:
    sidecar = input_png.with_suffix(".subject.txt")
    if sidecar.is_file():
        text = sidecar.read_text().strip()
        if text:
            return text
    return None


def wash_one(
    *,
    input_png: Path,
    output_png: Path,
    style_prompt: str,
    strength: float,
    seed: int,
    guidance: float,
    quantize: int,
    dry_run: bool,
) -> None:
    subject = load_subject_hint(input_png)
    prompt = style_prompt
    if subject:
        prompt = f"{prompt} Subject: {subject}"
    cmd = [
        "mflux-generate-flux2",
        "--model", "flux2-klein-9b",
        "--quantize", str(quantize),
        "--image-path", str(input_png),
        "--image-strength", str(strength),
        "--guidance", str(guidance),
        "--prompt", prompt,
        "--seed", str(seed),
        "--metadata",
        "--output", str(output_png),
    ]
    if dry_run:
        print(f"[dry-run] {' '.join(cmd)}")
        return
    print(f"[style_unify] {input_png.name}  ->  {output_png.relative_to(Path.cwd())}")
    output_png.parent.mkdir(parents=True, exist_ok=True)
    # Clear any stale metadata so mflux's overwrite-protection doesn't kick
    # in and silently rename our output to <stem>_1.png.
    output_png.unlink(missing_ok=True)
    metadata_file = output_png.with_suffix(".json")
    metadata_file.unlink(missing_ok=True)
    subprocess.run(cmd, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Wash a directory of images through local FLUX2 img2img.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("input_dir", type=Path)
    parser.add_argument("style_dir", type=Path)
    parser.add_argument("output_dir", type=Path)
    parser.add_argument(
        "--strength", type=float, default=DEFAULT_STRENGTH,
        help=f"mflux --image-strength (0.0 ignores init, 1.0 copies it). Default {DEFAULT_STRENGTH}.",
    )
    parser.add_argument(
        "--seed", type=int, default=1,
        help="Fixed seed for reproducible washes. Default 1.",
    )
    parser.add_argument(
        "--guidance", type=float, default=3.5,
        help="mflux --guidance scale. Default 3.5.",
    )
    parser.add_argument(
        "--quantize", type=int, default=4, choices=[3, 4, 5, 6, 8],
        help="mflux --quantize (model precision). Default 4.",
    )
    parser.add_argument(
        "--force", action="store_true",
        help="Re-wash even when the output file already exists.",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Print the planned mflux command for each input and exit.",
    )
    args = parser.parse_args()

    if not args.input_dir.is_dir():
        parser.error(f"input_dir is not a directory: {args.input_dir}")
    if not args.style_dir.is_dir():
        parser.error(f"style_dir is not a directory: {args.style_dir}")
    if not args.dry_run and shutil.which("mflux-generate-flux2") is None:
        parser.error(
            "mflux-generate-flux2 not on PATH — install mflux first "
            "(see tools/generate_sprite.sh for setup notes)."
        )

    style_prompt = load_style_prompt(args.style_dir)

    inputs = sorted(p for p in args.input_dir.iterdir() if p.suffix.lower() == ".png")
    if not inputs:
        print(f"[style_unify] no PNGs found in {args.input_dir}", file=sys.stderr)
        return 1

    total = len(inputs)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    for i, input_png in enumerate(inputs, start=1):
        output_png = args.output_dir / input_png.name
        if output_png.exists() and not args.force and not args.dry_run:
            print(f"[style_unify] skip {input_png.name} (already washed; use --force)")
            continue
        print(f"\n=== [{i}/{total}] {input_png.name} ===")
        try:
            wash_one(
                input_png=input_png,
                output_png=output_png,
                style_prompt=style_prompt,
                strength=args.strength,
                seed=args.seed,
                guidance=args.guidance,
                quantize=args.quantize,
                dry_run=args.dry_run,
            )
        except subprocess.CalledProcessError as e:
            print(f"[style_unify] mflux failed on {input_png.name}: {e}", file=sys.stderr)
            return e.returncode
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
