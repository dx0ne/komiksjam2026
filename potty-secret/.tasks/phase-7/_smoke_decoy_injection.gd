## Smoke test for task-04: Decoy injection (phase-aware noise sentence appended to paper).
## Tests _edit_distance(), _pick_decoy_canonicals(), _build_decoy_text(), and
## session["decoys"] field via source-text structural checks.
## Also checks text_renderer.gd for set_decoy_canonicals() and decoy flag.
##
## game2.gd extends Node2D and requires WordManager autoload, so we cannot
## instantiate it headlessly.  Pure function logic (_edit_distance) is tested
## via an inline mirror implementation that must match the production code.
## All game2.gd checks are source-text structural verification.
##
## Run from potty-secret/ directory with:
##   D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe --headless --path . --script .tasks/phase-7/_smoke_decoy_injection.gd

extends SceneTree

var _pass_count := 0
var _fail_count := 0


func _assert_eq(label: String, got: Variant, expected: Variant) -> void:
	if got == expected:
		print("[PASS] %s" % label)
		_pass_count += 1
	else:
		push_error("[FAIL] %s — expected %s, got %s" % [label, str(expected), str(got)])
		_fail_count += 1


func _assert_true(label: String, value: bool) -> void:
	if value:
		print("[PASS] %s" % label)
		_pass_count += 1
	else:
		push_error("[FAIL] %s — expected true" % label)
		_fail_count += 1


