## In-game pause overlay. Esc opens / closes it.
##
## Pauses the SceneTree while open so the patience clock, dialogue waits and
## the call director all freeze. Three buttons: Resume, Settings (opens the
## shared SettingsOverlay), and Back to title. The settings panel is the
## same component used on the title screen so the look stays unified.
extends CanvasLayer

const TITLE_SCENE := "res://scenes/title.tscn"

@onready var _menu: Control = $Menu
@onready var _resume_button: Button = $Menu/Center/Panel/VBox/ResumeButton
@onready var _settings_button: Button = $Menu/Center/Panel/VBox/SettingsButton
@onready var _title_button: Button = $Menu/Center/Panel/VBox/TitleButton
@onready var _settings_overlay: Control = $SettingsOverlay

func _ready() -> void:
	# Keep processing input + button presses while the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_menu.visible = false
	_resume_button.pressed.connect(close)
	_settings_button.pressed.connect(_settings_overlay.open)
	_title_button.pressed.connect(_on_back_to_title)
	_settings_overlay.opened.connect(_on_settings_opened)
	_settings_overlay.closed.connect(_on_settings_closed)
	# Resume = forward (back into the game); Settings = forward (deeper
	# into menus); Back to title = back (out of the run).
	_resume_button.pressed.connect(UiAudio.play_click)
	_settings_button.pressed.connect(UiAudio.play_click)
	_title_button.pressed.connect(UiAudio.play_back)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		# If the nested settings panel is open, let it consume the Escape
		# (its own _unhandled_input closes it). We only act when the panel
		# is hidden, so Esc on the pause menu itself toggles pause.
		if _settings_overlay.visible:
			return
		get_viewport().set_input_as_handled()
		if _menu.visible:
			close()
		else:
			open()

func open() -> void:
	_menu.visible = true
	get_tree().paused = true
	_resume_button.grab_focus()

func close() -> void:
	_menu.visible = false
	_settings_overlay.visible = false
	get_tree().paused = false

func _on_settings_opened() -> void:
	_menu.visible = false

func _on_settings_closed() -> void:
	_menu.visible = true
	_resume_button.grab_focus()

func _on_back_to_title() -> void:
	# Unpause before swapping scenes — the new tree must run normally.
	get_tree().paused = false
	_menu.visible = false
	_settings_overlay.visible = false
	if SceneTransition:
		SceneTransition.change_scene(TITLE_SCENE)
	else:
		get_tree().change_scene_to_file(TITLE_SCENE)
