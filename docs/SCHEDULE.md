# 5-day jam schedule

Deadline: **May 25, 21:00 PST** (≈ May 26, 06:00 CEST).

## Day 1 — May 20 (half day) — Foundation ✅
- [x] Project scaffold, story script, stub scripts
- [x] Create `scenes/switchboard.tscn`:
  - `Node2D` root → attach `call_director.gd`
  - `Sprite2D` background (placeholder ColorRect for now)
  - `Node2D "Sockets"` with 8 children (Area2D + sprite + label), each:
	- script: `socket.gd`
	- group: `sockets`
	- keys: `hayes`, `doc`, `sheriff`, `reverend`, `patty`, `cole`, `i40`, `hospital`
  - `Line2D "Cable"` with `cable.gd`
  - `Label "CallerRequest"` + `Label "PostConnect"` (replaced by `CallerCard` / `PostConnectBox` components)
  - `HBoxContainer "Patience"` with 3 lights (later pinned top-right)
- [x] Wire `Socket.cable_plugged` → `CallDirector.submit_connection`
- [x] Register `game_state.gd` as autoload `GameState`
- [x] Build 2 placeholder CallData `.tres` files in `data/calls/`
- [x] End-of-day: end-to-end playable with placeholder art

## Day 2 — May 21 — Content ✅
- [x] Author all 10 `.tres` CallData resources from `STORY.md`
- [x] Add "next call" advance after post-connect lines finish
- [x] Add `ending.tscn` (good/bad) — `scenes/ending_good.tscn`, `scenes/ending_bad.tscn`
- [ ] Add `title.tscn` — **not built yet** (Day 5 catch-up)
- [x] Patience UI feedback (light goes out + buzz sfx)
- [x] Pivotal-call handling (call 9, `CallData.pivotal`)
- [x] Per-call urgency timer (`CallData.time_limit` + `components/call_timer.tscn`)
- [x] Inter-call pacing: idle beat + ringing indicator before the next call

## Day 3 — May 22 — Art ✅ (pipeline pivoted)
- [x] Generate Tier 1 portraits — **pivoted from DALL·E to local mflux + FLUX.2 klein 9B** (see `tools/generate_sprite.sh`, `tools/batch_tier1.sh`)
- [x] Wire portraits into `CallerCard`
- [x] Per-line portrait override on `DialogueLine.portrait` (lets recipients swap in mid-call)
- [x] Style guide + sprite spec (`docs/STYLE_GUIDE.md`, `docs/SPRITE_SPEC.md`)
- [x] Log every prompt in `docs/AI_PROMPTS.md`
- [x] Update `ATTRIBUTIONS.md`
- [ ] Switchboard panel image — still placeholder ColorRect
- [ ] Operator-room background for title + ending — still placeholder

## Day 4 — May 23 — Audio + polish (partial)
- [x] Audio framework — `AudioManager` autoload (`components/audio_manager.tscn`)
- [x] SFX wired: ring, plug-click, hangup
- [x] 1 looping CC-BY music track
- [ ] Remaining SFX: dial tone, wrong-number buzz, static, room ambience, ticking clock
- [ ] CRT shader on a CanvasLayer
- [ ] Fade transitions between calls
- [ ] Title screen + 2 ending screens text polish

## Day 5 — May 24/25 — Export + submit
- [ ] HTML5 export — fix audio autoplay (may need a "click to start" splash)
- [ ] Test in Chrome + Firefox
- [ ] Itch page: description, 3 screenshots, attributions copy
- [ ] Submit by 19:00 PST (2h buffer)

---/

## Spec changes since planning

These shipped but weren't in the original plan — recording so the doc reflects reality:

- **Call data structure refactor.** Openings now only greet the operator, name the recipient, and add a *mood/vague hint*. The "why" lands in `connected_dialogue`, which starts with a cold pickup from the receiver. Eliminates the bug where receivers magically knew the caller's request before the cable was plugged in. See `scripts/call_data.gd` header doc for the lifecycle.
- **`DialogueLine.portrait` override.** Lets a connected recipient swap the portrait mid-call (e.g. Patty → Cole when Cole picks up).
- **`CallerCard` is hidden between spoken lines** rather than persistently shown, so the screen is quiet during idle beats.
- **Patience lights pinned top-right** (fixed screen position) rather than living in a layout container.
- **`PostConnectBox` component** split out from the original single label.
- **`CallTimer` component** built for `time_limit` countdowns during `AWAITING_ROUTING`.
- **`DebugScreenshot` autoload** added for capturing reference frames.
- **Art pipeline pivot.** Plan was ChatGPT/DALL·E → reality is local generation via `mflux` running FLUX.2 klein 9B. Reference-image-driven Gemini approach was tried then dropped (commit `757737c`).
- **Wrong-routing branches per call.** `CallData.wrong_responses` lets specific mis-routes get bespoke dialogue instead of always falling back to `generic_wrong_response`.
