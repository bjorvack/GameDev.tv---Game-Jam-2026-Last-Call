## Per-call urgency timer. Visible only when a CallData specifies time_limit > 0.
## Counts down and emits `expired` when it hits zero.
class_name CallTimer
extends PanelContainer

signal expired

@onready var label: Label = $VBoxContainer/Label
@onready var bar: ProgressBar = $VBoxContainer/ProgressBar

var _remaining: float = 0.0
var _total: float = 0.0
var _running: bool = false

func _ready() -> void:
	hide()
	set_process(false)

func start(seconds: float) -> void:
	_total = seconds
	_remaining = seconds
	_running = true
	bar.max_value = seconds
	bar.value = seconds
	_update_label()
	show()
	set_process(true)

func stop() -> void:
	_running = false
	set_process(false)
	hide()

func _process(delta: float) -> void:
	if not _running:
		return
	_remaining = maxf(0.0, _remaining - delta)
	bar.value = _remaining
	_update_label()
	if _remaining <= 0.0:
		_running = false
		set_process(false)
		expired.emit()

func _update_label() -> void:
	label.text = "%0.1fs" % _remaining
