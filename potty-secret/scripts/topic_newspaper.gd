extends Control
class_name TopicNewspaper

signal dismissed

@onready var _paper_name: Label = %PaperName
@onready var _headline: Label = %Headline
@onready var _deck: Label = %Deck
@onready var _body: Label = %Body
@onready var _post_it_label: Label = %PostItLabel

var _topic_id: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()
	if not _topic_id.is_empty():
		_apply_content()


func _fit_to_viewport() -> void:
	var vp_size := get_viewport().get_visible_rect().size
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	set_size(vp_size)
	position = Vector2.ZERO

	var center: CenterContainer = $Center
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.set_offset(Side.SIDE_LEFT, 0)
	center.set_offset(Side.SIDE_TOP, 0)
	center.set_offset(Side.SIDE_RIGHT, 0)
	center.set_offset(Side.SIDE_BOTTOM, 0)
	center.set_size(vp_size)


func setup(topic_id: String) -> void:
	_topic_id = topic_id
	if is_node_ready():
		_apply_content()


func _apply_content() -> void:
	var data := TopicContent.get_topic(_topic_id)
	_paper_name.text = data.get("paper_name", "THE CAPITAL SCOOP")
	_headline.text = data.get("headline", "")
	_deck.text = data.get("deck", "")
	_body.text = data.get("body", "")
	_post_it_label.text = data.get("post_it", TopicContent.POST_IT_DEFAULT)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dismiss()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		_dismiss()
		get_viewport().set_input_as_handled()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_dismiss()


func _dismiss() -> void:
	dismissed.emit()
	queue_free()
