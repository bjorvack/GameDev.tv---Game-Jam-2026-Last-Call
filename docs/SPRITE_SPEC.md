# Sprite specification — Last Call

Companion to `docs/STYLE_GUIDE.md`. Every asset needed, where it goes, what it should look like, and a ready-to-paste AI prompt.

Universal prefix and negative prompt: see `docs/STYLE_GUIDE.md`. Don't restate them in every prompt below; paste them once as a header in your AI tool and only change the `<CHARACTER>` line.

---

## Asset tiers

Generate in this order. Stop at any tier and the game still looks intentional.

- **Tier 1 (must have):** switchboard background, socket states, cable jack, patience light, Daniel + Patty + Reverend + Doc silhouettes, title art
- **Tier 2 (strong polish):** remaining silhouettes (Mrs. Henley, Sheriff, Cole, Nurse, Unknown), good/bad ending illustrations
- **Tier 3 (stretch):** Margaret's empty-chair scene, animated ring lamp, decorative background frame

---

## File layout

```
art/
├── backgrounds/
│   ├── switchboard.png          # main play area background
│   ├── title.png                # title screen
│   ├── ending_good.png          # hospital window
│   └── ending_bad.png           # dark exchange room
├── portraits/
│   ├── daniel.png
│   ├── patty.png
│   ├── reverend.png
│   ├── doc.png
│   ├── sheriff.png
│   ├── henley.png
│   ├── cole.png
│   ├── nurse.png
│   ├── margaret_empty_chair.png
│   └── unknown.png
└── ui/
    ├── socket_lit.png
    ├── socket_dim.png
    ├── cable_jack.png
    └── patience_light.png       # if you want a sprite instead of a ColorRect
```

All portraits: **512 × 512 PNG**, transparent background.
Backgrounds: **1280 × 720 PNG**.
UI sprites: as noted per item.

---

## Tier 1 — must have

