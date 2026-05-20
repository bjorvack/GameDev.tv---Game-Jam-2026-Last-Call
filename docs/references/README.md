# Style reference images

These two images, taken together, define the visual target for Last Call. Upload one or both into your ChatGPT chat after the opener message to give DALL·E 3 a concrete style anchor.

## `firewatch_olly_moss_triptych.jpg`

Olly Moss key art for the game Firewatch (Campo Santo, 2014). The single best reference for **mood and palette**: a lonely human-made structure against a vast warm-to-dark sunset, layered silhouette planes (foreground/midground/background), strict limited palette of ~5 flat colours, screen-print/WPA-poster sensibility. No photographic realism. This is the colour temperature and atmospheric register we want.

**Use as primary reference for backgrounds** (switchboard, title, endings).

Source: Campo Santo / Olly Moss, 2014. Used here as a style reference only.

## `olly_moss_star_wars_silhouettes.jpg`

Olly Moss's Star Wars trilogy posters (Mondo, 2010). The single best reference for **character rendering**: each character is a pure flat silhouette in a single colour, with the contour alone carrying the character identity (C-3PO's antennae, Boba Fett's helmet, Vader's hood). Scenes are nested inside the silhouettes — but for our purposes the key takeaway is "characters as flat one-colour cutouts against a contrasting background plane".

**Use as primary reference for character portraits.**

Source: Olly Moss / Mondo, 2010. Used here as a style reference only.

---

## How to use these with ChatGPT / DALL·E 3

1. Start a fresh chat. Paste the opener from `docs/STYLE_GUIDE.md`.
2. **Before sending the first image prompt**, drag both images into the chat and write:

   > "Here are two reference images that define the visual target. Match this style: flat silhouettes (Star Wars posters reference), warm-on-cool limited palette with painterly grain (Firewatch reference), no photography. Confirm you can see both images and describe in one sentence what visual qualities I want to inherit from them, before I send the first generation prompt."

3. Once ChatGPT confirms the style, send the Daniel prompt from `docs/SPRITE_SPEC.md`.

These references aren't sacred — if ChatGPT picks up some quality from them you don't want (e.g. the Firewatch reds, or full-frame composition), say "match the simplicity of the Star Wars silhouettes but use the deep teal #0F2A33 night palette from our brief, not the Firewatch sunset reds".