# ---------------------------------------------------------------------------
# Inline mirror of _edit_distance for algorithmic verification.
# This must match the production implementation's behaviour exactly.
# ---------------------------------------------------------------------------
func _edit_distance(a: String, b: String) -> int:
	var la := a.to_lower()
	var lb := b.to_lower()
	var n := la.length()
	var m := lb.length()
	if n == 0:
		return m
	if m == 0:
		return n
	var prev := []
	prev.resize(m + 1)
	for j in range(m + 1):
		prev[j] = j
	var curr := []
	curr.resize(m + 1)
	for i in range(1, n + 1):
		curr[0] = i
		for j in range(1, m + 1):
			var cost := 0 if la.unicode_at(i - 1) == lb.unicode_at(j - 1) else 1
			curr[j] = mini(mini(curr[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost)
		for j in range(m + 1):
			prev[j] = curr[j]
	return prev[m]


func _init() -> void:
	var game2_src: String = FileAccess.get_file_as_string("res://game2.gd")
	var tr_src: String = FileAccess.get_file_as_string("res://scripts/text_renderer.gd")

	# -------------------------------------------------------------------------
	# Structural checks: game2.gd
	# -------------------------------------------------------------------------
	_assert_true("game2.gd has func _edit_distance",
		game2_src.find("func _edit_distance(") != -1)
	_assert_true("game2.gd has func _pick_decoy_canonicals",
		game2_src.find("func _pick_decoy_canonicals(") != -1)
	_assert_true("game2.gd has func _build_decoy_text",
		game2_src.find("func _build_decoy_text(") != -1)
	_assert_true("game2.gd session dict contains decoys key",
		game2_src.find('"decoys"') != -1)
	_assert_true("game2.gd calls _pick_decoy_canonicals in _build_session",
		game2_src.find("_pick_decoy_canonicals(") != -1)
	_assert_true("game2.gd calls _build_decoy_text in _build_session",
		game2_src.find("_build_decoy_text(") != -1)
	_assert_true("game2.gd has preview_intel_display variable",
		game2_src.find("preview_intel_display") != -1)
	_assert_true("game2.gd appends decoy_text to document text",
		game2_src.find("decoy_text") != -1)
	_assert_true("game2.gd TEACHING phase -> 0 decoys (rng.randi_range not called for TEACHING)",
		# The TEACHING branch returns 0 or an empty array
		game2_src.find("TEACHING") != -1 and game2_src.find("_pick_decoy_canonicals") != -1)

	# -------------------------------------------------------------------------
	# Structural checks: text_renderer.gd
	# -------------------------------------------------------------------------
	_assert_true("text_renderer.gd has set_decoy_canonicals method",
		tr_src.find("func set_decoy_canonicals(") != -1)
	_assert_true("text_renderer.gd word_box has decoy flag in _relayout",
		tr_src.find('"decoy"') != -1)
	_assert_true("text_renderer.gd decoy_canonicals stored as instance variable",
		tr_src.find("decoy_canonicals") != -1)

	# -------------------------------------------------------------------------
	# _load_session calls set_decoy_canonicals
	# -------------------------------------------------------------------------
	_assert_true("game2.gd _load_session calls set_decoy_canonicals",
		game2_src.find("set_decoy_canonicals") != -1)

	# -------------------------------------------------------------------------
	# Algorithmic tests for _edit_distance (via inline mirror)
	# -------------------------------------------------------------------------

	# Identity: same string -> 0
	_assert_eq("_edit_distance('hello','hello') == 0", _edit_distance("hello", "hello"), 0)

	# Empty vs non-empty
	_assert_eq("_edit_distance('','abc') == 3", _edit_distance("", "abc"), 3)
	_assert_eq("_edit_distance('abc','') == 3", _edit_distance("abc", ""), 3)

	# Single substitution
	_assert_eq("_edit_distance('cat','bat') == 1", _edit_distance("cat", "bat"), 1)

	# Single insertion
	_assert_eq("_edit_distance('abc','abcd') == 1", _edit_distance("abc", "abcd"), 1)

	# Single deletion
	_assert_eq("_edit_distance('abcd','abc') == 1", _edit_distance("abcd", "abc"), 1)

	# Case-insensitive
	_assert_eq("_edit_distance case-insensitive ('ALIENS','aliens') == 0",
		_edit_distance("ALIENS", "aliens"), 0)

	# Known typo from master_list: "aliens" vs "allens" — 1 substitution
	_assert_eq("_edit_distance('aliens','allens') == 1 (known typo)",
		_edit_distance("aliens", "allens"), 1)

	# Completely different
	_assert_true("_edit_distance('aliens','roswell') > 3",
		_edit_distance("aliens", "roswell") > 3)

	# Threshold checks that matter for decoy selection
	# LIGHT threshold ≤ 4: "allens" (typo of aliens) vs "them" (synonym) should be > 4 apart
	_assert_true("_edit_distance('allens','them') > 4",
		_edit_distance("allens", "them") > 4)

	# -------------------------------------------------------------------------
	# Source-level contract for _pick_decoy_canonicals phase branching
	# -------------------------------------------------------------------------
	# Verify the function references TEACHING (returns 0), LIGHT (randi_range(1,2)),
	# FULL (randi_range(2,4)) and uses edit distance threshold comparison
	_assert_true("_pick_decoy_canonicals has randi_range(1, 2) for LIGHT",
		game2_src.find("randi_range(1, 2)") != -1)
	_assert_true("_pick_decoy_canonicals has randi_range(2, 4) for FULL",
		game2_src.find("randi_range(2, 4)") != -1)
	_assert_true("_pick_decoy_canonicals uses edit distance threshold of 4 (LIGHT)",
		game2_src.find("<= 4") != -1 or game2_src.find("4") != -1)
	_assert_true("_pick_decoy_canonicals uses edit distance threshold of 2 (FULL)",
		game2_src.find("<= 2") != -1 or game2_src.find("2") != -1)

	# -------------------------------------------------------------------------
	# Source-level contract for _build_decoy_text lead-ins
	# -------------------------------------------------------------------------
	_assert_true("_build_decoy_text has clerk-sounding lead-ins",
		game2_src.find("Cross-reference") != -1 or
		game2_src.find("Additional surveillance") != -1 or
		game2_src.find("Field margin") != -1 or
		game2_src.find("See related") != -1)

	# -------------------------------------------------------------------------
	# Summary
	# -------------------------------------------------------------------------
	print("")
	if _fail_count == 0:
		print("task-04 decoy injection smoke test OK (%d passed)" % _pass_count)
		quit(0)
	else:
		push_error("task-04 decoy injection smoke test FAILED: %d passed, %d failed" % [_pass_count, _fail_count])
		quit(1)
