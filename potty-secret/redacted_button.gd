class_name RedactedLabel
extends Node2D

@export var my_name:String;
signal on_redacted_clicked(id:String);
signal on_started_good();
signal on_zjebane();

@onready var btn:TextureButton = %TextureButton;

var words =WordManager.master_list.duplicate();
var random_word = words.pick_random()

var is_dragging = false
var start_pos = Vector2.ZERO
var threshold = 0.3;
var is_redacted:bool=false;

func _on_pressed() -> void:
	pass

func redacted() -> void:
	print("kliked "+random_word);
	is_redacted=true;
	on_redacted_clicked.emit(random_word);
	pass # Replace with function body.

func _on_ready() -> void:
	
	%Label.resized.connect(mix_btn_size);
	random_word = words.pick_random();
	%Label.text=random_word;
	mix_btn_size();
	pass # Replace with function body.

func mix_btn_size() -> void:
	var margin:float = 0.2
	btn.custom_minimum_size = %Label.size*(1.0+margin);
	btn.custom_minimum_size.y*=(1.0+margin);
	btn.position.x-=%Label.size.x*margin*0.5;
	btn.position.y-=%Label.size.y*margin*0.5;
	pass


func _on_label_gui_input(event: InputEvent) -> void:
	if is_redacted:
		return;
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
					print(event.position);
					if(event.position.x < btn.size.x*threshold):
						is_dragging=true;
						on_started_good.emit();
			elif is_dragging:
				print("zjebane?");
				var within_y = event.position.y >= 0 and event.position.y <=btn.size.y
				if(event.position.x > btn.size.x*(1.0-threshold) and event.position.x < btn.size.x and within_y):
					print("labelka prawa strona");
					is_dragging = false;
					redacted();
				else:
					is_dragging=false;
					print("zjebane");
					on_zjebane.emit();
	pass # Replace with function body.
