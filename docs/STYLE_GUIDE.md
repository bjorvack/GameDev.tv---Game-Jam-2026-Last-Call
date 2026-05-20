# Visual style guide — Last Call

## Vision in one line

> *A storybook silhouette set lit by a single amber lamp against the deep teal of a 1985 small-town night.*

The game's visual identity sits at the intersection of three references:
- **The Iron Giant / Anastasia** for the hand-illustrated storybook softness and unmistakable shape language
- **Lotte Reiniger shadow plays** for clarity-through-silhouette
- **Hopper / "Drive" / "Better Call Saul"** for the mood: warm interior light, deep cool exterior night

You can read the entire game in two colours: **amber** (the desk lamp, the operator's lifeline) and **deep teal** (the night, the void around her).

---

## Palette

Hard rule: 90% of every frame uses these five values. A scene that strays from them should look *wrong* on purpose.

| Role | Hex | Notes |
|------|-----|-------|
| Deep teal night | `#0F2A33` | The dominant background. Cool, slightly green-blue. |
| Mid teal shadow | `#173E4A` | Surfaces in shadow on the switchboard. |
| Warm wood / brass | `#5A3A22` | Switchboard panel, picture frame edges. |
| Amber lamp | `#E8B86A` | The operator's lamp light. Used for highlights, lit sockets, the cable. |
| Bone / paper | `#F1E4C8` | Text labels on the board. Slightly off-white, never pure. |

Two diegetic accents allowed:
- `#C14B4B` — **the cable**. Aged red rubber. Visually the only saturated red in the game. The cable IS the thematic throughline; everything else recedes so it pops.
- `#7AAE9A` — a desaturated mint for lit patience lights (currently yellow — recommend changing to this). Cooler, more "indicator-lamp-with-frosted-glass" than current sunshine yellow.

---

## Lighting

There is **one diffuse warm light source** in every interior frame: the operator's desk lamp, off-screen above and to the right. Everything else falls into teal shadow.

- Edges of silhouettes catch a thin rim of amber on their upper-right
- The switchboard panel surface has a subtle amber wash on the top half, deep teal below
- Backgrounds beyond the desk are *dark* — characters in other locations are framed against silhouetted window light or single lamps in their own rooms

No bright skies. No daylight. Every call happens at night.

---

## Texture & grain

- Subtle warm film grain across everything (add as a shader or texture overlay)
- Tiny paper-fibre texture on UI panels — this is a storybook, not a glossy screen
- Avoid: harsh anti-aliased vectors, neon glow, lens flares, modern UI gradients

---

## Composition rules

1. **Centre-weighted.** Characters and key objects sit at frame centre, framed by darkness. Storybook page composition.
2. **Negative space is the point.** A character takes maybe 40% of their portrait area. The rest is mood.
3. **No clutter.** A switchboard has six visible plugs. A diner has a counter, a coffee cup, nothing else. Strip everything you can.
4. **Diegetic light shapes.** A lamp cone, a TV glow, headlights through fog — light is always doing narrative work.

---

## Silhouette language

Characters are pure dark shapes against an amber-tinted environment glow. To keep nine silhouettes *readable* we lean on **shape language** instead of face details:

| Character | Defining silhouette traits |
|-----------|---------------------------|
| Patty | Round body, hair tied up in a kerchief, apron strings dangling. Holding a coffee pot. |
| Daniel Hayes | Tall, lean, baseball cap brim. Phone receiver pressed hard to ear, shoulders forward. |
| Mrs. Henley | Older woman, narrow shoulders, hair in a tight bun, lace collar bumps. Peering through a window. |
| Reverend Carter | Tall in a long coat, clerical collar visible as a small bright slit. Hat in hand. |
| Doc Wheeler | Stocky, wire-frame glasses (silhouetted as two small circles), bow tie. |
| Sheriff Briggs | Hat brim wide and flat, square shoulders, badge as a tiny glint. |
| Cole | Wiry, ball cap turned backwards, wrench in back pocket. Greasy rag on shoulder. |
| Margaret Hayes | *Never directly shown.* Represented by an empty rocking chair silhouette + a single ringing lamp. |
| Nurse | Cap with small cross, hair pulled back. Stiff posture. |
| Unknown (wrong number) | Generic featureless head + shoulder. No defining trait. Black against neutral teal — they don't deserve detail. |

---

## Universal AI prompt skeleton (Gemini / Imagen + Nano Banana)

Gemini's image generation (Imagen 3 by default, Gemini 2.5 Flash Image "Nano Banana" for editing/iteration) follows prompts more literally than DALL·E 3 and accepts proper multi-image reference input. The winning strategy for our project:

1. **One chat session for everything.** Style consistency comes from chat memory + repeated style references.
2. **After the first good portrait (Daniel) is generated, attach that image as a reference in EVERY subsequent prompt.** Gemini's image-to-image conditioning is its biggest advantage over DALL·E 3 — use it.
3. **Negative prompts work** — Gemini respects "do not include faces / do not use red colours" reasonably well. We still prefer positive phrasings (clearer to the model) but you can append a short "Avoid:" line.

### Step 1 — chat opener (paste once at the start of a FRESH chat)

```
I'm commissioning a set of illustrations for a small narrative game
called "Last Call". Every image must follow these STRICT, non-negotiable
constraints — treat them as the brief:

MEDIUM (hard requirement, never break):
- Hand-illustrated, two-dimensional, GRAPHIC POSTER STYLE.
- Style references: Olly Moss, Jon Klassen, Eyvind Earle.
- FLAT FIELDS of colour. Minimal shading. No 3D rendering.
- NOT photography. NOT photorealistic. NOT cinematic film stills.
- NOT CGI. NOT digital painting that imitates photography.
- Visible painterly grain or screen-print texture is welcome.

CHARACTERS (when present):
- Always rendered as PURE BLACK SILHOUETTES (#000000).
- Zero internal detail: no facial features, no skin tone, no eyes, no
  lips, no individual hair strands, no fabric folds, no jewellery.
- A character is a single dark cutout shape — like a paper puppet.
- The CONTOUR alone tells you who they are (hat shape, posture,
  what they're holding).

PALETTE (strict, no other colours allowed):
- Deep teal night #0F2A33  — the dominant background.
- Mid teal shadow #173E4A  — secondary background plane.
- Warm wood brown #5A3A22  — wooden interiors only.
- Amber lamp light #E8B86A — the ONE warm light source per image.
- Bone paper white #F1E4C8 — small text labels or sign letters.
- Aged red #C14B4B          — telephone cables ONLY.
- Mint indicator #7AAE9A    — tiny indicator lamps ONLY.
Avoid bright neon orange, hot reds, cyan, white skies, any saturated
colours not in the list.

LIGHT:
- Exactly ONE warm amber light source per image, falling from the
  upper right.
- A thin amber rim catches the top-right edges of silhouettes only;
  the rest of the silhouette stays pure black.
- No volumetric god-rays. No bright bloom. No lens flares. No realism.

COMPOSITION:
- Centered subject, 50–60% NEGATIVE SPACE around it.
- Looks like a single illustrated plate from a 1980s storybook.

INSTRUCTIONS TO YOU:
- Render my prompts EXACTLY as written. Do NOT rewrite, expand, or
  "improve" them before sending to the image model.
- Do NOT add detail I didn't request.
- Do NOT add text, signage letters, or words unless I explicitly ask.
- Do NOT add people or animals I didn't describe.
- If a generation comes out photographic or with visible faces, I will
  ask you to regenerate — do not protest, just regenerate enforcing
  the constraints harder.

Confirm you understand by replying only with: "Locked in. Send the
first image prompt."
```

Wait for ChatGPT's confirmation before sending your first image prompt.

### Step 2 — per-image prefix

Send every image request with this prefix, then the per-sprite description:

```
Next image in the Last Call storybook set, same style as before.
Aspect ratio: <SIZE>. Composition: centered with strong negative space.
Subject: <CHARACTER OR SCENE FROM SPRITE_SPEC.md>
```

`<SIZE>` is either `1024x1024` (portraits, UI) or `1792x1024` (landscape backgrounds). DALL·E 3 only supports those plus `1024x1792`.

### Writing prompts that survive DALL·E 3

- **Flowing prose, not tag soup.** "A stocky older man in a buttoned waistcoat" beats "stocky, waistcoat, bow tie, glasses".
- **Describe absence positively.** Instead of "no faces", say "pure dark silhouette with no facial features visible". Instead of "no text", just leave text unmentioned (and add "no text or signage" only if it's been a problem).
- **Place light explicitly.** "Lit from the upper right by a warm amber lamp" produces consistent lighting across images.
- **Repeat the style words.** Every prompt should include "hand-illustrated storybook silhouette" and the palette anchors ("deep teal", "amber"). Yes it's repetitive — that's how DALL·E 3 stays on style.
- **Iterate in chat.** If a generation drifts, reply: "make the silhouette darker / move the figure further from the center / reduce the amber glow / match the style of the previous image more closely". The next render usually corrects.

---

## What this guide is NOT

It is *not* a colour wheel for the GDscript-coloured placeholders we're using now (`#133C4C` background, `#c14b4b` cable, etc.). Those are close enough for the prototype. When we replace placeholders with art, the colours in this guide are the targets — the placeholders should be retired in the same pass.
