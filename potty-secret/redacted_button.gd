extends TextureButton

@export var my_name:String;
signal on_redacted_clicked(id:String);

func _on_pressed() -> void:
	print("kliked "+my_name);
	self.disabled =true;
	on_redacted_clicked.emit(my_name);
	pass # Replace with function body.
