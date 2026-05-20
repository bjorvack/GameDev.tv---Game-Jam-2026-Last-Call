## Headless verifier: loads every CallData .tres and prints whether its
## caller_portrait + per-line speaker portraits resolved correctly.
## Run via:
##   godot --headless --script tools/_verify_portraits.gd
extends SceneTree

func _count_line_portraits(lines: Array, accum: Dictionary) -> void:
	for line in lines:
		if line == null:
			continue
		if line.portrait != null:
			accum["with"] = accum.get("with", 0) + 1
		elif line.speaker != "" and line.speaker != "???":
			accum["without"] = accum.get("without", 0) + 1

func _initialize() -> void:
	var dir := DirAccess.open("res://data/calls")
	var calls_with := 0
	var calls_without := 0
	var line_totals := {"with": 0, "without": 0}
	for f in dir.get_files():
		if not f.ends_with(".tres"):
			continue
		var path := "res://data/calls/" + f
		var res := load(path) as CallData
		if res == null:
			push_error("Failed to load %s" % path)
			continue
		var has_portrait := res.caller_portrait != null
		var per_call := {"with": 0, "without": 0}
		_count_line_portraits(res.opening, per_call)
		_count_line_portraits(res.connected_dialogue, per_call)
		_count_line_portraits(res.generic_wrong_response, per_call)
		_count_line_portraits(res.timer_expired, per_call)
		for k in res.wrong_responses:
			_count_line_portraits(res.wrong_responses[k], per_call)
		print("  %s  caller=%s  default=%s  line_overrides=%d (+%d unportraited)" % [
			f, res.caller_name,
			"✓" if has_portrait else "—",
			per_call.get("with", 0),
			per_call.get("without", 0),
		])
		if has_portrait: calls_with += 1
		else: calls_without += 1
		line_totals["with"] += per_call.get("with", 0)
		line_totals["without"] += per_call.get("without", 0)
	print("\n%d/%d calls with default portrait" % [calls_with, calls_with + calls_without])
	print("%d per-line overrides set, %d speaker lines still un-portraited (Tier 2)" % [
		line_totals["with"], line_totals["without"],
	])
	quit()
