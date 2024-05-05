@tool
extends Control
class_name AssetDockGrid

const ASSET_BUTTON = preload("res://addons/asset_dock/asset_button.tscn")
const FOLDER_BIG_THUMB = preload("res://addons/asset_dock/FolderBigThumb.svg")
const BACK = preload("res://addons/asset_dock/Back.png")
const SETTINGS = preload("res://addons/asset_dock/settings.tres")
const FOLDER = preload("res://addons/asset_dock/Folder.svg")

var scene_spawn: String
var all_paths: Array
var last_folder_path = SETTINGS.root_folder_path
var back_button: AssetButton
var all_buttons: Array[AssetButton]
var last_mouse_pos: Vector2
var current_asset_path: String
var created_tree: bool = false
var root: TreeItem
var collapsed_items: Array[TreeItem] = []
var creating_items: bool = false

@onready var grid_container = $HSplitContainer/MainPanel/VBoxContainer/AssetContainer/ScrollContainer/GridContainer
@onready var popup_menu = $HSplitContainer/MainPanel/PopupMenu
@onready var create_folder_dialog = $CreateFolderDialog
@onready var delete_confirmation_dialog = $DeleteConfirmationDialog
@onready var tree = $HSplitContainer/FileListPanel/VBoxContainer/ScrollContainer/Tree
@onready var tree_view_line_edit = $HSplitContainer/FileListPanel/VBoxContainer/TreeViewLineEdit
@onready var line_edit = $HSplitContainer/MainPanel/VBoxContainer/SearchContainer/LineEdit

func _on_main_panel_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		last_mouse_pos = get_global_mouse_position()
		popup_menu.popup(Rect2(last_mouse_pos.x, last_mouse_pos.y, popup_menu.size.x, popup_menu.size.y))

func setup_grid(all_assets: Array):
	all_paths = all_assets
	clear_files(false, true)
	create_icons(all_assets)
	setup_tree_view(all_assets)

func reset_grid(all_assets: Array):
	all_paths = all_assets
	clear_files()
	create_icons(all_assets)

func setup_tree_view(all_assets: Array):
	if not created_tree:
		root = tree.create_item()
		root.set_text(0, SETTINGS.root_folder_path)
		root.set_metadata(0, SETTINGS.root_folder_path)
		root.set_icon(0, FOLDER)
		created_tree = true
	# Get only folder paths from all assets
	var folders = get_only_folders_from_path(all_assets)
	create_tree_items(folders, root) # Create the actual tree view
	
func create_tree_items(folders: Array, root_item: TreeItem):
	creating_items = true
	for folder in folders: # Create tree view
		var folder_name = folder["folder_name"].get_file()
		if not does_tree_item_exist(folder["folder_name"], root_item):
			var section_item = tree.create_item(root_item) as TreeItem
			section_item.set_text(0, folder_name)
			section_item.set_metadata(0, folder["folder_name"])
			section_item.set_icon(0, FOLDER)
			section_item.collapsed = true
			if folder["folder_files"].size() >= 1:
				var sub_folders = get_only_folders_from_path(folder["folder_files"])
				create_tree_items(sub_folders, section_item)
	creating_items = false

func update_tree_items(folders: Array, root_item: TreeItem, tree: Tree):
	creating_items = true
	# Track items that are still present in the tree
	var present_items: Array[TreeItem] = []
	for folder in folders:
		if typeof(folder) == TYPE_DICTIONARY:
			var folder_name = folder["folder_name"]
			var existing_item = find_tree_item(folder_name, root_item.get_children())
			if existing_item:
				present_items.append(existing_item) # Add the item to the list of present items
	# Remove items that are no longer present in the folders array
	for child in root_item.get_children():
		if child not in present_items:
			root_item.remove_child(child)
	# Update or add folders
	for folder in folders:
		if typeof(folder) == TYPE_DICTIONARY:
			var folder_name = folder["folder_name"]
			var existing_item = find_tree_item(folder_name, root_item.get_children())
			if existing_item:
				# Update existing folder
				update_tree_items(folder["folder_files"], existing_item, tree)
			else:
				# Create new folder using the provided tree
				if root_item.get_tree() == tree:
					var new_item = tree.create_item(root_item) as TreeItem
					if new_item:
						new_item.set_text(0, folder_name.get_file())
						new_item.set_metadata(0, folder_name)
						new_item.set_icon(0, FOLDER)
						new_item.collapsed = true
						if folder["folder_files"].size() >= 1:
							update_tree_items(folder["folder_files"], new_item, tree)
					else:
						printerr("Error: Failed to create new tree item.")
				else:
					printerr("Error: Root item belongs to a different tree than the one provided.")
			creating_items = false
	# Expand or collapse items based on the stored collapsed items
	for item in collapsed_items:
		item.collapsed = false

