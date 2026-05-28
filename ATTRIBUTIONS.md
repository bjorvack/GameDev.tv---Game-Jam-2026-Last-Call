# Attributions

Per jam rules: every asset I didn't make myself is listed here.

## Art

All art in `art/` was generated locally by me using **mflux 0.17.5** running
**`black-forest-labs/FLUX.2-klein-9B`** (FLUX Non-Commercial Licence). The
project initially shipped a few images from FLUX.1-schnell but those were
re-generated on the FLUX.2 klein pipeline mid-jam for better prompt adherence;
the current files in `art/` are all from FLUX.2 klein. Prompts, seeds, and
generation parameters are logged per-image in the sidecar `*.metadata.json`
files next to each PNG, and summarised in [`docs/AI_PROMPTS.md`](docs/AI_PROMPTS.md).

After generation, every cutout asset (portraits + props in `art/props/`,
plus `art/title.png`) was post-processed through [`tools/cutout.py`](tools/cutout.py),
which wraps [rembg](https://github.com/danielgatis/rembg) (`isnet-general-use`
model, MIT licence) to turn the flat-background renders into clean RGBA cutouts.

| File | Source | License | Notes |
|------|--------|---------|-------|
| `art/title.png`, `art/title_logo.png` | mflux + FLUX.2 klein 9B | FLUX Non-Commercial (model) / self-authored prompt | Title screen; `title.png` is RGBA via rembg |
| `art/backgrounds/switchboard.png` | mflux + FLUX.2 klein 9B | FLUX Non-Commercial (model) / self-authored prompt | Seed 101, see metadata |
| `art/backgrounds/room.png` | mflux + FLUX.2 klein 9B | FLUX Non-Commercial (model) / self-authored prompt | |
| `art/backgrounds/title.png` | mflux + FLUX.2 klein 9B | FLUX Non-Commercial (model) / self-authored prompt | |
| `art/backgrounds/ending_good.png` | mflux + FLUX.2 klein 9B | FLUX Non-Commercial (model) / self-authored prompt | |
| `art/backgrounds/ending_bad.png` | mflux + FLUX.2 klein 9B | FLUX Non-Commercial (model) / self-authored prompt | |
| `art/portraits/*.png` (cole, daniel, doc, henley, margaret_empty_chair, nurse, patty, reverend, sheriff, trucker, unknown) | mflux + FLUX.2 klein 9B + rembg | FLUX Non-Commercial (model) / MIT (rembg) / self-authored prompt | Character portraits, all RGBA cutouts |
| `art/props/cable_and_shelf.png`, `operator_desk.png`, `switchboard_panel.png`, `switchboard_panel_small.png`, `socket_lit.png` | mflux + FLUX.2 klein 9B + rembg | FLUX Non-Commercial (model) / MIT (rembg) / self-authored prompt | Switchboard props, RGBA cutouts |

## Audio — SFX

| File | Source | License | Notes |
|------|--------|---------|-------|
| `audio/sfx/275053__cvp1965__old-phone-ringing (1).wav` | https://freesound.org/people/cvp1965/sounds/275053/ | CC0 | Old phone ringing — used for both the incoming-call loop and the ringback one-shot |
| `audio/sfx/477641__joao_janz__power-cord-unplug-1_2.wav` | https://freesound.org/people/joao_janz/sounds/477641/ | CC0 | Cable plug |
| `audio/sfx/531060__haleyreesecalhoun__sneaky-phone-put-down-hrc.wav` | https://freesound.org/people/haleyreesecalhoun/sounds/531060/ | CC0 | Phone hang-up |
| `audio/sfx/717365__1bob__click.wav` | https://freesound.org/people/1Bob/sounds/717365/ | CC0 | Menu button click — pitched in code for back / toggle variants |

## Audio — Voice references

Each character's `audio/voice_refs/<slug>/default.wav` is a short CC0 / CC-licensed clip used as the speaker-cloning reference for Qwen3-TTS-MLX-Instruct (Apache-2.0 — see Tools). Per-line emotion is added at generation time via the model's `--instruct` directive, so each character only needs a single neutral reference. The generated dialogue lines live in `audio/dialogue/<slug>/`.

