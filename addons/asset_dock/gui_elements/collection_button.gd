@tool
extends HBoxContainer
class_name CollectionButton

signal on_collection_selected(collection: CollectionsData)
signal on_delete_pressed(name_of_collection: String)

@onready var popup_menu = $PopupMenu

var my_collection: CollectionsData

func setup(collection: CollectionsData):
	$Button.text = collection.collection_name
	my_collection = collection
	
func _on_button_pressed():
	on_collection_selected.emit(my_collection)

func _on_button_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		var last_mouse_pos = get_global_mouse_position()
		popup_menu.popup(Rect2(last_mouse_pos.x, last_mouse_pos.y, popup_menu.size.x, popup_menu.size.y))
