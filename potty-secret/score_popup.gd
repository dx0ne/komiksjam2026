extends Node2D

class_name ScorePopup

@onready var label: Label = %Label

func _ready() -> void:
	# Initialize with default empty text and white color
	label.text = ""
	label.modulate = Color.WHITE
	modulate.a = 0.0

func show_delta(text: String, color: Color) -> void:
	"""
	Display a score delta with animation:
	- Fade in over 0.05s
	- Drift up 18px over total 0.55s
	- Fade out over 0.50s (starting after fade-in)
	- Queue free when done
	"""
	label.text = text
	label.modulate = color

	# Main tween: drift up and initial fade in happen in parallel
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade in: 0.0 -> 1.0 over 0.05s
	var fade_in_tween = tween.tween_property(self, "modulate:a", 1.0, 0.05)

	# Drift up: move position.y up by 18px over 0.55s
	tween.tween_property(self, "position:y", position.y - 18.0, 0.55)

	# Chain the fade-out after fade-in completes
	fade_in_tween.tween_property(self, "modulate:a", 0.0, 0.50)
	fade_in_tween.tween_callback(queue_free)
