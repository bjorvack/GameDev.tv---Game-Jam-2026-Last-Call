## Headless verifier: loads every CallData .tres and prints whether its
## caller_portrait was successfully resolved. Run via:
##   godot --headless --script tools/_verify_portraits.gd
extends SceneTree

func _initialize() -> void:
	var dir := DirAccess.open("res://data/calls")
	var ok := 0
	var missing := 0
	for f in dir.get_files():
		if not f.ends_with(".tres"):
			continue
		var path := "res://data/calls/" + f
		var res := load(path) as CallData
		if res == null:
			push_error("Failed to load %s" % path)
			continue
		var has_portrait := res.caller_portrait != null
		print("  %s  caller=%s  portrait=%s" % [f, res.caller_name, "✓" if has_portrait else "—"])
		if has_portrait:
			ok += 1
		else:
			missing += 1
	print("\n%d with portrait, %d without (Tier 2 callers expected)" % [ok, missing])
	quit()
