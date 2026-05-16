extends Node2D

const CLICK_PADDING := Vector2(12, 12)


func contains_global_point(global_point: Vector2) -> bool:
	var mug: Sprite2D = $Mug
	if mug.texture == null:
		return false
	var local := mug.get_global_transform_with_canvas().affine_inverse() * global_point
	var rect := mug.get_rect().grow_individual(
		CLICK_PADDING.x,
		CLICK_PADDING.y,
		CLICK_PADDING.x,
		CLICK_PADDING.y
	)
	return rect.has_point(local)
