# Scene setup — component-scene approach

Godot 4.6. Autoload `GameState` is already registered.

Philosophy: **one responsibility per scene file**. Each reusable component lives in its own `.tscn`, configured via exported properties. The main `switchboard.tscn` mostly just *instantiates* them.

---

## Scene inventory

| Scene | Root type | Purpose | Reused? |
|------|-----------|---------|---------|
| `components/socket.tscn` | `Area2D` | One plug receptacle | × 8 |
| `components/cable.tscn` | `Line2D` | The draggable cable | × 1 (could be more later) |
| `components/patience_light.tscn` | `TextureRect` | A single indicator light | × 3 |
| `components/caller_card.tscn` | `PanelContainer` | Caller portrait + name + request text | × 1 |
| `components/post_connect_box.tscn` | `PanelContainer` | The post-connect dialogue area | × 1 |
| `scenes/switchboard.tscn` | `Node2D` | Composes everything for gameplay | × 1 |
| `scenes/title.tscn` | `Control` | Title screen | × 1 |
| `scenes/ending_good.tscn` | `Control` | Good ending | × 1 |
| `scenes/ending_bad.tscn` | `Control` | Bad ending | × 1 |

---

## 1. `components/socket.tscn`

**Root: `Area2D`** named `Socket`, script `res://scripts/socket.gd`.

Children:
- `CollisionShape2D` with `CircleShape2D`, radius `32`
- `Sprite2D` named `Visual` — placeholder texture (use `icon.svg` for now)
- `Label` named `NameLabel` — positioned below the sprite, autowrap on, centered

Add the root to group **`sockets`** (Node tab → Groups → add `sockets`).

In `socket.gd`, sync the label automatically so each instance "just works" when you set its export:

```gdscript
class_name Socket
extends Area2D

signal cable_plugged(socket_key: StringName)

@export var socket_key: StringName = &"":
    set(value):
        socket_key = value

@export var label_text: String = "":
    set(value):
        label_text = value
        if is_node_ready():
            $NameLabel.text = label_text

var lit: bool = true:
    set(value):
        lit = value
        modulate.a = 1.0 if lit else 0.3

func _ready() -> void:
    $NameLabel.text = label_text

func plug() -> void:
    if lit:
        cable_plugged.emit(socket_key)
```

(Replace `scripts/socket.gd` with the version above — same intent, just keeps the visual in sync with the export.)

Save as `res://components/socket.tscn`.

---

## 2. `components/cable.tscn`

**Root: `Line2D`** named `Cable`, script `res://scripts/cable.gd`.

- Width `8`, Default Color warm red `#c14b4b`
- Add a `Sprite2D` child named `Jack` for the visual base (placeholder for now)

Save as `res://components/cable.tscn`.

---

## 3. `components/patience_light.tscn`

**Root: `TextureRect`** named `PatienceLight`.

