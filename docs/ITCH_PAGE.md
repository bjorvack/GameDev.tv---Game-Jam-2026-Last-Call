# Itch.io page setup

Copy-paste reference for the [itch.io project page](https://bjorvack.itch.io/) for **Last Call**. Sections map 1:1 to itch's edit form.

---

## Basic info

| Field | Value |
|---|---|
| **Title** | `Last Call` |
| **Project URL** | `last-call` (or whatever you prefer) |
| **Short description / tagline** | `A 1960 switchboard operator. Ten calls. One night that will not be like the others.` |
| **Classification** | Games |
| **Kind of project** | HTML |
| **Release status** | Released |
| **Pricing** | `$0` / Free (jam entry) |

---

## Detailed description (markdown)

```markdown
> *"Three rings. Four. Margaret didn't pick up. There has never been a market open at this hour."*

Mayfield Bend, North Carolina. Friday, **11 November 1960**, deep into the night. The town's manual switchboard. One operator. One paired patch cord. **Ten calls** that, between them, decide whether a son makes it home in time.

## How it plays

- A line lights up. **Click the glowing socket** to answer.
- The caller asks the operator (you) for a name.
- **Click the line they need** to patch them through.
- The party on the other end picks up. They speak.
- Cable releases. Next call.

You don't choose what the callers say. You choose where the wires go. Wrong sockets cost you patience. Time-pressured calls can be missed. One call, deep in the night, will end the shift one way or the other.

## ~ 15 minutes. One sitting. No saves.

The shift is short. It is also the only thing on the board tonight.

## Made for the GameDev.tv Game Jam 2026

Built in five days in [Godot 4.6](https://godotengine.org). Art generated locally on Apple Silicon with mflux + FLUX.2 klein 9B, post-processed through rembg for clean RGBA cutouts. The palette is locked to an Olly Moss / Eyvind Earle noir-poster scheme: deep teal night, warm wood, amber lamps, mint indicator lights, aged red telephone cable.

## Controls

- **Click** a socket to plug or unplug
- **Any key / click** advances title and ending screens

## Credits

- Design, code, story — Bjorn Vanacker
- Pair programming assist — [Cognition Devin](https://devin.ai)
- Engine — Godot 4.6 (GL Compatibility on web)
- Music — *[fill in CC-BY track + author]*
- SFX — *[fill in CC0 sources]*
- Image generation — FLUX.2 klein 9B (non-commercial) via [mflux](https://github.com/filipstrand/mflux)
- Background removal — [rembg](https://github.com/danielgatis/rembg) (isnet-general-use)

See [`ATTRIBUTIONS.md`](https://github.com/bjorvack/GameDev.tv---Game-Jam-2026-Last-Call/blob/main/ATTRIBUTIONS.md) for full third-party credits.
```

> Edit the music + SFX credits once those tracks are picked.

---

## Tags

Pick 5-10. Suggested:

```
narrative
point-and-click
short
historical
noir
period
atmospheric
story-rich
drama
single-player
```

## Genre

`Adventure` (with secondary `Visual Novel` if itch allows two).

## Average session

`15 minutes` (or `A few minutes` if you'd rather under-promise).

## Languages

`English`.

## Inputs

`Mouse`, `Keyboard` (for skipping title / endings).

## Accessibility

- Subtitles ✅ (all dialogue is subtitled, no audio-only content)
- Configurable difficulty ❌
- Color-blind friendly — *probably yes*; the gameplay-critical cue is "the brightest pulsing lamp", which uses both luminance change AND amber colour. Worth flagging as "may be hard for severe blue/yellow color-blindness".

---

## Page theme — manual customisation values

Itch's "Edit theme" picker, set to **Custom**. The palette mirrors the in-game style guide (`docs/STYLE_GUIDE.md`):

| Field | Hex | Note |
|---|---|---|
| Background colour | `#0F2A33` | deep teal night |
| Background image | *(none — let the solid teal carry it)* |
| Sidebar / panel background | `#173E4A` | mid teal |
| Border colour | `#5A3A22` | warm wood |
| Text colour | `#F1E4C8` | bone paper |
| Heading colour | `#E8B86A` | amber lamp |
| Link colour | `#E8B86A` | amber lamp |
| Link hover | `#F1E4C8` | bone paper |
| Button background | `#5A3A22` | warm wood |
| Button text | `#F1E4C8` | bone paper |

Font: stay with itch's default (`Lato`) — it reads well on dark teal. Avoid serif body fonts, they fight the painterly logo.

---

## Embed options (Project files / Edit game)

After uploading `build/last_call_web.zip` and ticking "This file will be played in the browser":

| Setting | Value |
|---|---|
| Viewport / frame dimensions | `1152 × 648` |
| Fullscreen button | ✅ on |
| Mobile friendly | ❌ off (untested touch) |
| SharedArrayBuffer support | ❌ off (we built `thread_support = false`, so the COOP/COEP headers aren't needed; leaving this off keeps itch comments + ratings working) |
| Click to launch in fullscreen | ✅ on — doubles as the user gesture browsers need to allow audio autoplay |
| Automatically start on page load | ❌ off |
| Orientation | `Landscape` (locked) |

---

## Cover art / banner — what we need

| Asset | Pixel size | Source |
|---|---|---|
| Cover image (game card thumbnail) | **630 × 500** | crop of `art/backgrounds/title.png` + `art/title.png` overlay, or a tight crop of the panel + caller silhouette |
| Optional banner (top of page) | **1920 × 620** | wider crop of the title scene |
| Screenshots (3-5) | any size, ≥ 700px wide | see below |

### Screenshot shot list

Captures to grab from a live playthrough (1152×648 native is fine, itch will resize):

1. **Title screen** — already have it at `build/screenshots/01_title.png`. Use as the second screenshot for the gallery; doubles as a candidate cover crop.
2. **Switchboard idle** — wide shot of all 20 sockets, room context visible. Captures the "operator's room" feel.
3. **Ringing socket + caller speaking** — caller card top-left with silhouette + amber halo + dialogue line, ringing socket pulsing amber on the panel. Captures both the gameplay loop and the visual style. *Best single-image hook for the project card.*
4. **Connected call** — cable bridging two sockets, recipient mid-line, caller card showing the recipient's silhouette. Reads as "the patch worked".
5. **Wrong number** — wrong-socket plug, "wrong number" exchange playing. Shows the failure state without spoiling story beats.

To capture interactively:

```bash
cd build/web && python3 -m http.server 8765
# Open http://localhost:8765 in Chrome / Safari
# macOS: ⌘⇧4 then Space to capture the iframe rectangle
# Save into build/screenshots/
```

The game also writes `debug_screenshot.png` to `~/Library/Application Support/Godot/app_userdata/Last Call/` each time the project stops in the editor — handy for grabbing exact moments by stopping mid-call.

---

## Pre-publish checklist

- [ ] Music + SFX credits filled in above
- [ ] 3-5 screenshots in `build/screenshots/` and uploaded
- [ ] Cover image (630×500) made and uploaded
- [ ] `last_call_web.zip` uploaded, marked "played in browser", embed dims 1152×648, fullscreen on
- [ ] Theme picker set to the palette above
- [ ] Tags + genre + classification set
- [ ] Public visibility — only flip to "Public" once the GameDev.tv jam page accepts the link
