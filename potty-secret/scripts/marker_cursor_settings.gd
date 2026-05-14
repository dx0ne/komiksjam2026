extends Resource
class_name MarkerCursorSettings

@export_file("*.png") var texture_path := "res://assets/Reka_Marker.png"
@export var cursor_scale := 0.08
@export var rotation_degrees := 125.0
@export var hotspot := Vector2(1655.0, 304.0)

func scale_vector() -> Vector2:
	return Vector2(cursor_scale, cursor_scale)

func rotation_radians() -> float:
	return deg_to_rad(rotation_degrees)

func load_texture() -> Texture2D:
	if ResourceLoader.exists(texture_path):
		var resource := load(texture_path)
		if resource is Texture2D:
			return resource
	var image := Image.load_from_file(texture_path)
	if image == null:
		push_warning("Could not load marker cursor texture: %s" % texture_path)
		return null
	return ImageTexture.create_from_image(image)