func find_tree_item(folder_name: String, items: Array) -> TreeItem:
	for item in items:
		if item.get_metadata(0) == folder_name:
			return item
	return null

func does_tree_item_exist(folder_name: String, root_item: TreeItem) -> bool:
	var children = root_item.get_children()
	for chld in children:
		var folder = chld.get_metadata(0) as String
		if folder_name == folder:
			return true
	return false

func get_tree_item_for_path(folder_path: String) -> TreeItem:
	for child in root.get_children():
		var path = child.get_metadata(0)
		if path == folder_path:
			return child
	printerr("Failed to find tree item for path " + folder_path)
	return null

func get_only_folders_from_path(all_assets: Array) -> Array:
	var folders: Array = []
	for asset_path in all_assets:
		if type_string(typeof(asset_path)) == "Dictionary":
			folders.append(asset_path)
	return folders

func refresh_current_path(path: String, all_assets: Array):
	reset_line_edit()
	all_assets = all_assets
	var assets_for_path = AssetDock.get_all_files(path, SETTINGS.file_types)
	if assets_for_path.size() <= 0:
		clear_files(true)
	else:
		clear_old_files()
		create_icons(assets_for_path)
	# Get only folder paths from all assets
	var folders = get_only_folders_from_path(AssetDock.get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types))
	update_tree_items(folders, root, tree) # Create the actual tree view
	
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

func clear_files(skip_back_button: bool = false, clear_tree: bool = false):
	all_buttons.clear()
	for i in range(grid_container.get_children().size()):
		var child = grid_container.get_child(i)
		var button = child as AssetButton
		if button.is_back_button and skip_back_button:
			continue
		else:
			child.queue_free()
	if clear_tree and created_tree:
		var tree_items = root.get_children()
		for current in tree_items:
			root.remove_child(current)

func reset_line_edit():
	line_edit.text = ""
	tree_view_line_edit.text = ""

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

func delete_back_button():
	for i in range(grid_container.get_children().size()):
		var child = grid_container.get_child(i)
		var button = child as AssetButton
		if button:
			if button.is_back_button:
				button.queue_free()

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

func _on_tree_item_collapsed(item):
	if not creating_items:
		# Update the collapsed items array
		if item in collapsed_items:
			collapsed_items.erase(item)
		else:
			collapsed_items.append(item)

func _on_tree_cell_selected():
	var selected_folder = tree.get_selected() as TreeItem
	var folder_path = selected_folder.get_metadata(0) as String
	create_assets_for_path(folder_path)

func create_assets_for_path(path: String):
	last_folder_path = path
	if path != SETTINGS.root_folder_path:
		delete_back_button()
		create_back_button()
	else:
		delete_back_button()
	var assets_for_path = AssetDock.get_all_files(path, SETTINGS.file_types)
	if assets_for_path.size() <= 0:
		clear_files(true)
	else:
		clear_old_files()
		create_icons(assets_for_path)

func _on_popup_menu_about_to_popup():
	reset_line_edit()
	reset_grid(AssetDock.get_all_files(last_folder_path, SETTINGS.file_types))

func _on_tree_view_line_edit_text_changed(new_text: String):
	var root_item = tree.get_root()
	var children = root_item.get_children()
	var current_text = new_text.to_lower()
	if current_text == "":
		for child in children:
			child.visible = true
			var child_items = child.get_children()
			for child_child in child_items:
				child_child.visible = true
	else:
		for child in children:
			var current = child as TreeItem
			if current.collapsed:
				current.collapsed = false
			var tree_item_name = current.get_text(0).to_lower()
			if current.get_child_count() <= 0 or !has_visiable_child(current):
				current.visible = false
			else:
				var child_items = current.get_children()
				for child_child in child_items:
					var tree_child_name = child_child.get_text(0).to_lower()
					if !tree_child_name.contains(current_text):
						child_child.visible = false

func has_visiable_child(tree_item: TreeItem) -> bool:
	if tree_item.get_child_count() > 0:
		var children = tree_item.get_children()
		for child in children:
			var current = child as TreeItem
			if current.visible:
				return true
		return false
	else:
		return false
