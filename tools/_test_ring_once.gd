## Per-scene verifier for AudioManager.play_ring_once().
## Attach to a one-off Node2D and set that as the main scene with:
##   godot --headless --quit-after 30 --main-scene res://tools/_test_ring_once.tscn
extends Node

func _ready() -> void:
	await get_tree().process_frame
	for i in 3:
		var dur := randf_range(1.0, 2.0)
		var t0 := Time.get_ticks_msec()
		print("[Test] call %d  requested=%.2fs" % [i + 1, dur])
		await AudioManager.play_ring_once(dur)
		var elapsed_ms := Time.get_ticks_msec() - t0
		var still_playing: bool = AudioManager.ring_player.playing
		print(
			"[Test] call %d  elapsed=%.2fs  ring_player.playing=%s" % [
				i + 1, elapsed_ms / 1000.0, still_playing,
			]
		)
		var requested_ms := int(dur * 1000.0)
		var within_lower := elapsed_ms >= requested_ms - 50
		var within_upper := elapsed_ms <= requested_ms + 300
		print(
			"[Test] call %d  within_bounds=%s (%d ms vs %d ms)" % [
				i + 1, within_lower and within_upper, elapsed_ms, requested_ms,
			]
		)
	print("[Test] OK")
	get_tree().quit(0)