### `art/backgrounds/switchboard.png` — 1280×720
The main play surface. We see the operator's switchboard from her POV, slightly angled. A warm amber pool of lamp-light on the upper half of a dark brass-and-wood panel; the bottom of the frame is the operator's desk in deep teal shadow. The panel has a faint grid where the sockets will be overlaid (we'll position the actual interactive sockets in code on top). Edges of the frame vignette into near-black.

```
A 1985 telephone exchange switchboard panel viewed from the operator's
seat, slightly tilted forward. Aged brass and dark walnut panel, faintly
glowing amber from a single overhead lamp falling from the upper right.
Deep teal-black shadows in the corners. Subtle wood and metal texture.
A faint grid of recessed circular receptacle holes across the upper
half — no plugs, no cables in this image — empty board, waiting.
Lower half is the operator's desk surface in deep teal shadow. Centre
composition. Storybook softness, painterly textures, fine warm film
grain. Iron Giant art direction. No people. No text.
```

### `art/backgrounds/title.png` — 1280×720
The operator's room before her shift starts. We see her desk from across the room: switchboard panel ahead, the back of her empty chair, the amber lamp on, coat hanging on a hook. Warm and lonely.

```
A 1985 telephone exchange operator's room at night, seen from across the
room. An unattended switchboard panel of brass and dark wood glows under
a single amber desk lamp. The operator's wooden chair is empty, pushed
slightly back. A heavy coat hangs on a wall hook. Everything else recedes
into deep teal shadow. Hand-illustrated storybook style, Iron Giant art
direction, painterly, melancholic. Centre composition with strong negative
space. Warm amber light only from the lamp. No text. No people.
```

### `art/backgrounds/ending_good.png` — 1280×720
A hospital room window seen from outside at dawn. Warm yellow light spills through the curtains. The silhouettes of two figures inside — one in a bed, one leaning forward holding their hand. No faces, no detail.

```
A small hospital room window seen from outside at the first amber light
of dawn. Through gauzy curtains, two warm silhouettes: a person in a
hospital bed and a second figure leaning forward holding their hand.
Soft amber glow from inside spills out into the cold blue of pre-dawn.
Hand-illustrated storybook style, Iron Giant art direction, painterly,
hopeful but quiet, melancholic. Strong negative space. Centre composition.
No text.
```

### `art/backgrounds/ending_bad.png` — 1280×720
The same operator's room as the title, but the desk lamp is off. The switchboard panel is dark. Only a thin slice of teal moonlight through a small window. Empty chair, untouched coffee cup gone cold.

```
A 1985 telephone exchange operator's room at the end of a long night. The
desk lamp is off. The switchboard panel sits dark and silent. A single
cold thin shaft of teal moonlight cuts across the operator's empty chair
and an untouched coffee cup gone cold on the desk. Everything else in
deep teal-black shadow. Hand-illustrated storybook style, Iron Giant art
direction, painterly, mournful. Strong negative space, centre composition.
No text. No people.
```

### `art/ui/socket_lit.png` — 96×96, transparent
A single circular brass receptacle, lit warmly. Slight inner shadow giving it depth. Faint amber rim along the upper-right (the lamp direction).

```
A single 1985 brass telephone switchboard socket — a small circular
recessed receptacle in dark walnut wood, the inner hole glowing faintly
amber. Aged brass ring around it catches a thin warm highlight on the
upper right. Painterly texture, hand-illustrated. Centre composition,
transparent background, isolated, no other objects, no text.
```

### `art/ui/socket_dim.png` — 96×96, transparent
Same socket, unlit. No amber glow, ring tarnished and cooler.

```
A single 1985 brass telephone switchboard socket — a small circular
recessed receptacle in dark walnut wood, unlit. Tarnished cool brass
ring, no warm glow, the inner hole reading as deep teal-black. Painterly
texture, hand-illustrated. Centre composition, transparent background,
isolated, no other objects, no text.
```

### `art/ui/cable_jack.png` — 64×64, transparent
The plug end of the cable that the player drags. Aged red rubber housing, brass tip catching amber light. Hangs by a short bit of red rubber-coated cable.

```
The plug end of a 1985 telephone operator's cable — aged red rubber
grip housing, a polished brass tip catching warm amber lamp light, a
short stub of red rubber-coated cable trailing from it. Hand-illustrated,
painterly storybook texture. Centre composition, transparent background.
Slightly angled so the plug tip points up-right. No text.
```

### `art/ui/patience_light.png` — 32×32, transparent
A small frosted indicator lamp lit a desaturated mint-green (`#7AAE9A`). Brass collar around its base.

```
A small frosted glass indicator lamp lit a desaturated mint-green from
within, set in an aged brass collar. 1985 industrial control panel
aesthetic. Hand-illustrated, painterly. Centre composition, transparent
background. No text.
```

### Portrait silhouettes (Tier 1: 4 most-used callers)

Each follows the universal prefix. Insert these as `<CHARACTER>` descriptions:

**`art/portraits/daniel.png`** — *Daniel Hayes — calls in 4 times; most important.*
```
<CHARACTER> = a tall, lean man in his early thirties in profile, wearing
a baseball cap with a slight curved brim, a denim work jacket. He grips a
1980s telephone receiver hard against his ear, shoulders hunched forward
with worry. We see him as a pure dark silhouette from the side, like he's
in a phone booth at a highway truck stop. Behind him, the soft amber glow
of a distant gas station sign.
```

**`art/portraits/patty.png`**
```
<CHARACTER> = a middle-aged round-shouldered woman, hair tied up in a
kerchief, wearing an apron whose ties dangle behind her. She holds a
coffee pot in one hand and a telephone receiver in the other, leaning
on a diner counter. Side silhouette. The faint glow of a neon "OPEN"
sign visible behind her as a soft amber haze.
```

**`art/portraits/reverend.png`**
```
<CHARACTER> = a tall older man in a long dark coat, broad-brimmed hat
held in his free hand, the bright slit of a white clerical collar visible
at his throat. He's standing in profile in a chapel's foyer, telephone
receiver to ear. A small amber sanctuary lamp visible in the deep teal
behind him.
```

**`art/portraits/doc.png`**
```
<CHARACTER> = a stocky older man in a buttoned waistcoat with a bow tie,
two small round wire-frame glasses catching a tiny amber glint at his
profile, telephone receiver to ear. Behind him, the faint amber glow of
a clinic desk lamp on a wooden cabinet. Side silhouette.
```

### `art/title_logo.png` — 800×200, transparent
Just the words **"Last Call"** in hand-lettered serif, slightly imperfect strokes, warm bone colour (`#F1E4C8`) with a faint amber wash. Below it in much smaller letters: *"a story in ten calls"*.

```
The words "Last Call" hand-lettered in an imperfect 1940s-style serif,
slightly weathered, in warm bone-white with a faint amber wash. Below in
much smaller letters: "a story in ten calls". Centred, painterly,
storybook texture, transparent background. No frame, no decoration.
```

---

## Tier 2 — strong polish

### Remaining portrait silhouettes

Same prefix; replace `<CHARACTER>`.

**`art/portraits/henley.png`** — Mrs. Henley
```
<CHARACTER> = an elderly thin-shouldered woman, hair pulled into a tight
bun, lace collar visible as small bright bumps at her neck. She holds a
telephone receiver and peers through a window curtain into the night.
Side silhouette. Behind her the cool teal of an empty house at night,
a sliver of streetlamp amber bleeding through the curtain.
```

**`art/portraits/sheriff.png`** — Sheriff Briggs
```
<CHARACTER> = a stocky man with a wide flat-brimmed cowboy hat, square
shoulders, a tiny amber glint of a metal badge on his chest. He's at a
desk holding a phone receiver, body squared to the viewer slightly. Behind
him, a wall map and the small amber pool of a desk lamp.
```

**`art/portraits/cole.png`** — Cole
```
<CHARACTER> = a wiry man, ball cap turned backwards, the silhouette of
a wrench tucked in his back pocket, an oily rag draped over one shoulder.
He leans against a wall holding a wall-mounted telephone receiver. Side
silhouette. Behind him, the cavernous teal of a garage with a single
amber overhead work-lamp.
```

**`art/portraits/nurse.png`** — Final call
```
<CHARACTER> = a woman in a 1980s nursing uniform, a small soft cap with
a tiny cross silhouette, hair pulled back tight, posture stiff and
professional. She holds a phone at a hospital nursing station. Side
silhouette. Behind her, the cool teal of a long hospital corridor, a
single amber sconce far down the hall.
```

**`art/portraits/unknown.png`** — Wrong-number recipient
```
<CHARACTER> = a featureless generic head-and-shoulder silhouette of a
person holding a phone receiver. No identifying features at all. Black
against a flat neutral teal. Plain, unadorned, almost absent.
```

---

## Tier 3 — stretch

### `art/portraits/margaret_empty_chair.png`
For the calls where Daniel tries to reach Mom and there's no answer. Shown briefly during the "no answer" beat instead of any character silhouette.

```
An empty wooden rocking chair in a darkened sitting room. On a small
side table beside it, a 1985 telephone with the receiver in its cradle,
the cradle gently glowing amber as if ringing. Deep teal shadows around
the chair. Hand-illustrated, storybook softness, painterly. Centre
composition, transparent background, melancholic. No text, no people.
```

### Ring indicator lamp (animated, optional)
A single bigger version of the patience light — a frosted glass dome on a brass collar — that briefly pulses amber during the "ringing" beat between calls.

```
A small frosted glass dome lamp lit warm amber, set in an aged brass
collar mounted on a dark walnut switchboard panel. Industrial 1980s.
Hand-illustrated, painterly. Centre composition, transparent background.
No text.
```

If animated: render 3 frames — off, dim glow, full amber glow — looped at ~2 Hz during the ringing beat.

---

## Workflow

1. **Generate a test of one portrait first** (suggest `daniel.png`) to lock the AI tool, seed, and prompt template. Don't move on until the test looks right.
2. **Lock the seed and style modifiers.** Note the exact prompt + seed in `docs/AI_PROMPTS.md` (we'll create that as you go).
3. **Generate Tier 1 in one sitting**, same session, same seed/style for max consistency.
4. **Update `ATTRIBUTIONS.md`** as you save each file — `<filename> · <AI tool + model> · <prompt summary> · <seed>`.
5. **Hook into the game**: drop each portrait into `art/portraits/`, then assign on the relevant `CallData.tres` via `caller_portrait` (or, for line-specific portraits like recipients picking up, on the DialogueLine's `portrait` field).
6. **Replace placeholders incrementally** — the game stays playable throughout.

---

## Estimated count and time

Tier 1: 4 portraits + 4 backgrounds + 4 UI sprites + 1 logo = **13 generations** + iteration. Realistically 1–2 hours with a good AI workflow.

Full set (all tiers): ~25 generations. Half a day at most.
