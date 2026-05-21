# UI/Layout analysis — `scenes/switchboard.tscn`

State as of the post–cable-bay screenshot. Resolution 1152×648. Style anchor:
1960s switchboard, painterly noir storybook (`docs/STYLE_GUIDE.md`).

## What the player currently sees

Top-to-bottom, the screen reads as five disconnected zones:

1. **Caller card** (top-left, ~256×256 portrait + black panel to the right
   for name + dialogue).
2. **Patience lights** (top-right, three tiny mint dots, ~24px each).
3. **Sockets grid** (centered middle, 4×2, brass rings on a flat teal field,
   with text labels under each).
4. **Cable bay** (bottom-center, new — brass-trimmed wooden shelf, phone
   jack, "Drag the cable to a socket" hint).
5. **Call timer** (declared in `HUD/BottomBar` but invisible / overlapping
   the cable bay area; we only ever see it during timed calls).

There is no visual scaffolding tying these zones together — no switchboard
panel, no desk surface, no operator-room framing. Everything floats on a
flat #135160-ish teal field.

## Strengths

- **Shader-driven sockets, jack and patience lights** now match the palette
  perfectly and need no external art.
- **Caller portrait + dialogue** in the top strip is the right anchor for
  attention — every Tier 1/2 portrait reads instantly there.
- **The 4×2 socket grid** is a clean, learnable layout. Two rows is the
  right shape for a switchboard.
- **Sockets dim convincingly when unlit** (Highway 40, County General in the
  screenshot) — instantly communicates "not available this call".

## Issues

Ranked by impact on the jam build.

### 1. The room has no walls. Style-wise, this is the biggest gap.

Right now the BG is a flat ColorRect. The whole conceit is "you are an
operator at a switchboard panel in 1960," but the screen looks like a Godot
prototype with one good portrait pasted in. Every other 1960-era visual the
player infers — wood, brass, a desk, a panel — is *absent*.

This makes the patience lights, cable bay, and sockets read as floating
HUD widgets instead of *parts of a physical machine*.

### 2. The caller card panel is unstyled (no frame, no period feel)

It's a default `PanelContainer` with default Godot theme — black with a
faint border. The portrait sits flush against the edges and the dialogue
uses Godot's default Noto Sans. Nothing about it says "1960 ledger note,
hand-written operator card, brass-framed photo on the wall."

Players will subconsciously read "modern UI" before they read "1960
operator."

### 3. Patience lights are tiny and unlabelled

They're easy to miss in the top-right corner. A new player will not realise
they're a life counter until they lose one. They need a **label**, a
**brass plate underneath**, or both — and they should be bigger.

### 4. The call timer is invisible / colliding with the cable bay

`CallTimer` is declared in `HUD/BottomBar` which anchors to the bottom of
the viewport — exactly where the cable bay now lives. Timed calls
(`time_limit > 0`) will fight for that space.

It should also probably **not** look like a generic Godot ProgressBar; that
break the period feel harder than anything else does.

### 5. Cable's resting state still doesn't suggest "draggable"

We added the bay and a hint label, which is a huge improvement, but at rest
the cable itself is invisible (it's a Line2D that goes from `jack_position`
to `jack_position`). Players don't see "a thing on a wire I can pick up";
they see a small plug on a shelf with a text hint.

A subtle idle visual would sell the metaphor:
- Cable visibly coiling/drooping from the jack to a fixed anchor point off-screen left or right.
- A gentle pulse / amber halo around the jack when the game is in
  `AWAITING` phase ("the operator is waiting for you to act").

### 6. No hover feedback on sockets while dragging

When the cable is being dragged over a lit socket, nothing in that socket
changes. There's no "snap target" cue, so you only learn whether you
clicked the right thing *after* you release.

This is a one-shader-uniform fix: a `hovering` bool that boosts the amber
glow radius and brightness while the cable is over the socket.

### 7. Typography is generic Godot Noto Sans throughout

Caller name, dialogue, socket labels, and the new hint label all share one
font and one size. For a hand-illustrated 1960 game, this is the single
loudest "made in Godot" tell.

A free serif + a free typewriter font (both CC/OFL) would lift the entire
aesthetic in 20 minutes.

### 8. The dialogue area is cramped

