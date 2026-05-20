# 5-day jam schedule

Deadline: **May 25, 21:00 PST** (≈ May 26, 06:00 CEST).

## Day 1 — May 20 (today, half day) — Foundation
- [x] Project scaffold, story script, stub scripts
- [ ] Create `scenes/switchboard.tscn`:
  - `Node2D` root → attach `call_director.gd`
  - `Sprite2D` background (placeholder ColorRect for now)
  - `Node2D "Sockets"` with 8 children (Area2D + sprite + label), each:
    - script: `socket.gd`
    - group: `sockets`
    - keys: `hayes`, `doc`, `sheriff`, `reverend`, `patty`, `cole`, `i40`, `hospital`
  - `Line2D "Cable"` with `cable.gd`
  - `Label "CallerRequest"` + `Label "PostConnect"`
  - `HBoxContainer "Patience"` with 3 lights
- [ ] Wire `Socket.cable_plugged` → `CallDirector.submit_connection`
- [ ] Register `game_state.gd` as autoload "GameState"
- [ ] Build 2 placeholder CallData `.tres` files in `data/calls/`
- [ ] End-of-day: end-to-end playable with placeholder art

## Day 2 — May 21 — Content
- [ ] Author all 10 `.tres` CallData resources from `STORY.md`
- [ ] Add "next call" advance after post-connect lines finish
- [ ] Add `title.tscn` and `ending.tscn` (good/bad)
- [ ] Patience UI feedback (light goes out + buzz sfx)
- [ ] Pivotal-call handling (call 9)

## Day 3 — May 22 — Art
- [ ] Lock 1 AI prompt template, generate ~12 portraits with same seed
- [ ] Generate / source switchboard panel image
- [ ] Generate operator-room background for title + ending
- [ ] Log every prompt in `docs/AI_PROMPTS.md`
- [ ] Update `ATTRIBUTIONS.md`

## Day 4 — May 23 — Audio + polish
- [ ] SFX: dial tone, ring, plug-click, wrong-number buzz, static, room ambience, ticking clock
- [ ] 1 looping CC-BY music track
- [ ] CRT shader on a CanvasLayer
- [ ] Fade transitions between calls
- [ ] Title screen + 2 ending screens text

## Day 5 — May 24/25 — Export + submit
- [ ] HTML5 export — fix audio autoplay (may need a "click to start" splash)
- [ ] Test in Chrome + Firefox
- [ ] Itch page: description, 3 screenshots, attributions copy
- [ ] Submit by 19:00 PST (2h buffer)
