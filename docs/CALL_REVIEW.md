# Call Review — Deep Dive

**Audit of the 10-call structure in `tools/generate_calls.py`. Goal:**
does each call work standalone and inside the story arc, and is the
count of calls (10) actually right?

---

## Method

Each call is analysed against six axes:

1. **Premise clarity** — without external context, can the player infer the correct socket from the opening lines alone?
2. **Story function** — what does the call *do* for the night's arc?
3. **Hint payload** — what new information does the player walk away with?
4. **Voice & character** — does the dialogue distinguish the caller? Does the connected/wrong-response dialogue earn its lines?
5. **Stakes calibration** — does `time_limit`, `pivotal`, and `patience` cost fit the dramatic weight?
6. **Issues** — concrete problems worth fixing.

Then a macro pass: pacing, redundancy, cut/keep recommendation.

---

## Call 1 — `01_patty_cole.tres`

**Patty → Cole's Garage.** Tutorial.

- **Premise clarity:** ★★★★★. Patty literally names "Cole's Garage" in the opening. This violates the writing rule from `STORY.md` ("Never name the correct socket in the request") — but for a tutorial that's correct: a player has never seen the board before, so naming the socket teaches the verb.
- **Story function:** Establishes Patty (folksy, awake early), the diner, the existence of mundane breakdowns. Sets the night up as ordinary.
- **Hint payload:** Worldbuilding only. Patty's tone — "Mornin', operator" at whatever hour this is — quietly tells the player Briar Hollow is a place where people are friendly and the operator is known by voice.
- **Voice:** Patty's "Mornin'" + "Bless you, Cole" reads small-town American with no effort. Cole's "Cole's. Yep, I'll be over in twenty." is the right two-syllables-per-line laconic.
- **Stakes:** No timer, no pivotal flag, generic wrong response. Correct — first call is a free practice round.
- **Issues:** The `wrong_responses["hayes"]` entry — *"She must not be in. Try someone else, operator."* — leaks the existence of HAYES as a recipient and slightly foreshadows that someone called Mrs. Hayes is not picking up. That's lovely sliver of foreshadowing, but only if the player misroutes. Worth ensuring the player has *some* chance of seeing it — see macro pass.

**Verdict:** Keep as-is.

---

## Call 2 — `02_daniel_hayes.tres`

**Daniel Hayes → Mrs. Hayes (7th & Vine).** The hook.

- **Premise clarity:** ★★★★☆. Daniel says "Mrs. Hayes on 7th and Vine. She's my mother." The mental hop is *Mrs. Hayes* → socket labelled **HAYES**. Easy.
- **Story function:** Introduces every load-bearing element of the rest of the night: Daniel, Margaret (by absence), the Highway 40 distance, the missed morning call. This is the cold open of the actual story.
- **Hint payload:** The huge one — *"didn't answer her morning call"* establishes a routine that has been broken. Anyone who has had an aging parent knows what that line means at midnight.
- **Voice:** Daniel's three short opening sentences read like a man rehearsing what he'll say to the operator before he calls. The third line — "I'm two hours out on Highway 40" — is geographic exposition disguised as worry. Tight writing.
- **Stakes:** `time_limit = 25.0`, no `pivotal`. First time pressure of the night. The 25s feels generous because the player is still learning. Correct.
- **Wrong responses:** `doc` ("sorry, I was trying my mother") and `patty` ("Have you seen my mom today?" — Patty replies *"Not today, hon"*). Both add character and seed information. Patty's "Not today" is a *clue*: it means she normally would have seen Margaret. A careful player notices.
- **Issues:**
  1. Routing **correctly** here results in *no answer* — a quiet emotional beat, not the usual reward feedback. A first-time player might think they routed wrong. The 3-line aftermath (*"She… she must've gone to the market"*) salvages this, but the call leans on the player to *understand the silence is the point*. Worth keeping but worth noting as the only call where "success" is a downer.
  2. Daniel says *"the market"* — does Briar Hollow have a market open before noon? Probably not. He's lying to himself out loud. Beautiful but extremely subtle; consider one more line of marginalia in `CALL_LOG.md` highlighting it (already done in the artifact log).

**Verdict:** Keep. Strongest opening hook in the script.

---

## Call 3 — `03_henley_sheriff.tres`

**Mrs. Henley → Sheriff Briggs.** First drop of dread.

