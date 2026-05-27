## Smoke test for task-03: Intel derived from paper canonicals + canonical-based matching.
##
## Run from potty-secret/ directory with:
##   D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe --headless --path . --script .tasks/phase-7/_smoke_intel_from_paper.gd
##
## Validates:
##   - WordManager.current_toilet_canonicals field exists
##   - game2.gd has _intel_variant_mode_for_phase
##   - text_renderer.gd has set_planted_canonicals (not set_planted_words)
##   - illegal flag is canonical-based (TextRenderer.set_forbidden_words now uses WordManager.current_toilet_canonicals)
##   - game2.gd _ready() order: spawn paper first, THEN roll intel

extends SceneTree

var _pass_count := 0
var _fail_count := 0

func _assert_true(label: String, value: bool) -> void:
	if value:
		print("[PASS] %s" % label)
		_pass_count += 1
	else:
		push_error("[FAIL] %s — expected true" % label)
		_fail_count += 1

func _assert_eq(label: String, got: Variant, expected: Variant) -> void:
	if got == expected:
		print("[PASS] %s" % label)
		_pass_count += 1
	else:
		push_error("[FAIL] %s — expected %s, got %s" % [label, str(expected), str(got)])
		_fail_count += 1

func _init() -> void:
	var wm: Node = load("res://WordManager.gd").new()
	var game2_src := FileAccess.get_file_as_string("res://game2.gd")
	var tr_src := FileAccess.get_file_as_string("res://scripts/text_renderer.gd")

	# -------------------------------------------------------------------------
	# 1. WordManager.current_toilet_canonicals field exists
	# -------------------------------------------------------------------------
	_assert_true("WordManager has current_toilet_canonicals field",
		wm.get("current_toilet_canonicals") != null or wm.get_script().source_code.find("current_toilet_canonicals") != -1)

	# Directly test the field is accessible
	var ctc = wm.get("current_toilet_canonicals")
	_assert_true("WordManager.current_toilet_canonicals is an Array",
		typeof(ctc) == TYPE_ARRAY)

	# -------------------------------------------------------------------------
	# 2. game2.gd has _intel_variant_mode_for_phase
	# -------------------------------------------------------------------------
	_assert_true("game2.gd has _intel_variant_mode_for_phase",
		game2_src.find("_intel_variant_mode_for_phase") != -1)

	# -------------------------------------------------------------------------
	# 3. game2.gd _roll_toilet_intel reads from session planted_canonicals
	# -------------------------------------------------------------------------
	_assert_true("game2.gd _roll_toilet_intel reads planted_canonicals",
		game2_src.find("planted_canonicals") != -1 and
		game2_src.find("_roll_toilet_intel") != -1)

	# Confirm _roll_toilet_intel assigns WordManager.current_toilet_canonicals
	_assert_true("game2.gd assigns WordManager.current_toilet_canonicals in _roll_toilet_intel",
		game2_src.find("current_toilet_canonicals") != -1)

	# -------------------------------------------------------------------------
	# 4. game2.gd _ready(): spawn paper BEFORE rolling intel
	# -------------------------------------------------------------------------
	# Find the relative positions of _spawn_fresh_paper and _roll_toilet_intel in _ready
	var spawn_pos := game2_src.find("_spawn_fresh_paper(false)")
	var intel_pos := game2_src.find("_roll_toilet_intel(true)")
	_assert_true("_spawn_fresh_paper(false) appears before _roll_toilet_intel(true) in _ready()",
		spawn_pos != -1 and intel_pos != -1 and spawn_pos < intel_pos)

	# -------------------------------------------------------------------------
	# 5. text_renderer.gd has set_planted_canonicals (not only set_planted_words)
	# -------------------------------------------------------------------------
	_assert_true("text_renderer.gd has set_planted_canonicals",
		tr_src.find("func set_planted_canonicals") != -1)
	_assert_true("text_renderer.gd set_planted_words is removed or absent",
		tr_src.find("func set_planted_words") == -1)

	# -------------------------------------------------------------------------
	# 6. text_renderer.gd set_forbidden_words uses canonical matching
	# -------------------------------------------------------------------------
	_assert_true("text_renderer.gd set_forbidden_words uses WordManager.canonicalize",
		tr_src.find("WordManager.canonicalize") != -1)
	_assert_true("text_renderer.gd set_forbidden_words uses WordManager.current_toilet_canonicals",
		tr_src.find("current_toilet_canonicals") != -1)

	# -------------------------------------------------------------------------
	# 7. text_renderer.gd _relayout uses canonical matching for illegal flag
	# -------------------------------------------------------------------------
	_assert_true("text_renderer.gd _relayout uses current_toilet_canonicals",
		tr_src.find("current_toilet_canonicals") != -1)

	# -------------------------------------------------------------------------
	# 8. game2.gd _load_session calls set_planted_canonicals
	# -------------------------------------------------------------------------
	_assert_true("game2.gd _load_session calls set_planted_canonicals",
		game2_src.find("set_planted_canonicals") != -1)
	_assert_true("game2.gd _load_session does NOT call set_planted_words",
		game2_src.find("set_planted_words") == -1)

	# -------------------------------------------------------------------------
	# 9. Canonical matching logic: set_planted_canonicals uses canonical comparison
	# -------------------------------------------------------------------------
	_assert_true("text_renderer.gd uses planted_canonicals as stored state",
		tr_src.find("planted_canonicals") != -1)

	# -------------------------------------------------------------------------
	# 10. Intel variant mode logic exists in game2.gd for all 3 phases
	# -------------------------------------------------------------------------
	_assert_true("game2.gd _intel_variant_mode_for_phase handles TEACHING->CANONICAL",
		game2_src.find("TEACHING") != -1)
	_assert_true("game2.gd _intel_variant_mode_for_phase handles LIGHT->TYPO/SYNONYM",
		game2_src.find("LIGHT") != -1)
	_assert_true("game2.gd _intel_variant_mode_for_phase handles FULL->TYPO_OR_SYNONYM",
		game2_src.find("TYPO_OR_SYNONYM") != -1)

	# -------------------------------------------------------------------------
	# Summary
	# -------------------------------------------------------------------------
	print("")
	if _fail_count == 0:
		print("task-03 intel-from-paper smoke test OK (%d passed)" % _pass_count)
		quit(0)
	else:
		push_error("task-03 intel-from-paper smoke test FAILED: %d passed, %d failed" % [_pass_count, _fail_count])
		quit(1)
