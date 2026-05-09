extends Node2D

@export var my_name:String;
signal on_redacted_clicked(id:String);

var words = ["aliens", "elivis", "bigfoot", "reptilians"]
var random_word = words.pick_random()

var is_dragging = false
var start_pos = Vector2.ZERO
var threshold = 0.2

func _on_pressed() -> void:
	print("kliked "+random_word);
	self.disabled =true;
	on_redacted_clicked.emit(my_name);
	pass # Replace with function body.

func _on_ready() -> void:
	%Label.resized.connect(mix_btn_size);
	random_word = words.pick_random();
	%Label.text=random_word;
	pass # Replace with function body.

func mix_btn_size() -> void:
	%TextureButton.custom_minimum_size = %Label.size*1.2;
	%TextureButton.custom_minimum_size.y*=1.1;
	pass


func _on_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
					print(event.position);
					if(event.position.x < %Label.size.x*threshold):
						is_dragging=true;
			elif is_dragging:
				if(event.position.x > %Label.size.x*(1.0-threshold)):
					is_dragging = false;
					print("redacted "+random_word);
	pass # Replace with function body.
