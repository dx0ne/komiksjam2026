extends VBoxContainer

@onready var resolution_option_button: OptionButton = $OptionButton

var Resolutions: Dictionary = {"3840x2160":Vector2i(3840,2160),
								"2560x1440": Vector2i(2560,1440),
								"1920x1080":Vector2i(1920,1080),
								"1366x768":Vector2i(1366,768),
								"1536x864":Vector2i(1536,864),
								"1280x720":Vector2i(1280,720),
								"1440x900":Vector2i(1440,900),
								"1600x900":Vector2i(1600,900),
								"1024x600":Vector2i(1024,600),
								"800x600": Vector2i(800,600)}

#Called when the node enters the scene tree the firt time.
func _ready():
	Add_Resolution() # Replace with function body.
	
func Add_Resolution():
	for r in Resolutions:
		resolution_option_button.add_item(r)

func _on_option_button_item_selected(index: int) -> void:
	var ID = resolution_option_button.get_item_text(index)
	get_window().set_size(Resolutions[ID])
	Centre_Window()
	
func Centre_Window():
	var Centre_Screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var Window_Size = get_window().get_size_with_decorations()
	get_window().set_position(Centre_Screen-Window_Size/2)
