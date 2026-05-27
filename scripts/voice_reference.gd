## One reference audio clip used by tools/generate_voices.py to clone a
## character's voice through F5-TTS-MLX. Bundled into Character.voices
## as an array so a single character can have a "default" reference plus
## any number of mood variants (urgent, relieved, hesitant, ...).
##
## The transcript is mandatory for F5-TTS quality cloning: the model
## uses it to align the reference audio's prosody to phonemes. Without
## an accurate transcript the cloned voice drifts in timbre and stress.
class_name VoiceReference
extends Resource

## Mood key — matches DialogueLine.mood. Empty string and "default" are
## treated as equivalent. The pipeline falls back to the speaker's
## default clip when a more specific mood isn't authored.
@export var mood: StringName = &"default"

## Reference audio. Mono 24 kHz WAV is the F5-TTS-MLX native format;
## anything else will be transcoded by the pipeline before passing to
## the model. Keep clips 5-10 seconds long for best cloning results.
@export var audio: AudioStream

## Verbatim transcript of `audio`. Punctuation matters: F5-TTS reads
## it as prosody hints when matching the reference timing.
@export_multiline var transcript: String = ""

## Free-form notes — source URL, timecode, why we picked this clip,
## license confirmation. Kept here so attribution and re-sourcing
## stays trivial if a clip ever needs replacing.
@export_multiline var notes: String = ""