The portrait is 256×256 in the upper-left, and the dialogue label sits in a
VBox to its right. The opening line is one short sentence ("Mornin',
operator. Patty here.") which leaves a lot of empty panel space, but later
lines that wrap to 2–3 lines will feel claustrophobic because the
PanelContainer has no padding/margin around the text.

### 9. The post-connect box and caller card flicker between calls

`CallerCard` is hidden between lines (per the schedule's spec changes), and
`PostConnectBox` is hidden by default. Between calls everything goes quiet.
That's intentional for pacing, but combined with the fact that the rest of
the scene is flat teal, the inter-call beat reads as "did the game freeze?"
rather than "the operator is between calls."

A persistent low-key visual (the switchboard panel itself, an unattended
phone, a ticking wall clock) would carry that quiet beat.

### 10. Reading order is L-shaped, not top-down

You read the caller card top-left, then need to look down-and-right to find
the socket. Then you need to look back to the bottom-center to find the
cable. That's three eye movements per call.

Better: caller info on top, sockets below it, cable directly below sockets
(short eye path: caller → who does this belong to → grab cable → plug).
Roughly what we have, but pulling the caller card to span the full width
and shrinking it vertically would tighten the loop.

## Suggested improvements, prioritised

For each I'm noting **effort** (S/M/L) and **impact** (S/M/L). With ~3 days
to ship I'd do the L-impact / S–M-effort items only.

### Tier A — ship-blocking polish (do these)

1. **Add a switchboard panel background.** *(M / L)*
   - Use the existing `art/backgrounds/switchboard.png` (or regenerate one
     with the AI pipeline) as a `Sprite2D` or `TextureRect` filling the
     viewport.
   - Re-anchor the sockets grid so it sits *inside* the rendered panel area
     of that image (you may want to add a `Control` margin frame).
   - Replace the flat-teal BG `ColorRect`.

2. **Frame the caller card.** *(S / L)*
   - Drop a `StyleBoxFlat` (or a `StyleBoxTexture` using a brass-corner
     image) onto its `PanelContainer`.
   - Background: deep teal #0F2A33, border: brass #B47333 2–4px, content
     padding ~12px.
   - Caller name in bone-white #F1E4C8 serif, 20–24px; dialogue in a
     smaller typewriter face, 14–16px.

3. **Label and enlarge the patience lights.** *(S / L)*
   - Bump custom_minimum_size to ~32px.
   - Add a small "PATIENCE" label above (bone-white, small caps, brass
     hairline underneath).
   - Optionally wrap them in a brass-trimmed panel like the cable bay.

4. **Pick two free period fonts and theme the project.** *(S / L)*
   - Heading face: a slightly weathered serif. "IM Fell English" or "Special
     Elite" (both OFL/CC).
   - Body face: typewriter — "Courier Prime" works perfectly.
   - Drop both into `theme.tres`, set everywhere via the default theme.
   - This *single change* is the largest visible style upgrade you can
     make.

5. **Hover state on sockets while dragging.** *(S / M)*
   - Add a `uniform bool is_hovering` to `socket.gdshader`.
   - In `cable.gd`, while `_dragging`, raycast/walk the sockets group and
     set `is_hovering` on the one whose rect contains the cursor. Clear
     when leaving.
   - In the shader, boost `glow_radius` and amber alpha when `is_hovering`
     is true.

6. **Move the call timer to the top edge, next to the patience lights.**
   *(S / M)*
   - It conflicts with the cable bay at the bottom.
   - Conceptually a timer + patience belong together as "session state."

### Tier B — strong polish (do if time permits)

7. **Restyle the call timer as a period-correct gauge.** *(M / M)*
   - Either a custom `Control` that draws a small clock-face dial with
     `_draw`, or a sliced `TextureProgressBar` with a brass frame.
   - Avoid the default ProgressBar look.

8. **Idle cable visual.** *(S / S)*
   - Make the Line2D show a slack curl at rest by adding 2–3 fixed points
     between the jack position and an off-screen anchor.
   - Or — simpler — animate the jack's `position.y` with a subtle 2–3px
     vertical sine bob via an `AnimationPlayer` or a tween.

9. **Inter-call ambient visual.** *(M / M)*
   - During `IDLE` phase, dim the switchboard slightly and show a small
     "ticking" element — a clock hand jump, or a faint light pulse on one
     socket — so the screen isn't dead between calls.

10. **Pad and align the dialogue.** *(S / S)*
    - 12–16px padding inside the caller card.
    - Cap dialogue width at ~50ch via `custom_minimum_size`.

### Tier C — stretch (probably not for the jam)

11. **Animated cable while dragging.** *(M / S)*
    - Add a midpoint that lags slightly behind the mouse for a whippy
      cable feel.

12. **Brass animated ring lamp for incoming calls.** *(M / S)*
    - Match the storybook spec's Tier 3 idea — a glowing lamp at the top
      of the switchboard that pulses during `RING_DURATION`.

13. **CRT shader on a CanvasLayer.** *(S / S)*
    - Currently on the schedule as Day 4 work. Subtle scanlines + slight
      barrel distortion would help unify the whole frame.

## Concrete first patch I'd ship

If I had 30 minutes:

- [x] Cable bay + hint label *(done)*
- [ ] Switchboard background image as the BG
- [ ] Theme.tres with a typewriter font set as the default
- [ ] Caller card `StyleBoxFlat` (teal panel, brass border, padding)
- [ ] "PATIENCE" label above the lights, bump size to 32px

That gets the screen from "Godot prototype with one good portrait" to
"hand-illustrated 1960 operator scene" with no new art beyond the existing
`switchboard.png`.
