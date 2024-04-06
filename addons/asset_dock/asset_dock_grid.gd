@tool
extends Control
class_name AssetDockGrid

const ASSET_BUTTON = preload("res://addons/asset_dock/asset_button.tscn")
const FOLDER_BIG_THUMB = preload("res://addons/asset_dock/FolderBigThumb.svg")
const BACK = preload("res://addons/asset_dock/Back.png")
const SETTINGS = preload("res://addons/asset_dock/settings.tres")

var scene_spawn: String
var all_paths: Array
var last_folder_path = SETTINGS.root_folder_path
var back_button: AssetButton
var all_buttons: Array[AssetButton]

@onready var grid_container = $MainPanel/VBoxContainer/AssetContainer/ScrollContainer/GridContainer

func setup_grid(all_assets: Array):
	all_paths = all_assets
	clear_files()
	create_icons(all_assets)
	
func create_icons(asset_paths: Array, create_folder_icons: bool = true):
	for asset_path in asset_paths:
		if asset_path != null and type_string(typeof(asset_path)) != "Dictionary":
			AssetDock.get_preview(asset_path, self, "create_asset_button")
		elif type_string(typeof(asset_path)) == "Dictionary":
			if create_folder_icons:
				create_folder_icon(asset_path["folder_files"], asset_path["folder_name"].get_file(), asset_path["folder_name"])
			else:
				create_icons(asset_path["folder_files"], false)

func create_folder_icon(asset_paths: Array, folder_name: String, folder_path: String):
	if !created_button_for_path(folder_path):
		var asset_button = ASSET_BUTTON.instantiate() as AssetButton
		asset_button.add_folder_button(FOLDER_BIG_THUMB, folder_name, asset_paths, folder_path)
		grid_container.add_child(asset_button)
		asset_button.on_asset_folder_button_clicked.connect(on_folder_button_clicked)
		all_buttons.append(asset_button)

func create_asset_button(path: String, preview: Texture2D, thumbnail: Texture2D, userdata):
	if !created_button_for_path(path):
		var asset_button = ASSET_BUTTON.instantiate() as AssetButton
		var name = path.get_file()
		asset_button.add_button(preview, name, path)
		grid_container.add_child(asset_button)
		all_buttons.append(asset_button)

func _on_line_edit_text_changed(new_text: String):
	if new_text.is_empty():
		clear_files()
		create_icons(all_paths)
	else:
		var current_text_lowered = new_text.to_lower()
		clear_files()
		create_icons(all_paths, false)
		var children = grid_container.get_children()
		for child in children:
			var current = child as AssetButton
			var current_name = current.asset_name.to_lower() as String
			if current_name.contains(current_text_lowered):
				current.visible = true
			else:
				current.visible = false

func on_folder_button_clicked(paths: Array, folder_path: String):
	last_folder_path = folder_path
	clear_files()
	create_back_button()
	create_icons(paths)

func clear_files():
	all_buttons.clear()
	for i in range(grid_container.get_children().size()):
		var child = grid_container.get_child(i)
		child.queue_free()

func create_back_button():
	back_button = ASSET_BUTTON.instantiate() as AssetButton
	back_button.add_back_button(BACK, "Back", last_folder_path)
	grid_container.add_child(back_button)
	back_button.on_back_button_pressed.connect(on_back_button_press)

func on_back_button_press(folder_path: String):
	if folder_path == SETTINGS.root_folder_path:
		clear_files()
		var paths = get_assets_for_path(SETTINGS.root_folder_path, all_paths)
		last_folder_path = SETTINGS.root_folder_path
		create_icons(paths)
	else:
		var newpath = get_last_path(folder_path)
		clear_files()
		var paths = get_assets_for_path(newpath, all_paths)
		last_folder_path = newpath
		if last_folder_path != SETTINGS.root_folder_path:
			create_back_button()
		create_icons(paths)

func created_button_for_path(path: String) -> bool:
	for button in all_buttons:
		if button.asset_path == path:
			return true
	return false

func get_last_path(folder_path: String) -> String:
	var directory_separator = "/"
	var parts = folder_path.split(directory_separator)
	if parts.size() > 1:
		parts = parts.slice(0, parts.size() - 1)
	return "/".join(parts)

func get_assets_for_path(folder_path: String, asset_paths: Array) -> Array:
	if folder_path == SETTINGS.root_folder_path:
		return asset_paths
	else:
		for asset_path in asset_paths:
			if type_string(typeof(asset_path)) == "Dictionary":
				if "folder_name" in asset_path and asset_path["folder_name"] == folder_path:
					return asset_path["folder_files"] as Array
				elif "folder_files" in asset_path:
					var result = get_assets_for_path(folder_path, asset_path["folder_files"])
					if result != []:
						return result
		return []
