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

const _LABEL_ON := "[X]  Manual dialogue advance"
const _LABEL_OFF := "[  ]  Manual dialogue advance"

@onready var _manual_toggle: Button = $Center/Panel/VBox/ManualAdvanceToggle
@onready var _back_button: Button = $Center/Panel/VBox/BackButton

func _ready() -> void:
	visible = false
	_manual_toggle.toggle_mode = true
	if SettingsState:
		_manual_toggle.button_pressed = SettingsState.manual_dialogue
	_refresh_toggle_label()
	_manual_toggle.toggled.connect(_on_manual_toggled)
	_back_button.pressed.connect(close)

func open() -> void:
	if SettingsState:
		_manual_toggle.button_pressed = SettingsState.manual_dialogue
	_refresh_toggle_label()
	visible = true
	_back_button.grab_focus()
	opened.emit()

func close() -> void:
	visible = false
	closed.emit()

func _on_manual_toggled(pressed: bool) -> void:
	if SettingsState:
		SettingsState.manual_dialogue = pressed
	_refresh_toggle_label()

func _refresh_toggle_label() -> void:
	_manual_toggle.text = _LABEL_ON if _manual_toggle.button_pressed else _LABEL_OFF

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()
