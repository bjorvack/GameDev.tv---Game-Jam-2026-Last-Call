## Shared settings panel. Embedded in both the title screen and the in-game
## pause overlay so the two surfaces stay visually identical. Exposes the
## current accessibility toggles and emits `closed` when the user backs out.
##
## Usage:
##   var settings := preload("res://components/settings_overlay.tscn").instantiate()
##   add_child(settings)
##   settings.closed.connect(_on_settings_closed)
##   settings.open()
##
## Or instance directly in a scene and call `open()` / `close()` from the
## parent menu's button handlers.
extends Control

signal opened
signal closed

const _MANUAL_ON := "[X]  Manual dialogue advance"
const _MANUAL_OFF := "[  ]  Manual dialogue advance"
const _CURSOR_ON := "[X]  Use system cursor"
const _CURSOR_OFF := "[  ]  Use system cursor"

@onready var _manual_toggle: Button = $Center/Panel/VBox/ManualAdvanceToggle
@onready var _cursor_toggle: Button = $Center/Panel/VBox/SystemCursorToggle
@onready var _back_button: Button = $Center/Panel/VBox/BackButton

func _ready() -> void:
	visible = false
	_manual_toggle.toggle_mode = true
	_cursor_toggle.toggle_mode = true
	_sync_from_settings()
	_manual_toggle.toggled.connect(_on_manual_toggled)
	_cursor_toggle.toggled.connect(_on_cursor_toggled)
	_back_button.pressed.connect(close)
	# Toggles get a state-aware click (pitched up for ON, down for OFF);
	# Back is a back-style press (pitched down click).
	_manual_toggle.toggled.connect(UiAudio.play_toggle)
	_cursor_toggle.toggled.connect(UiAudio.play_toggle)
	_back_button.pressed.connect(UiAudio.play_back)

func open() -> void:
	_sync_from_settings()
	visible = true
	_back_button.grab_focus()
	opened.emit()

func close() -> void:
	visible = false
	closed.emit()

func _sync_from_settings() -> void:
	if SettingsState:
		_manual_toggle.button_pressed = SettingsState.manual_dialogue
		_cursor_toggle.button_pressed = SettingsState.use_system_cursor
	_refresh_toggle_labels()

func _on_manual_toggled(pressed: bool) -> void:
	if SettingsState:
		SettingsState.manual_dialogue = pressed
	_refresh_toggle_labels()

func _on_cursor_toggled(pressed: bool) -> void:
	if SettingsState:
		SettingsState.use_system_cursor = pressed
	_refresh_toggle_labels()

func _refresh_toggle_labels() -> void:
	_manual_toggle.text = _MANUAL_ON if _manual_toggle.button_pressed else _MANUAL_OFF
	_cursor_toggle.text = _CURSOR_ON if _cursor_toggle.button_pressed else _CURSOR_OFF

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
