# Voice reference clips

Reference audio for the F5-TTS-MLX voice-cloning pipeline. One short
clip per (character, mood) pair, used by `tools/generate_voices.py`
to clone the speaker's voice over the text of each `DialogueLine`.

## Layout

```
audio/voice_refs/
├── <character_slug>/
│   ├── default.wav    # mono 24 kHz, 5–10 s
│   ├── default.txt    # verbatim transcript of default.wav
│   ├── urgent.wav     # optional mood variants — same speaker,
│   ├── urgent.txt     # different prosody / energy
│   ├── relieved.wav
│   └── relieved.txt
└── ...
```

`<character_slug>` is the lowercase, underscored form of the
`Character.name` field in `data/characters/<slug>.tres`. The pipeline
also reads the per-character mood mapping from the `Character.voices`
array on the resource, so adding a new mood means:

1. Drop `<slug>/<mood>.wav` + `<mood>.txt` in this directory.
2. Append a new `VoiceReference` sub-resource to
   `data/characters/<slug>.tres` with `mood = "<mood>"` and
   `audio = ExtResource(...)` pointing at the WAV.
3. Annotate the relevant `DialogueLine` resources with
   `mood = "<mood>"`.

The pipeline falls back to `default.wav` whenever a mood-specific
clip isn't authored, so adding moods is always additive — no
existing call data breaks if you don't backfill every variant.

## Clip requirements

F5-TTS-MLX expects the reference to be:

- **mono**
- **24 kHz sample rate**
- **16-bit signed PCM WAV**
- **5–10 seconds long** (shorter loses prosody fidelity, longer wastes
  attention budget)
- **clean** — no background music, no overlapping voices, minimal
  room reverb

Convert any source clip with ffmpeg:

```bash
ffmpeg -i source.mp3 -ss 00:01:23 -t 8 -ac 1 -ar 24000 -sample_fmt s16 \
    audio/voice_refs/patty/default.wav
```

Then save the transcript exactly as spoken (punctuation matters —
F5-TTS uses it for timing) into the matching `.txt` file.

## Sourcing notes

All clips must be **CC0 / public domain** — see `ATTRIBUTIONS.md` for
how each clip is logged. Good places to find period-appropriate
1960s-American voices:

- **Internet Archive — [Prelinger Archives](https://archive.org/details/prelinger)**
  — thousands of 1940s–60s educational and ephemeral films, most
  explicitly public domain.
- **Internet Archive — [OTRR Certified](https://archive.org/details/OTRR_Certified)**
  — 30s–50s Old Time Radio shows with verified PD status (Gunsmoke,
  Dragnet, Yours Truly Johnny Dollar, etc.).
- **[LibriVox](https://librivox.org/)** — public-domain audiobook
  readings, CC0. Useful for finding consistent narrator voices.
- **[Mozilla Common Voice](https://commonvoice.mozilla.org/)** — CC0
  contemporary samples, filterable by accent + age + gender. Good
  fallback when no period clip fits.

Log every clip's source URL + timecode + license confirmation in the
`notes` field of its `VoiceReference` sub-resource. The .wav files
themselves stay free of metadata so they re-import cleanly.