- **Premise clarity:** ★★★★★. "Connect me to the sheriff." Direct.
- **Story function:** External corroboration. The first non-Daniel voice that suggests something is wrong on Vine.
- **Hint payload:** *"There's been an ambulance sitting two streets over near Vine for ten minutes."* Connect to Call 2: Margaret lives at 7th & Vine. Ten-minute ambulance + nearby + odd hour = on her. This is where a sharp player starts to *know*.
- **Voice:** Henley's "this is Henley over on 8th" and "Something's not right" do their job. Briggs's single-word self-identification ("Briggs.") is established here and pays off in Call 6.
- **Stakes:** No timer. Correct — it's a witness call, not a panic call.
- **Wrong responses:** Only `hayes` (no answer) + generic. The hayes branch is great — it tells the player they tried Margaret's line and got silence *while* the ambulance is sitting outside. Doubly ominous.
- **Issues:**
  1. "Two streets over near Vine" is grammatically slightly fuzzy — *"two streets over from Vine"* or *"two streets from Vine, near her place"* would read cleaner.
  2. Briggs's response *"We're already on it"* is implicitly important — it tells the player the sheriff is aware before Henley even called. But it goes by fast. Could be drawn out a beat (one extra line).

**Verdict:** Keep. Consider one-word tightening pass on Henley's geography.

---

## Call 4 — `04_reverend_doc.tres`

**Reverend Carter → Doc Wheeler.** Filler / worldbuilding.

- **Premise clarity:** ★★★★★. "Put me through to Doc Wheeler, please." Named.
- **Story function:** This is the call the design doc explicitly labels *filler*. Function: establishes the Reverend and Doc exist, and they trust each other professionally. Also a *pacing breath* between the dread of Call 3 and the gut-punch of Call 5.
- **Hint payload:** The chapel has evening prayer — *anchors the in-fiction time of day*. Doc is on-call. Mr. Bray is a never-seen NPC, which is fine.
- **Voice:** Reverend's "Operator — the Chapel here" with the em-dash matches his diction across Calls 7 and 9. Doc's "On my way, Reverend." establishes him as terse — earning the contrast in Call 5 when he speaks four full sentences.
- **Stakes:** None.
- **Wrong responses:** Only generic. **This is the thinnest wrong-response bench in the script.**
- **Issues:**
  1. **Weakest narrative function of any call.** If we needed to cut, this is the candidate. *But* its function as pacing breath is real — sandwiching Call 5's bombshell directly against Call 3's dread would over-saturate. Recommend keeping but enriching: at least one bespoke wrong response (e.g. routing to Sheriff — *"Sheriff's office." / "Sorry, sheriff, wrong line. The clinic."* gives Briggs another voice beat).
  2. *"Mr. Bray taking a turn"* — period-correct euphemism, but a younger player may not parse "taking a turn" as "going into medical distress." Consider one disambiguating word: *"taking a bad turn"* or *"having a spell"*.

**Verdict:** Keep with light enrichment. **The most cut-able call but worth its slot for pacing.**

---

## Call 5 — `05_daniel_doc.tres`

**Daniel Hayes → Doc Wheeler.** Story tightens.

- **Premise clarity:** ★★★★☆. "Could you try Doc Wheeler?" Named. The chain of reasoning — *she had a check-up Thursday, maybe Doc knows where she went* — is the rationalisation Daniel is telling himself.
- **Story function:** The pivot. Doc breaks the wall and tells Daniel the truth on the line. *"Son — drive faster."*
- **Hint payload:** Massive. The player learns:
  - Margaret had chest pains Thursday.
  - She was told to call Doc if symptoms returned.
  - She didn't call (implication: she couldn't, or she didn't make it to the phone).
  - Doc is now *worried out loud*, which Doc — terse Doc, from Call 4 — would not be unless the worry was warranted.
- **Voice:** *"Wheeler."* — same cadence as Call 4. Then the long medical confession, beat by beat. The four-line build to "Son — drive faster" is the best-written stretch of the script.
- **Stakes:** `time_limit = 20.0`, no pivotal. Tightening from Call 2's 25s — correct escalation.
- **Wrong responses:** `hayes` (still no answer — *"Still nothing. Operator, please — try Doc Wheeler."*) and `sheriff` (*"Son, who am I talking to?"* — Briggs not yet aware the caller is Daniel-the-son-of-Margaret-who-his-deputies-are-at-right-now). The sheriff branch is **brilliant** because it foreshadows that Briggs is the one whose voice will identify Daniel by name in Call 6.
- **Issues:**
  1. Doc telling a worried son on the line that his mother had chest pains is borderline HIPAA-adjacent — but in 1960 rural America, with a personally-known doctor and patient, it is wholly plausible and dramatically necessary. Keep.
  2. The connected_dialogue is 4 lines and ~13 seconds of dialogue. That's a long beat. Pace-wise it works because it's the emotional climax of Act 2 — but it's the longest reading load in the script. Worth double-checking the duration values feel right when running.