| File | Source | License | Notes |
|------|--------|---------|-------|
| `audio/voice_refs/cole/default.wav` | https://freesound.org/people/balloonhead/sounds/382281/ (`shortfilm-voice`, first 8s) | CC0 | Cole — gruff blue-collar mechanic |
| `audio/voice_refs/daniel/default.wav` | Pixabay (`faespencer / I can't believe it`) | Pixabay Content License (royalty-free, commercial-friendly) | Daniel — anxious salesman |
| `audio/voice_refs/doc/default.wav` | Pixabay (`originalvo / medieval gamer voice — darkness hunts us`) | Pixabay Content License | Doc Wheeler — weary doctor |
| `audio/voice_refs/henley/default.wav` | https://freesound.org/.../female-blurb-105836 | CC0 | Mrs. Henley — anxious older neighbour |
| `audio/voice_refs/mrs_bray/default.wav` | https://freesound.org/.../female-bartender-58632 (4s window) | CC0 | Mrs. Bray (and reused as the `unknown` ??? wrong-number speaker) |
| `audio/voice_refs/nurse/default.wav` | Pixabay (`faespencer / Thanks I really appreciate it`) | Pixabay Content License | Nurse — calm professional warmth |
| `audio/voice_refs/operator/default.wav` | https://freesound.org/.../experimental-64402 (first 8s) | CC0 | Operator — hushed reflective inner monologue |
| `audio/voice_refs/patty/default.wav` | Pixabay (`faespencer / alone time spoken`) | Pixabay Content License | Patty — warm diner owner |
| `audio/voice_refs/reverend/default.wav` | Pixabay (`originalvo / British hybrid voice — let's stay connected`) | Pixabay Content License | Reverend Carter — pastoral calm |
| `audio/voice_refs/sheriff/default.wav` | https://freesound.org/people/tekgnosis/sounds/320854/ (first 7s) | CC0 | Sheriff Briggs — gruff authoritative cop |
| `audio/voice_refs/trucker/default.wav` | https://freesound.org/.../hey-check-your-blood-sugar-44993 | CC0 | Trucker — rough road-weary plain-spoken |

Each `.wav` ships alongside a `.txt` sidecar with the reference clip's transcribed line, fed to Qwen3-TTS-MLX as `--ref_text`.

## Audio — Music

| File | Source | License | Notes |
|------|--------|---------|-------|
| `audio/music/197795__yuval__soundtrack-noise-1940s.wav` | https://freesound.org/people/Yuval/sounds/197795/ | CC0 | 1940s soundtrack noise bed |
| `audio/music/693423__gis_sweden__waiting-for-mellow-cinematic-loop.wav` | https://freesound.org/people/gis_sweden/sounds/693423/ | CC0 | Mellow cinematic loop |
| `audio/music/839571__cvltiv8r__contemplative-string-loop-violin-and-cello.wav` | https://freesound.org/people/cvltiv8r/sounds/839571/ | CC0 | Contemplative strings loop |

## Fonts

None — uses Godot's built-in default font; no external font files in the project.

## Shaders

All shaders in `shaders/` were written by me from scratch for this jam.

| File | Source | License |
|------|--------|---------|
| `shaders/jack.gdshader` | Self-authored | Same as project |
| `shaders/patience_light.gdshader` | Self-authored | Same as project |
| `shaders/socket.gdshader` | Self-authored | Same as project |

## Tools used (disclosure)

- **Godot 4.6** — engine
- **mflux 0.17.5** running **FLUX.2 klein 9B** (FLUX Non-Commercial Licence) — local image generation for all art assets, on Apple Silicon via MLX. Per-image prompts/seeds in `*.metadata.json` and `docs/AI_PROMPTS.md`.
- **rembg** (`isnet-general-use`, MIT) — background removal for RGBA cutouts of portraits and props. Driven by [`tools/cutout.py`](tools/cutout.py) (PEP 723 inline script, runs via `uv`).
- **Qwen3-TTS-MLX-Instruct** (Alibaba Qwen team, Apache-2.0) via `mlx-audio` — local speaker-cloning TTS for every voiced dialogue line. Each character has a short CC0/CC-licensed reference clip (above); per-line emotion is steered with the model's `--instruct` natural-language directive. Generation pipeline lives in [`tools/_gen_all_lines_qwen.py`](tools/_gen_all_lines_qwen.py).
- **OpenAI Whisper** (`base` model, MIT) — used by [`tools/_verify_generated_lines.py`](tools/_verify_generated_lines.py) as a sanity check that the TTS output matches the intended line text.
- **FFmpeg** (LGPL/GPL) — `loudnorm` filter, EBU R128, all generated dialogue clips normalised to -16 LUFS for consistent in-game levels.
