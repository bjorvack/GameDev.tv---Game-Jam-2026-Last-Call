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
| `audio/sfx/274289__abernstein__rotary-phone-ring-medium.wav` | https://freesound.org/people/abernstein/sounds/274289/ | CC0 (declared by uploader) | Rotary phone ring. Uploader marks this as CC0, but it is a remix of [lwdickens/269380](https://freesound.org/people/lwdickens/sounds/269380/) which is **CC-BY-NC 4.0**. To be safe, credit lwdickens too. |
| `audio/sfx/275053__cvp1965__old-phone-ringing (1).wav` | https://freesound.org/people/cvp1965/sounds/275053/ | CC0 | Old phone ringing |
| `audio/sfx/477641__joao_janz__power-cord-unplug-1_2.wav` | https://freesound.org/people/joao_janz/sounds/477641/ | CC0 | Cable unplug |
| `audio/sfx/531060__haleyreesecalhoun__sneaky-phone-put-down-hrc.wav` (and `.m4a`) | https://freesound.org/people/haleyreesecalhoun/sounds/531060/ | CC0 | Phone hang-up |

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
- **Devin (CLI)** by Cognition — coding assistant used as a pair-programming agent throughout development.
