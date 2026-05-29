extends Node2D

class_name ScorePopup

@onready var label: Label = %Label

func _ready() -> void:
	label.text = ""
	label.modulate = Color.WHITE

func show_delta(text: String, color: Color) -> void:
	"""
	Display a score delta with animation:
	- Appears fully opaque
	- Drifts up 18px
	- Fades out, then queue_free
	"""
	label.text = text
	label.modulate = color
	modulate.a = 1.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 18.0, 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.30) \
		.set_delay(0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(queue_free)