**Verdict:** Keep. Don't touch the writing.

---

## Call 6 — `06_sheriff_patty.tres`

**Sheriff Briggs → Patty's Diner.** Confirmation.

- **Premise clarity:** ★★★★★. "Has Margaret Hayes been in today?" → Patty's Diner.
- **Story function:** The town puts it together. Patty's *"Oh god"* is the moment a second adult character realises Margaret is in serious trouble.
- **Hint payload:** Confirms there is a sheriff's unit at Margaret's place (relayed from Henley's call, which the player witnessed in Call 3). Confirms Patty hasn't seen Margaret today — and *"She came in yesterday morning. Said she was tired."* is a memory-as-clue.
- **Voice:** Briggs's "Patty? Briggs." matches his earlier cadence. Patty's *"Said she was tired"* trails into *"Oh god"* — earns the line by understatement.
- **Stakes:** None.
- **Wrong responses:** None — only generic. **Second-thinnest wrong-response bench, after Call 4.**
- **Issues:**
  1. **Possible redundancy with Call 8.** Both calls have a townsperson stating that something is happening at Margaret's place. Call 6 is from law-enforcement perspective (Briggs confirming), Call 8 is from civilian-on-scene perspective (Cole + chaplain at the door). Together they bracket the event from two viewpoints. **They aren't redundant — they're a chorus.** But it's the closest thing to repetition in the script.
  2. Worth a `wrong_responses["hayes"]` — routing Briggs to Margaret's line. Could land as one of the most devastating wrong-routes: Briggs gets the same silence Daniel got. Cheap to write, payoff is high.

**Verdict:** Keep. **Add one wrong response (`hayes`) for the misroute payoff.**

---

## Call 7 — `07_daniel_reverend.tres`

**Daniel Hayes → Reverend Carter.** Daniel rallies the ground team.

- **Premise clarity:** ★★★★★. "The Chapel, Reverend Carter."
- **Story function:** Daniel has accepted what's happening. He wants someone *at her door physically*. The Reverend is the obvious choice because (a) the chapel is in town, (b) the Reverend can be there in minutes, (c) the implication of clergy at the door is heavy.
- **Hint payload:** Daniel's brevity — two short lines, no preamble — does work. *He has stopped pretending it might be nothing.*
- **Voice:** "Hurry, please." Two syllables. The Reverend's response — *"I'll be at your mother's door in five. Stay on the road."* — is the most quietly devastating line in the script after Call 5's "Drive faster."
- **Stakes:** `time_limit = 15.0` — tightest of the night so far. Matches Daniel's panic.
- **Wrong responses:** `doc` only (*"Doc Wheeler — Daniel, is that you?" / "Doc, I need the Chapel."*) — already-established voices reused. No sheriff or hayes branch. Could add but doesn't *need* them.
- **Issues:**
  1. Daniel doesn't *explicitly* say why he wants the Reverend. The player has to infer (last-rites / someone present / spiritual rather than medical now). For the target audience this lands; for a first-time player it might be ambiguous. Worth considering one extra word of context, but probably correct as restraint.

**Verdict:** Keep. Possibly the most stylish call in the script.

---

## Call 8 — `08_cole_patty.tres`

**Cole → Patty's Diner.** The hint that lands.

- **Premise clarity:** ★★★★★. Cole calls Patty by name.
- **Story function:** Cole is the gossip relay. His call provides:
  - On-scene description: *"two units and a chaplain at Margaret's place."*
  - Confirmation that Reverend Carter (from Call 7) arrived.
  - Confirmation that the town is *now actively worried about Daniel*, not just Margaret.
- **Hint payload:** Patty's *"He's on Highway 40. Lord, he doesn't know yet."* is the **single most important hint in the script** — it tells the player that Daniel is unreachable by normal means and sets up the Highway 40 socket in Call 9. Without this line, Call 9's pivot would feel like a deus ex machina.
- **Voice:** Cole's "Truck stalled out near 7th and Vine" — incidentally Cole's truck is in the same intersection that's become the focal point of the story. He's the eyewitness who didn't mean to be one.
- **Stakes:** None.
- **Wrong responses:** None — only generic.
- **Issues:**
  1. Why does Cole call **Patty** and not the sheriff or Daniel? Because he doesn't have Daniel's number (Daniel's on a payphone), and Patty is the small-town information hub. Implicit; works.
  2. **Critical narrative load on a single line of Patty's connected dialogue.** If a player misses *"He's on Highway 40. Lord, he doesn't know yet,"* they'll be confused by Call 9. Consider a fractionally longer duration on that line so it has time to land.

**Verdict:** Keep. Critical bridge to Call 9.

---

## Call 9 — `09_reverend_i40.tres`

**Reverend Carter → Highway 40 Truck Stop, Marker 88.** Pivotal connection.

- **Premise clarity:** ★★★☆☆. The Reverend literally tells the operator where to plug ("the truck stop payphone at marker 88") — but the **HWY 40 MM 88** socket has *never appeared on the board before*. `sockets_lit` exposes it just for this call. The puzzle is *noticing the new socket* and trusting it.
- **Story function:** The crown jewel. The Reverend is trying to reach Daniel *before* Daniel learns of his mother's status secondhand or gives up driving. Margaret is alive.
- **Hint payload:** Margaret is **alive**. They're taking her to County General. This is a reversal — the player has been bracing for the worst since Call 5.
- **Voice:** Reverend is now in operations mode: a man holding the wheel in a storm. His instructions are specific because he has spent the last ten minutes thinking about exactly how to do this.
- **Stakes:** `time_limit = 18.0`, `pivotal = True`. Misroute or timeout triggers the **bad ending instantly** — bypassing the patience system. This is the single biggest mechanical moment in the game.
- **Wrong responses:** `hospital` — routing the Reverend to County General. The Nurse: *"County General, please hold —"* / Reverend: *"No — not yet — he needs to know FIRST."* **This is the best wrong-response in the script.** It tells the player that the hospital exists (foreshadowing Call 10) *while* explaining why this isn't the right choice yet. Two birds.
- **Issues:**
  1. How does the Reverend know Daniel is at marker 88? He'd have to guess based on Daniel's last-known location (Asheville-ish from Call 5) + driving speed + the route. This is *plausibly* worked out, but it isn't *stated*. A single line — *"Doc said he was outside Asheville an hour back — marker 88 is the next truck stop, try there"* — would make it ironclad. Minor.
  2. **The seventh socket lights up only for this call.** Players who don't scan the board for changes will not notice until they've already misrouted. Consider a small visual emphasis — extra glow, slight pulse, the patience indicator briefly fading — to draw the eye. (Implementation-level note, not script-level.)
  3. The connected_dialogue's first line is a narrator/SFX line: *"(Static. A trucker grabs the phone, runs out, flags Daniel down.)"* This is the most cinematic moment in the script. It also means the CallerCard plays a line with empty speaker — make sure the empty-speaker rendering is good and the line stays on screen long enough to read.

**Verdict:** Keep. Add one Reverend line of justification. Visual emphasis on the new socket.

---

## Call 10 — `10_daniel_hospital.tres`

**Daniel Hayes → County General Hospital.** The last call.

- **Premise clarity:** ★★★★★. "County General. I'm in the parking lot." Named. Like Call 1, naming the recipient is correct because this is the resolution, not a puzzle.
- **Story function:** Resolution. Daniel needs to know if his mother is still alive when he walks in.
- **Hint payload:** None — pure release.
- **Voice:** Daniel exhausted. Three short ellipsis-laden lines: *"Operator… please." / "I need to know if I can still — "* (trailing off). The Nurse's *"She's been asking for you."* is the line that earns the ending.
- **Stakes:** `time_limit = 25.0`. Generous — the player has been through it. No pivotal flag. By this point either the player has lost patience tokens (→ bad ending regardless) or they haven't (→ good ending). Call 10 is mostly mechanical formality + emotional release.
- **Wrong responses:** `hayes` — gut-wrenching. *"(no answer — that line is empty now)"* + Daniel: *"No — the hospital, operator. The hospital."*
- **Issues:**
  1. Two of three player-routable lines are narrator/SFX lines (the *"(Daniel's breath catches…)"* and *"(The operator's board goes dark, one light at a time.)"* lines in connected). The latter is essentially the ending text. Make sure the durations let these breathe.
  2. The *"hayes — that line is empty now"* wrong response should be *the* most-felt misroute of the game. If durations rush past it, it loses force.

**Verdict:** Keep. Confirm durations.

---

## Macro Pass

### Pacing

| # | Call | Time pressure | Length | Emotional load |
|---|------|---------------|--------|----------------|
| 1 | Patty → Cole | none | short | none |
| 2 | Daniel → Hayes | 25s | medium | high (set-up) |
| 3 | Henley → Sheriff | none | short | medium (foreboding) |
| 4 | Reverend → Doc | none | short | low (breath) |
| 5 | Daniel → Doc | 20s | long | **peak** (reveal) |
| 6 | Sheriff → Patty | none | short | medium (corroboration) |
| 7 | Daniel → Reverend | 15s | short | high (resolve) |
| 8 | Cole → Patty | none | medium | medium (bridge) |
| 9 | Reverend → MM88 | 18s + pivotal | long | **peak** (reversal) |
| 10 | Daniel → Hospital | 25s | medium | release |

The pattern is **U-shaped**: tension builds 1→5, breathes briefly at 6, climbs again 7→9, releases at 10. Time pressure correctly intensifies on Daniel's calls (25→20→15) before relaxing at 10.

This is textbook three-act with a midpoint reveal. No restructuring needed.

### Redundancy check

Only two calls overlap functionally:

- **Calls 6 and 8** both have townspeople processing what's happening at Margaret's. Call 6 is law-enforcement perspective (Briggs ↔ Patty), Call 8 is civilian-eyewitness perspective (Cole at the scene). They bracket the event from two viewpoints. **Not redundant — it's a chorus.**

### Wrong-response coverage

| Call | Bespoke wrong responses | Note |
|------|------------------------|------|
| 1 | 1 (hayes) | Foreshadows Daniel's silence |
| 2 | 2 (doc, patty) | Strongest worldbuilding |
| 3 | 1 (hayes) | Doubles down on dread |
| 4 | **0** | Thinnest |
| 5 | 2 (hayes, sheriff) | Best variety |
| 6 | **0** | Thin |
| 7 | 1 (doc) | Adequate |
| 8 | **0** | Thin |
| 9 | 1 (hospital) | Best line in script |
| 10 | 1 (hayes) | Devastating |

**Recommendation:** Add a single bespoke wrong response to each of 4, 6, 8. Cheap, high-yield enrichment.

### Do we need more calls?

**No.** Reasons:

- 10 calls × ~60s each ≈ 8–10 minutes of play. Adding calls dilutes tension.
- 89 dialogue lines / ~1,800 words is already a lot for a jam game. Read aloud, the existing script runs about 7 minutes of pure VO; you're at the upper boundary.
- The arc is complete. Every additional call would have to *do something new* — and the structure has no obvious gap.

The one "missing" beat is **Reverend arriving at Margaret's door**: between Call 7 (Reverend leaves) and Call 9 (Reverend coordinates marker 88), the Reverend physically arrives at Margaret's house and discovers she's alive. Currently we hear this *secondhand* — Cole sees him there in Call 8, and we infer he saw her alive because in Call 9 he knows. **This works through implication** but could be staged. Verdict: don't add, but be aware.

### Do we need fewer calls?

**No.** Reasons:

- **Call 4 is the weakest** but provides a pacing breath between the dread of Call 3 and the bombshell of Call 5. Removing it would push Call 5's emotional load directly against Call 3's dread without a beat to digest.
- **Calls 6 and 8 are close functionally** but serve different chorus voices. Cutting either would break the "town puts it together in stages" rhythm.
- 10 is a round, satisfying number for a "ten calls" framed story. The subtitle of the title logo even says *a story in ten calls* — changing the count would mean changing the art.

### Net recommendation

**Keep all 10 calls. No restructure.** Apply these small surgical improvements:

1. **Call 3** — tighten Henley's geography line ("two streets over near Vine" → "two streets from Vine").
2. **Call 4** — add one bespoke wrong response (suggest: `sheriff` — *"Sheriff's office." / "Sorry, Sheriff — wrong line. The clinic, please."*).
3. **Call 6** — add `wrong_responses["hayes"]` for the misroute payoff (Briggs gets the same silence Daniel did).
4. **Call 8** — extend Patty's *"He's on Highway 40. Lord, he doesn't know yet."* duration by ~0.5s so the hint lands hard.
5. **Call 9** — add one Reverend line justifying the marker-88 guess (*"Doc said he was outside Asheville an hour back — try the truck stop at marker 88"*). Mechanically emphasise the new socket on the board.
6. **Call 10** — confirm durations on the narrator/SFX lines so the closing read isn't rushed.

Total writing surface: ~6 lines of dialogue. Half a day's polish.

### Risk register

- **The biggest player-experience risk** is Call 9's reveal of a new socket. If the player misses that HWY 40 MM 88 has appeared, they'll spend their 18 seconds re-checking the six standard sockets and time out → bad ending. Worth a UI cue (pulse, glow, or a single line in the CallerCard's request like *"…try the truck stop payphone at marker 88, operator — the line just opened."*).
- **The second-biggest risk** is Call 2's correct-routing outcome (no answer). New players may panic-click another socket thinking they misrouted. Worth a forgiving design: maybe the *first* connection to HAYES that returns no-answer doesn't count against patience even on a successful route. (Worth testing.)
