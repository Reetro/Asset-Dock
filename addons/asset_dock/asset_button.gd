@tool
extends Control
class_name AssetButton

signal on_asset_folder_button_clicked(paths: Array, folder_path: String)
signal on_back_button_pressed(folder_path: String)

var asset_name: String
var asset_path: String
var sub_files: Array
var is_folder: bool = false
var is_back_button: bool = false

func _ready():
	$Button.connect("gui_input", on_input)

func on_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.double_click:
			if is_folder:
				on_asset_folder_button_clicked.emit(sub_files, asset_path)
			elif is_back_button:
				on_back_button_pressed.emit(asset_path)

func add_button(icon: Texture, name: String, path: String):
	$Label.text = name
	$Button.icon = icon
	asset_name = name
	asset_path = path
	is_back_button = false
	is_folder = false
	$Button.setup(asset_path)
	
func add_folder_button(icon: Texture, name: String, paths: Array, folder_path: String):
	$Label.text = name
	$Button.icon = icon
	asset_name = name
	sub_files = paths
	asset_path = folder_path
	is_back_button = false
	is_folder = true

func add_back_button(icon: Texture, name: String, folder_path: String):
	$Label.text = name
	$Button.icon = icon
	asset_name = name
	asset_path = folder_path
	is_back_button = true
	is_folder = false
