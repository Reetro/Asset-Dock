@tool
extends Control
class_name CollectionsAssetButton

signal remove_button_clicked(collection: CollectionsData, asset_path: String)

const SETTINGS = preload("res://addons/asset_dock/settings.tres")

@onready var popup_menu = $PopupMenu

var asset_name: String
var asset_path: String
var last_mouse_pos: Vector2
var my_collection: CollectionsData

func add_button(icon: Texture, name: String, path: String, collection: CollectionsData):
	$Button.scene_path = path
	$Label.text = name
	$Button.icon = icon
	asset_name = name
	asset_path = path
	my_collection = collection

func _on_popup_menu_id_pressed(id):
	match (id):
		0:
			remove_button_clicked.emit(my_collection, asset_path)

func _on_button_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		var last_mouse_pos = get_global_mouse_position()
		popup_menu.popup(Rect2(last_mouse_pos.x, last_mouse_pos.y, popup_menu.size.x, popup_menu.size.y))
