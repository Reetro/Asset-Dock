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
var last_mouse_pos: Vector2
var current_asset_path: String

@onready var grid_container = $MainPanel/VBoxContainer/AssetContainer/ScrollContainer/GridContainer
@onready var popup_menu = $MainPanel/PopupMenu
@onready var create_folder_dialog = $CreateFolderDialog
@onready var delete_confirmation_dialog = $DeleteConfirmationDialog

func _on_main_panel_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		last_mouse_pos = get_global_mouse_position()
		popup_menu.popup(Rect2(last_mouse_pos.x, last_mouse_pos.y, popup_menu.size.x, popup_menu.size.y))

func setup_grid(all_assets: Array):
	all_paths = all_assets
	clear_files()
	create_icons(all_assets)
	
func refresh_current_path(path: String, all_assets: Array):
	all_assets = all_assets
	var assets_for_path = AssetDock.get_all_files(path, SETTINGS.file_types)
	if assets_for_path.size() <= 0:
		clear_files(true)
	else:
		clear_old_files()
		create_icons(assets_for_path)
	
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
		asset_button.on_context_menu_click.connect(on_context_menu_click)
		all_buttons.append(asset_button)

func create_asset_button(path: String, preview: Texture2D, thumbnail: Texture2D, userdata):
	if !created_button_for_path(path):
		var asset_button = ASSET_BUTTON.instantiate() as AssetButton
		var name = path.get_file()
		asset_button.add_button(preview, name, path)
		grid_container.add_child(asset_button)
		asset_button.on_context_menu_click.connect(on_context_menu_click)
		all_buttons.append(asset_button)
		
func on_context_menu_click(type: AssetButton.CONTEXT_MENU_TYPES, asset_path: String):
	match (type):
		AssetButton.CONTEXT_MENU_TYPES.DELETE:
			delete_asset(asset_path)
		AssetButton.CONTEXT_MENU_TYPES.RENAME:
			pass
		AssetButton.CONTEXT_MENU_TYPES.DUPLICATE:
			pass

func delete_asset(asset_path: String):
	current_asset_path = asset_path
	var message = "Are you sure wish to delete %s?"
	delete_confirmation_dialog.get_label().text = message % asset_path
	delete_confirmation_dialog.popup_centered()

func _on_delete_confirmation_dialog_confirmed():
	OS.move_to_trash(ProjectSettings.globalize_path(current_asset_path))
	AssetDock.refresh_local_folder = true
	AssetDock.current_folder_path = last_folder_path
	AssetDock.editor.get_resource_filesystem().scan() # Refresh file system

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

func clear_files(skip_back_button: bool = false):
	all_buttons.clear()
	for i in range(grid_container.get_children().size()):
		var child = grid_container.get_child(i)
		var button = child as AssetButton
		if button.is_back_button and skip_back_button:
			continue
		else:
			child.queue_free()

func clear_old_files():
	for i in range(grid_container.get_children().size()):
		var child = grid_container.get_child(i)
		var button = child as AssetButton
		if button:
			if not does_folder_exist(button.asset_path) and button.is_folder:
				button.queue_free()
			elif not button.is_folder and not button.is_back_button: # regular file
				if not does_file_exist(button.asset_path):
					button.queue_free()

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
		if is_instance_valid(button):
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

func does_folder_exist(folder_path: String) -> bool:
	var paths = AssetDock.get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types) # This maybe slow will have to stress test this cause getting all the assets over and over again will probably slow things down
	var asset_paths = get_assets_for_path(last_folder_path, paths)
	for asset_path in asset_paths:
		if type_string(typeof(asset_path)) == "Dictionary":
			if "folder_name" in asset_path and asset_path["folder_name"] == folder_path:
				return true
	return false
	
func does_file_exist(file_path: String) -> bool:
	var paths = AssetDock.get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types) # This maybe slow will have to stress test this cause getting all the assets over and over again will probably slow things down
	var asset_paths = get_assets_for_path(last_folder_path, paths)
	for asset_path in asset_paths:
		if type_string(typeof(asset_path)) != "Dictionary":
			if file_path == asset_path:
				return true
	return false

func _on_popup_menu_id_pressed(id):
	match (id):
		0:
			create_folder_dialog.popup_centered()

func _on_create_folder_dialog_create_folder_clicked(folder_name):
	if folder_name == "":
		printerr("Failed to create folder no name was given")
		return
	var path = last_folder_path + "/" + folder_name
	if !does_folder_exist(path):
		DirAccess.make_dir_absolute(path)
		AssetDock.refresh_local_folder = true
		AssetDock.current_folder_path = last_folder_path
		AssetDock.editor.get_resource_filesystem().scan() # Refresh file system
	else:
		var message = "Failed to create folder at path %s folder already exists"
		printerr(message % path)
