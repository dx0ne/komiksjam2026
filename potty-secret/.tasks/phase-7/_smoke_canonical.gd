## Smoke test for phase-7 canonical data model.
## Run from potty-secret/ directory with:
##   D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe --headless --script .tasks/phase-7/_smoke_canonical.gd
##
## This is a standalone script — it does NOT require a running scene.
## WordManager is loaded directly as a script resource and instantiated.

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

func _assert_not_eq(label: String, got: Variant, not_expected: Variant) -> void:
	if got != not_expected:
		print("[PASS] %s" % label)
		_pass_count += 1
	else:
		push_error("[FAIL] %s — value should NOT be %s" % [label, str(not_expected)])
		_fail_count += 1

func _assert_true(label: String, value: bool) -> void:
	if value:
		print("[PASS] %s" % label)
		_pass_count += 1
	else:
		push_error("[FAIL] %s — expected true" % label)
		_fail_count += 1

func _init() -> void:
	var wm: Node = load("res://WordManager.gd").new()

	# -------------------------------------------------------------------------
	# canonicalize tests
	# -------------------------------------------------------------------------

	# Uppercase input resolves to canonical (case-insensitive lookup)
	var c_aliens: String = wm.canonicalize("ALIENS")
	_assert_eq("canonicalize('ALIENS') returns 'aliens'", c_aliens, "aliens")

	# Typo lookup
	var c_typo: String = wm.canonicalize("allens")
	_assert_eq("canonicalize('allens') returns 'aliens'", c_typo, "aliens")

	# Synonym lookup
	var c_syn: String = wm.canonicalize("them")
	_assert_eq("canonicalize('them') returns 'aliens'", c_syn, "aliens")

	# Unknown word returns empty string
	var c_none: String = wm.canonicalize("not-a-word")
	_assert_eq("canonicalize('not-a-word') returns ''", c_none, "")

	# -------------------------------------------------------------------------
	# display_variants tests
	# -------------------------------------------------------------------------

	# TYPO mode returns array of length >= 1 and does NOT contain the canonical itself
	var typo_variants: Array = wm.display_variants("aliens", wm.VariantMode.TYPO)
	_assert_true("display_variants('aliens', TYPO) has length >= 1", typo_variants.size() >= 1)
	_assert_not_eq("display_variants('aliens', TYPO) first item is not the canonical", typo_variants[0], "aliens")

	# CANONICAL mode returns exactly [canonical]
	var canon_variants: Array = wm.display_variants("aliens", wm.VariantMode.CANONICAL)
	var expected_canonical: Array = ["aliens"]
	_assert_eq("display_variants('aliens', CANONICAL) returns ['aliens']", canon_variants, expected_canonical)

	# SYNONYM mode returns array of length >= 1 and does NOT contain the canonical
	var syn_variants: Array = wm.display_variants("aliens", wm.VariantMode.SYNONYM)
	_assert_true("display_variants('aliens', SYNONYM) has length >= 1", syn_variants.size() >= 1)
	_assert_not_eq("display_variants('aliens', SYNONYM) first item is not the canonical", syn_variants[0], "aliens")

	# TYPO_OR_SYNONYM mode combines both pools
	var mixed_variants: Array = wm.display_variants("aliens", wm.VariantMode.TYPO_OR_SYNONYM)
	_assert_true("display_variants('aliens', TYPO_OR_SYNONYM) has length >= 2", mixed_variants.size() >= 2)

	# Unknown canonical returns []
	var unknown_variants: Array = wm.display_variants("not-a-word", wm.VariantMode.CANONICAL)
	var expected_empty: Array = []
	_assert_eq("display_variants('not-a-word', CANONICAL) returns []", unknown_variants, expected_empty)

	# -------------------------------------------------------------------------
	# pick_random_canonicals tests
	# -------------------------------------------------------------------------

	var picks: Array = wm.pick_random_canonicals(5)
	_assert_true("pick_random_canonicals(5) returns 5 items", picks.size() == 5)

	# All picks are valid canonicals (canonicalize(pick) == pick)
	var all_valid := true
	for p in picks:
		var c: String = wm.canonicalize(p)
		if c != p:
			all_valid = false
			break
	_assert_true("pick_random_canonicals all results are valid canonicals", all_valid)

	# No duplicates
	var seen := {}
	var no_dupes := true
	for p in picks:
		if seen.has(p):
			no_dupes = false
			break
		seen[p] = true
	_assert_true("pick_random_canonicals returns distinct values", no_dupes)

	# -------------------------------------------------------------------------
	# Summary
	# -------------------------------------------------------------------------

	print("")
	if _fail_count == 0:
		print("phase-7 canonical smoke test OK (%d passed)" % _pass_count)
		quit(0)
	else:
		push_error("phase-7 canonical smoke test FAILED: %d passed, %d failed" % [_pass_count, _fail_count])
		quit(1)
