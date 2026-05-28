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

@onready var _tabs: TabContainer = $Center/Panel/VBox/Tabs
@onready var _manual_toggle: Button = $Center/Panel/VBox/Tabs/Accessibility/ManualGroup/ManualAdvanceToggle
@onready var _cursor_toggle: Button = $Center/Panel/VBox/Tabs/Accessibility/CursorGroup/SystemCursorToggle
@onready var _audio_grid: GridContainer = $Center/Panel/VBox/Tabs/Audio/AudioGrid
@onready var _audio_reset_button: Button = $Center/Panel/VBox/Tabs/Audio/ResetRow/ResetButton
@onready var _back_button: Button = $Center/Panel/VBox/BackButton

## Per-bus value labels, keyed by bus name. Rebuilt every time the audio
## grid is populated so opening the overlay reflects the live state even
## if volumes were changed elsewhere (e.g. a future hotkey).
var _value_labels: Dictionary = {}

func _ready() -> void:
	visible = false
	_manual_toggle.toggle_mode = true
	_cursor_toggle.toggle_mode = true
	# Friendly tab titles override the raw child node names.
	_tabs.set_tab_title(0, "Accessibility")
	_tabs.set_tab_title(1, "Audio")
	_tabs.tab_changed.connect(_on_tab_changed)
	_build_audio_rows()
	_sync_from_settings()
	_manual_toggle.toggled.connect(_on_manual_toggled)
	_cursor_toggle.toggled.connect(_on_cursor_toggled)
	_back_button.pressed.connect(close)
	# Toggles get a state-aware click (pitched up for ON, down for OFF);
	# Back is a back-style press (pitched down click).
	_manual_toggle.toggled.connect(UiAudio.play_toggle)
	_cursor_toggle.toggled.connect(UiAudio.play_toggle)
	_back_button.pressed.connect(UiAudio.play_back)
	_audio_reset_button.pressed.connect(_on_audio_reset_pressed)
	_audio_reset_button.pressed.connect(UiAudio.play_click)

func open() -> void:
	_sync_from_settings()
	# Reset to the first tab on every open so the panel reads consistently
	# regardless of where the player last left it.
	_tabs.current_tab = 0
	visible = true
	_back_button.grab_focus()
	opened.emit()

func _on_tab_changed(_index: int) -> void:
	UiAudio.play_click()

## Restore every audio bus to its baseline volume and refresh the slider
## row so the user sees the snap-back. SettingsState.reset_volumes()
## writes through set_volume() per bus, so the AudioServer + config file
## stay in sync without any extra plumbing here.
func _on_audio_reset_pressed() -> void:
	if SettingsState == null:
		return
	SettingsState.reset_volumes()
	_sync_audio_rows()

func close() -> void:
	visible = false
	closed.emit()

func _sync_from_settings() -> void:
	if SettingsState:
		_manual_toggle.button_pressed = SettingsState.manual_dialogue
		_cursor_toggle.button_pressed = SettingsState.use_system_cursor
	_refresh_toggle_labels()
	_sync_audio_rows()

## Builds one row per audio bus: [Label] [HSlider] [value %]. Driven by
## SettingsState.BUSES so adding a new bus only requires updating the
## autoload's constant — the settings UI follows automatically.
func _build_audio_rows() -> void:
	if SettingsState == null:
		return
	# Wipe any pre-existing children (defensive — supports hot-reload in
	# the editor).
	for child in _audio_grid.get_children():
		child.queue_free()
	_value_labels.clear()
	for bus_name in SettingsState.BUSES:
		var name_label := Label.new()
		name_label.text = String(bus_name)
		name_label.custom_minimum_size = Vector2(80, 0)
		_audio_grid.add_child(name_label)

		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.01
		slider.custom_minimum_size = Vector2(240, 0)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		# Bind the bus name into the connection so one handler covers
		# every slider — no per-row closures or lambdas needed.
		slider.value_changed.connect(_on_volume_changed.bind(bus_name))
		_audio_grid.add_child(slider)

		var value_label := Label.new()
		value_label.custom_minimum_size = Vector2(56, 0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_audio_grid.add_child(value_label)
		# Stash the pair so _sync_audio_rows can refresh without rebuilding.
		_value_labels[bus_name] = {"slider": slider, "label": value_label}

func _sync_audio_rows() -> void:
	if SettingsState == null:
		return
	for bus_name in _value_labels:
		var row: Dictionary = _value_labels[bus_name]
		var slider: HSlider = row["slider"]
		var value: float = SettingsState.get_volume(bus_name)
		# set_value_no_signal to avoid bouncing back through set_volume
		# (which would mark the cfg dirty + emit volume_changed again).
		slider.set_value_no_signal(value)
		_refresh_value_label(bus_name, value)

func _on_volume_changed(value: float, bus_name: StringName) -> void:
	if SettingsState:
		SettingsState.set_volume(bus_name, value)
	_refresh_value_label(bus_name, value)

func _refresh_value_label(bus_name: StringName, value: float) -> void:
	var row = _value_labels.get(bus_name)
	if row == null:
		return
	(row["label"] as Label).text = "%d%%" % int(round(value * 100.0))

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
