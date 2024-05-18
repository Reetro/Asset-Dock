@tool
extends HBoxContainer
class_name CollectionButton

signal on_collection_selected(asset_paths: Array[String])
signal on_delete_pressed(name_of_collection: String)

@onready var popup_menu = $PopupMenu
var asset_paths: Array[String] = []

func setup(name_to_use: String, asset_paths_to_use: Array[String]):
	$Button.text = name_to_use
	asset_paths = asset_paths_to_use
	
func _on_button_pressed():
	on_collection_selected.emit(asset_paths)

func _on_button_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		var last_mouse_pos = get_global_mouse_position()
		popup_menu.popup(Rect2(last_mouse_pos.x, last_mouse_pos.y, popup_menu.size.x, popup_menu.size.y))
