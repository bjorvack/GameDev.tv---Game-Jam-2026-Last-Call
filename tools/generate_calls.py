#!/usr/bin/env python3
"""Generate CallData .tres files from a compact Python spec.

Run from the project root:
    uv run tools/generate_calls.py
or:
    python3 tools/generate_calls.py

The Python list `CALLS` below is the source of truth. Each entry produces
one `data/calls/NN_<slug>.tres`. To tweak dialogue, edit this file and rerun.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = PROJECT_ROOT / "data" / "calls"


@dataclass
class Line:
    speaker: str
    text: str
    duration: float = 2.5


@dataclass
class Call:
    slug: str
    caller_name: str
    opening: list[Line]
    correct_socket: str
    connected: list[Line]
    wrong_responses: dict[str, list[Line]] = field(default_factory=dict)
    generic_wrong: list[Line] = field(default_factory=list)
    time_limit: float = 0.0
    timer_expired: list[Line] = field(default_factory=list)
    sockets_lit: list[str] = field(default_factory=list)
    pivotal: bool = False


# Shorthand: a generic short wrong-number exchange used whenever a specific
# wrong-response isn't authored.
def generic_wrong(caller: str) -> list[Line]:
    return [
        Line("???", "Hello?", duration=1.5),
        Line(caller, "Sorry — wrong number.", duration=2.0),
    ]


CALLS: list[Call] = [
    # ── 1. Tutorial ────────────────────────────────────────────────────────
    Call(
        slug="01_patty_cole",
        caller_name="Patty",
        opening=[
            Line("Patty", "Mornin', operator. Patty here."),
            Line("Patty", "My delivery truck won't crank — could you put me through to Cole's Garage?", duration=3.5),
        ],
        correct_socket="cole",
        connected=[
            Line("Cole", "Cole's. Yep, I'll be over in twenty.", duration=3.0),
            Line("Patty", "Bless you, Cole.", duration=2.0),
        ],
        wrong_responses={
            "hayes": [
                Line("???", "(ringing… no answer)", duration=2.5),
                Line("Patty", "She must not be in. Try someone else, operator.", duration=3.0),
            ],
        },
        generic_wrong=generic_wrong("Patty"),
    ),

    # ── 2. The hook ────────────────────────────────────────────────────────
    Call(
        slug="02_daniel_hayes",
        caller_name="Daniel Hayes",
        opening=[
            Line("Daniel", "Hello? Operator?"),
            Line("Daniel", "I need to reach Mrs. Hayes on 7th and Vine. She's my mother — she didn't answer her morning call.", duration=4.5),
            Line("Daniel", "I'm two hours out on I-40.", duration=2.5),
        ],
        correct_socket="hayes",
        connected=[
            Line("", "(Ring. Ring. Ring. No answer.)", duration=3.5),
            Line("Daniel", "She… she must've gone to the market.", duration=3.0),
            Line("Daniel", "I'll try again later. Thanks.", duration=2.5),
        ],
        wrong_responses={
            "doc": [
                Line("Doc Wheeler", "Doc Wheeler's office.", duration=2.0),
                Line("Daniel", "Doc — sorry, I was trying my mother.", duration=3.0),
            ],
            "patty": [
                Line("Patty", "Patty's Diner.", duration=1.8),
                Line("Daniel", "Patty, have you seen my mom today?", duration=2.5),
                Line("Patty", "Not today, hon. Sorry.", duration=2.0),
            ],
        },
        generic_wrong=generic_wrong("Daniel"),
        time_limit=25.0,
        timer_expired=[
            Line("Daniel", "Operator? Operator, please — I'll call back.", duration=3.5),
        ],
    ),

    # ── 3. First drop of dread ─────────────────────────────────────────────
    Call(
        slug="03_henley_sheriff",
        caller_name="Mrs. Henley",
        opening=[
            Line("Mrs. Henley", "Operator, this is Henley over on 8th."),
            Line("Mrs. Henley", "There's been an ambulance sitting two streets over near Vine for ten minutes.", duration=4.0),
            Line("Mrs. Henley", "Connect me to the sheriff, would you? Something's not right.", duration=3.5),
        ],
        correct_socket="sheriff",
        connected=[
            Line("Sheriff Briggs", "Briggs.", duration=1.5),
            Line("Sheriff Briggs", "Appreciate the call, Mrs. Henley. We're already on it. Stay inside.", duration=4.0),
        ],
        wrong_responses={
            "hayes": [
                Line("", "(no answer)", duration=2.0),
                Line("Mrs. Henley", "Lord, that's her line. Try the sheriff, operator.", duration=3.5),
            ],
        },
        generic_wrong=generic_wrong("Mrs. Henley"),
    ),

    # ── 4. Filler / worldbuilding ──────────────────────────────────────────
    Call(
        slug="04_reverend_doc",
        caller_name="Reverend Carter",
        opening=[
            Line("Reverend Carter", "Operator — the Chapel here."),
            Line("Reverend Carter", "I've got old Mr. Bray taking a turn during evening prayer. Put me through to Doc Wheeler, please.", duration=4.5),
        ],
        correct_socket="doc",
        connected=[
            Line("Doc Wheeler", "On my way, Reverend.", duration=2.5),
        ],
        generic_wrong=generic_wrong("Reverend Carter"),
    ),

    # ── 5. Story tightens ──────────────────────────────────────────────────
    Call(
        slug="05_daniel_doc",
        caller_name="Daniel Hayes",
        opening=[
            Line("Daniel", "Operator, it's Daniel Hayes again."),
            Line("Daniel", "Still no answer at Mom's.", duration=2.0),
            Line("Daniel", "Could you try Doc Wheeler? She had a check-up Thursday — maybe he knows if she went somewhere.", duration=4.5),
        ],
        correct_socket="doc",
        connected=[
            Line("Doc Wheeler", "Wheeler.", duration=1.5),
            Line("Doc Wheeler", "Daniel… your mother came in Thursday with chest pains.", duration=4.0),
            Line("Doc Wheeler", "I told her to call me at the first sign it came back.", duration=3.5),
            Line("Doc Wheeler", "Son — drive faster.", duration=2.5),
        ],
        wrong_responses={
            "hayes": [
                Line("", "(no answer)", duration=2.5),
                Line("Daniel", "Still nothing. Operator, please — try Doc Wheeler.", duration=3.5),
            ],
            "sheriff": [
                Line("Sheriff Briggs", "Sheriff's office.", duration=1.8),
                Line("Daniel", "Sheriff — I'm sorry, wrong line. I'm trying to reach Doc Wheeler.", duration=4.0),
                Line("Sheriff Briggs", "…Son, who am I talking to?", duration=2.5),
            ],
        },
        generic_wrong=generic_wrong("Daniel"),
        time_limit=20.0,
        timer_expired=[
            Line("Daniel", "Operator? I'm losing signal. Try again — please.", duration=3.5),
        ],
    ),

    # ── 6. Confirmation ────────────────────────────────────────────────────
    Call(
        slug="06_sheriff_patty",
        caller_name="Sheriff Briggs",
        opening=[
            Line("Sheriff Briggs", "Patty? Briggs."),
            Line("Sheriff Briggs", "Has Margaret Hayes been in today? Henley says there's a unit at her place.", duration=4.0),
        ],
        correct_socket="patty",
        connected=[
            Line("Patty", "She came in yesterday morning. Said she was tired.", duration=3.5),
            Line("Patty", "Hasn't been in today, Sheriff. Oh god.", duration=3.0),
        ],
        generic_wrong=generic_wrong("Sheriff Briggs"),
    ),

    # ── 7. Daniel rallies ──────────────────────────────────────────────────
    Call(
        slug="07_daniel_reverend",
        caller_name="Daniel Hayes",
        opening=[
            Line("Daniel", "Operator — the Chapel, Reverend Carter."),
            Line("Daniel", "Hurry, please.", duration=2.0),
        ],
        correct_socket="reverend",
        connected=[
            Line("Reverend Carter", "I'm leaving now, son.", duration=2.5),
            Line("Reverend Carter", "I'll be at your mother's door in five.", duration=3.0),
            Line("Reverend Carter", "Stay on the road.", duration=2.0),
        ],
        wrong_responses={
            "doc": [
                Line("Doc Wheeler", "Wheeler — Daniel, is that you?", duration=2.5),
                Line("Daniel", "Doc, I need the Chapel. The Reverend.", duration=3.0),
            ],
        },
        generic_wrong=generic_wrong("Daniel"),
        time_limit=15.0,
        timer_expired=[
            Line("Daniel", "Operator?? OPERATOR.", duration=2.5),
        ],
    ),

    # ── 8. Hint that lands ─────────────────────────────────────────────────
    Call(
        slug="08_cole_patty",
        caller_name="Cole",
        opening=[
            Line("Cole", "Patty, it's Cole."),
            Line("Cole", "Truck stalled out near 7th and Vine — there's two units and a chaplain at Margaret's place.", duration=4.5),
            Line("Cole", "Anyone heard from Daniel?", duration=2.5),
        ],
        correct_socket="patty",
        connected=[
            Line("Patty", "He's on I-40.", duration=2.0),
            Line("Patty", "Lord, he doesn't know yet.", duration=2.5),
        ],
        generic_wrong=generic_wrong("Cole"),
    ),

    # ── 9. The pivotal connection ──────────────────────────────────────────
    Call(
        slug="09_reverend_i40",
        caller_name="Reverend Carter",
        opening=[
            Line("Reverend Carter", "Operator. I need to reach Daniel Hayes — he's on the highway."),
            Line("Reverend Carter", "Try the truck stop payphone at marker 88.", duration=3.5),
            Line("Reverend Carter", "Tell him his mother's alive. They're taking her to County General.", duration=4.5),
        ],
        correct_socket="i40",
        connected=[
            Line("", "(Static. A trucker grabs the phone, runs out, flags Daniel down.)", duration=4.0),
            Line("Daniel", "(distant, breathless) Tell the Reverend — tell him I'm coming.", duration=4.0),
        ],
        wrong_responses={
            "hospital": [
                Line("Nurse", "County General, please hold —", duration=2.5),
                Line("Reverend Carter", "No — not yet — he needs to know FIRST.", duration=3.5),
            ],
        },
        generic_wrong=[
            Line("???", "Hello?", duration=1.5),
            Line("Reverend Carter", "No, no — the truck stop, operator! Marker 88!", duration=3.5),
        ],
        time_limit=18.0,
        timer_expired=[
            Line("Reverend Carter", "(Lord forgive us.)", duration=3.0),
        ],
        sockets_lit=["hayes", "doc", "sheriff", "reverend", "patty", "cole", "i40"],
        pivotal=True,
    ),

    # ── 10. The last call ──────────────────────────────────────────────────
    Call(
        slug="10_daniel_hospital",
        caller_name="Daniel Hayes",
        opening=[
            Line("Daniel", "Operator… please."),
            Line("Daniel", "County General. I'm in the parking lot.", duration=3.0),
            Line("Daniel", "I need to know if I can still — ", duration=3.0),
        ],
        correct_socket="hospital",
        connected=[
            Line("Nurse", "Mr. Hayes? She's awake.", duration=3.0),
            Line("Nurse", "She's been asking for you.", duration=3.0),
            Line("", "(Daniel's breath catches. The line goes warm with quiet.)", duration=4.0),
            Line("", "(The operator's board goes dark, one light at a time.)", duration=4.0),
        ],
        wrong_responses={
            "hayes": [
                Line("", "(no answer — that line is empty now)", duration=3.0),
                Line("Daniel", "No — the hospital, operator. The hospital.", duration=3.0),
            ],
        },
        generic_wrong=generic_wrong("Daniel"),
        time_limit=25.0,
        timer_expired=[
            Line("Daniel", "(silence — then a click)", duration=3.5),
        ],
        sockets_lit=["hayes", "doc", "sheriff", "reverend", "patty", "cole", "hospital"],
    ),
]


def emit_line(line: Line, sub_id: str) -> str:
    return (
        f'[sub_resource type="Resource" id="{sub_id}"]\n'
        f'script = ExtResource("2_dline")\n'
        f'speaker = {json_str(line.speaker)}\n'
        f'text = {json_str(line.text)}\n'
        f'duration = {line.duration}\n\n'
    )


def json_str(s: str) -> str:
    """Escape a string for tscn/tres."""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'


def lines_array(lines: list[Line], prefix: str, sub_ids: list[str], blocks: list[str]) -> str:
    """Emit the sub_resource blocks and return the array literal."""
    ids_here: list[str] = []
    for i, line in enumerate(lines):
        sid = f"{prefix}_{i}"
        sub_ids.append(sid)
        blocks.append(emit_line(line, sid))
        ids_here.append(sid)
    if not ids_here:
        return "Array[Resource]([])"
    refs = ", ".join(f'SubResource("{sid}")' for sid in ids_here)
    return f"Array[Resource]([{refs}])"


def emit_call(call: Call) -> str:
    sub_ids: list[str] = []
    blocks: list[str] = []

    opening_arr = lines_array(call.opening, "opening", sub_ids, blocks)
    connected_arr = lines_array(call.connected, "connected", sub_ids, blocks)
    generic_arr = lines_array(call.generic_wrong, "generic", sub_ids, blocks)
    timer_arr = lines_array(call.timer_expired, "timer", sub_ids, blocks)

    wrong_entries: list[str] = []
    for socket, lines in call.wrong_responses.items():
        arr = lines_array(lines, f"wrong_{socket}", sub_ids, blocks)
        wrong_entries.append(f"&{json_str(socket)}: {arr}")
    wrong_dict = "{\n" + ",\n".join(wrong_entries) + "\n}" if wrong_entries else "{}"

    lit_arr = (
        "Array[StringName]([" + ", ".join(f"&{json_str(s)}" for s in call.sockets_lit) + "])"
        if call.sockets_lit else "Array[StringName]([])"
    )

    load_steps = 2 + len(sub_ids)  # 2 ext_resources + N sub_resources

    parts: list[str] = []
    parts.append(f'[gd_resource type="Resource" script_class="CallData" load_steps={load_steps} format=3]\n\n')
    parts.append('[ext_resource type="Script" path="res://scripts/call_data.gd" id="1_calldata"]\n')
    parts.append('[ext_resource type="Script" path="res://scripts/dialogue_line.gd" id="2_dline"]\n\n')
    parts.extend(blocks)
    parts.append("[resource]\n")
    parts.append('script = ExtResource("1_calldata")\n')
    parts.append(f"caller_name = {json_str(call.caller_name)}\n")
    parts.append(f"opening = {opening_arr}\n")
    parts.append(f"correct_socket = &{json_str(call.correct_socket)}\n")
    parts.append(f"connected_dialogue = {connected_arr}\n")
    parts.append(f"wrong_responses = {wrong_dict}\n")
    parts.append(f"generic_wrong_response = {generic_arr}\n")
    parts.append(f"time_limit = {call.time_limit}\n")
    parts.append(f"timer_expired = {timer_arr}\n")
    parts.append(f"sockets_lit = {lit_arr}\n")
    parts.append(f"pivotal = {'true' if call.pivotal else 'false'}\n")
    return "".join(parts)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for call in CALLS:
        text = emit_call(call)
        path = OUT_DIR / f"{call.slug}.tres"
        path.write_text(text, encoding="utf-8")
        print(f"  → {path.relative_to(PROJECT_ROOT)}")
    print(f"Generated {len(CALLS)} call resources.")


if __name__ == "__main__":
    main()