- 24×24
- `Texture` placeholder (any small circle png — for now leave empty + use a `ColorRect` if you don't have art)
- Add a small script if you want fade animations, but optional for Day 1.

Save as `res://components/patience_light.tscn`.

---

## 4. `components/caller_card.tscn`

**Root: `PanelContainer`** named `CallerCard`.

Tree:
```
CallerCard (PanelContainer)
└── HBoxContainer
    ├── TextureRect "Portrait" (96×96)
    └── VBoxContainer
        ├── Label "CallerName" (bold, large)
        └── Label "RequestText" (autowrap = Word Smart)
```

Attach a small script for setters:

```gdscript
# components/caller_card.gd
class_name CallerCard
extends PanelContainer

@onready var portrait: TextureRect = $HBoxContainer/Portrait
@onready var caller_name: Label = $HBoxContainer/VBoxContainer/CallerName
@onready var request_text: Label = $HBoxContainer/VBoxContainer/RequestText

func show_call(c: CallData) -> void:
    caller_name.text = c.caller_name
    request_text.text = c.request_text
    portrait.texture = c.caller_portrait
```

Save as `res://components/caller_card.tscn` (with `caller_card.gd` next to it).

---

## 5. `components/post_connect_box.tscn`

**Root: `PanelContainer`** named `PostConnectBox`.

Tree:
```
PostConnectBox (PanelContainer)
└── Label "Text" (autowrap on)
```

Tiny script to step through lines:

```gdscript
# components/post_connect_box.gd
class_name PostConnectBox
extends PanelContainer

signal finished

@export var line_duration: float = 2.5

@onready var label: Label = $Text

func play(lines: Array[String]) -> void:
    show()
    for line in lines:
        label.text = line
        await get_tree().create_timer(line_duration).timeout
    hide()
    finished.emit()

func _ready() -> void:
    hide()
```

Save as `res://components/post_connect_box.tscn`.

---

## 6. `scenes/switchboard.tscn` — the composition

**Root: `Node2D`** named `Switchboard`, script `res://scripts/call_director.gd`.

Tree (mostly *instances* now):
```
Switchboard (Node2D)                      ← call_director.gd
├── BG (ColorRect or Sprite2D)            ← placeholder bg
├── Sockets (Node2D)
│   ├── Socket (instance) "Hayes"         ← set socket_key=hayes, label_text="Mrs. Hayes — 7th & Vine"
│   ├── Socket (instance) "Doc"
│   ├── Socket (instance) "Sheriff"
│   ├── Socket (instance) "Reverend"
│   ├── Socket (instance) "Patty"
│   ├── Socket (instance) "Cole"
│   ├── Socket (instance) "I40"           ← lit = false
│   └── Socket (instance) "Hospital"      ← lit = false
├── Cable (instance of cable.tscn)
└── HUD (CanvasLayer)
    ├── TopBar (MarginContainer)
    │   └── HBoxContainer
    │       ├── CallerCard (instance)
    │       └── Patience (HBoxContainer)
    │           ├── PatienceLight (instance)
    │           ├── PatienceLight (instance)
    │           └── PatienceLight (instance)
    └── BottomBar (MarginContainer)
        └── PostConnectBox (instance)
```

### Instancing tip
To instance a scene as a child of the current scene: drag the `.tscn` file from FileSystem dock into the Scene tree at the right spot. Then in Inspector, edit the exports on that instance to configure it (e.g. each Socket's `socket_key` and `label_text`).

### Wiring (in `call_director.gd`)

Replace the body of `call_director.gd` with this presenter-enabled version (we already wrote the director logic; this adds the glue):

```gdscript
extends Node

signal call_started(call_data: CallData)
signal call_resolved(success: bool, call_data: CallData)
signal all_calls_finished()

@export var calls: Array[CallData] = []

@export_node_path("CallerCard") var caller_card_path
@export_node_path("PostConnectBox") var post_connect_path
@export_node_path("HBoxContainer") var patience_path

@onready var caller_card: CallerCard = get_node(caller_card_path)
@onready var post_box: PostConnectBox = get_node(post_connect_path)
@onready var patience_container: HBoxContainer = get_node(patience_path)

const DEFAULT_LIT := [&"hayes", &"doc", &"sheriff", &"reverend", &"patty", &"cole"]

var _current: CallData

func _ready() -> void:
    GameState.reset()
    GameState.patience_changed.connect(_on_patience_changed)
    post_box.finished.connect(_start_next)
    for socket in get_tree().get_nodes_in_group("sockets"):
        socket.cable_plugged.connect(_on_socket_plugged)
    _start_next()

func _start_next() -> void:
    var idx := GameState.current_call_index
    if idx >= calls.size():
        all_calls_finished.emit()
        GameState.end_game(true)
        return
    _current = calls[idx]
    _apply_lit_state(_current)
    caller_card.show_call(_current)
    call_started.emit(_current)

func _apply_lit_state(c: CallData) -> void:
    var lit_keys := c.sockets_lit if not c.sockets_lit.is_empty() else DEFAULT_LIT
    for socket in get_tree().get_nodes_in_group("sockets"):
        socket.lit = socket.socket_key in lit_keys

func _on_socket_plugged(socket_key: StringName) -> void:
    if _current == null:
        return
    var success := socket_key == _current.correct_socket
    call_resolved.emit(success, _current)
    if success:
        GameState.advance_call()
        post_box.play(_current.post_connect_lines)
        # _start_next() is triggered by post_box.finished
    else:
        if _current.pivotal:
            GameState.end_game(false)
        else:
            GameState.lose_patience()

func _on_patience_changed(value: int) -> void:
    for i in patience_container.get_child_count():
        patience_container.get_child(i).visible = i < value
```

Then in the editor, on the `Switchboard` root's Inspector, set:
- `Caller Card Path` → the CallerCard instance
- `Post Connect Path` → the PostConnectBox instance
- `Patience Path` → the Patience HBoxContainer

---

## 7. Listening for the ending

Add this to `_ready()` of the Switchboard root (after the existing connections):

```gdscript
GameState.game_ended.connect(_on_game_ended)
```

And add:

```gdscript
func _on_game_ended(good: bool) -> void:
    var path := "res://scenes/ending_good.tscn" if good else "res://scenes/ending_bad.tscn"
    get_tree().change_scene_to_file(path)
```

---

## 8. Title + endings

- `scenes/title.tscn`: `Control` root, `Label` title, `Button` "Start" → `change_scene_to_file("res://scenes/switchboard.tscn")`.
- `scenes/ending_good.tscn` and `scenes/ending_bad.tscn`: each just a `Control` with a `Label` for the closing text and a "Play again" button → back to title.

Set `title.tscn` as Main Scene: Project → Project Settings → Application → Run → Main Scene.

---

## 9. Smoke test (end of Day 1)

1. Instance two `CallData.tres` files with placeholder text into `CallDirector.calls`.
2. Run. Call 1 text appears in the CallerCard.
3. Drag cable from jack to a Socket. Wrong → patience light disappears. Right → post-connect text plays, then call 2 loads.
4. Lose 3 patience → ending_bad scene loads.
5. Win both calls (when you only have 2) → ending_good scene loads.

If steps 1–5 pass, **Day 1 is done.** Everything from here is content (the 10 `.tres` files) and dressing (art, sfx, shader).
