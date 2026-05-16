class_name RedactionCoverage

const SAMPLE_STEP := 6.0
const COVERAGE_CELL_WIDTH := 8.0
const COVERAGE_HALF_RATIO := 0.50
const COVERAGE_FULL_RATIO := 0.70
const COVERAGE_MIN_CELLS := 2


static func sample_stroke(stroke: PackedVector2Array) -> PackedVector2Array:
	var samples := PackedVector2Array()
	for index in range(stroke.size() - 1):
		var start := stroke[index]
		var end := stroke[index + 1]
		var distance := start.distance_to(end)
		var sample_count := maxi(1, ceili(distance / SAMPLE_STEP))
		for sample_index in range(sample_count + 1):
			samples.append(start.lerp(end, float(sample_index) / float(sample_count)))
	return samples


static func coverage_tier(strokes: Array, target_rect: Rect2, tolerance: float) -> String:
	var grown: Rect2 = target_rect.grow(tolerance)
	var cell_total := maxi(1, ceili(grown.size.x / COVERAGE_CELL_WIDTH))
	var touched := {}

	for stroke in strokes:
		var samples := sample_stroke(stroke)
		for point in samples:
			if not grown.has_point(point):
				continue
			var ci := clampi(
				floori((point.x - grown.position.x) / COVERAGE_CELL_WIDTH),
				0,
				cell_total - 1
			)
			touched[ci] = true

	return tier_from_touched(touched.size(), cell_total)


static func tier_from_touched(touched: int, total: int) -> String:
	if touched < COVERAGE_MIN_CELLS:
		return "none"
	var ratio := float(touched) / float(total)
	if ratio >= COVERAGE_FULL_RATIO:
		return "full"
	if ratio >= COVERAGE_HALF_RATIO:
		return "half"
	return "none"
