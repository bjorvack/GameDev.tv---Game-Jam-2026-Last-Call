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

## Universal AI prompt skeleton

Use the same prefix for every portrait generation so style locks. Replace `<CHARACTER>` with the per-sprite description from `docs/SPRITE_SPEC.md`.

```
A hand-illustrated storybook silhouette portrait. 1985 American small town
at night. Pure dark figure of <CHARACTER>, no face details, lit from
upper-right by warm amber lamp light catching a thin rim along the upper
edges. Deep teal background, very dark, with a soft amber glow on one side.
Storybook softness, painterly textures, fine warm film grain. Iron Giant
art direction, Lotte Reiniger shadow play composition. Centre composition,
60% negative space. No text. No modern elements. Muted, melancholic mood.
```

Negative prompt (every generation):
```
no faces, no facial features, no neon, no daylight, no bright colors, no
text, no watermark, no harsh outlines, no anime, no realistic photography,
no modern technology
```

Seed: fix to one value across all character portraits for maximum consistency.

---

## What this guide is NOT

It is *not* a colour wheel for the GDscript-coloured placeholders we're using now (`#133C4C` background, `#c14b4b` cable, etc.). Those are close enough for the prototype. When we replace placeholders with art, the colours in this guide are the targets — the placeholders should be retired in the same pass.
