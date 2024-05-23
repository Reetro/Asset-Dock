@tool
extends Control
class_name AssetDockGrid

const ASSET_BUTTON = preload("res://addons/asset_dock/asset_button.tscn")
const FOLDER_BIG_THUMB = preload("res://addons/asset_dock/FolderBigThumb.svg")
const BACK = preload("res://addons/asset_dock/Back.png")
const SETTINGS = preload("res://addons/asset_dock/settings.tres")
const FOLDER = preload("res://addons/asset_dock/Folder.svg")

enum TABS {
	FILESYSTEM,
	COLLECTIONS
}

@onready var grid_container = $TabContainer/FileSystem/MainPanel/VBoxContainer/AssetContainer/ScrollContainer/GridContainer
@onready var tree = $TabContainer/FileSystem/FileListPanel/VBoxContainer/ScrollContainer/Tree
@onready var tree_view_line_edit = $TabContainer/FileSystem/FileListPanel/VBoxContainer/TreeViewLineEdit
@onready var line_edit = $TabContainer/FileSystem/MainPanel/VBoxContainer/SearchContainer/LineEdit
@onready var tab_container = $TabContainer
@onready var collections: CollectionsPanel = $TabContainer/Collections

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
var folder_to_rename: String = ""

func _on_main_panel_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		tree.deselect_all()
		tree.release_focus()
		tree_view_line_edit.release_focus()
		line_edit.release_focus()

func setup_grid(all_assets: Array, reset_tree_view_name: bool = false):
	var selected_tab = tab_container.current_tab
	match (selected_tab):
		TABS.FILESYSTEM:
			all_paths = all_assets
			clear_files(false, true)
			create_icons(all_assets)
			setup_tree_view(all_assets, reset_tree_view_name)
		TABS.COLLECTIONS:
			collections.setup_collections()

func _on_tab_container_tab_changed(tab: int):
	match (tab):
		TABS.FILESYSTEM:
			all_paths = AssetDock.get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types)
			clear_files(false, true)
			create_icons(all_paths)
			setup_tree_view(all_paths, true)
		TABS.COLLECTIONS:
			if collections:
				collections.setup_collections()

func reset_grid(all_assets: Array):
	all_paths = all_assets
	clear_files()
	create_icons(all_assets)

func setup_tree_view(all_assets: Array, reset_tree_view_name: bool):
	if not created_tree:
		root = tree.create_item()
		root.set_text(0, SETTINGS.root_folder_path)
		root.set_metadata(0, SETTINGS.root_folder_path)
		root.set_icon(0, FOLDER)
		created_tree = true
	elif created_tree and reset_tree_view_name:
		root.set_text(0, SETTINGS.root_folder_path)
		root.set_metadata(0, SETTINGS.root_folder_path)
	# Get only folder paths from all assets
	var folders = get_only_folders_from_path(all_assets)
	create_tree_items(folders, root) # Create the actual tree view
	
func create_tree_items(folders: Array, root_item: TreeItem):
	if tab_container.current_tab == TABS.COLLECTIONS:
		return
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
	if tab_container.current_tab == TABS.COLLECTIONS:
		return
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
	AssetDock.current_folder_path = folder_path
	clear_files()
	create_back_button()
	create_icons(paths)

func has_folder_search() -> bool:
	return tree_view_line_edit.text != ""

func has_asset_search() -> bool:
	return line_edit.text != ""

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
		var paths = get_assets_for_path(SETTINGS.root_folder_path, AssetDock.get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types))
		last_folder_path = SETTINGS.root_folder_path
		create_icons(paths)
	else:
		var newpath = get_last_path(folder_path)
		clear_files()
		var paths = get_assets_for_path(newpath, AssetDock.get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types))
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
	var result = "/".join(parts)
	if result == "res:/":
		return "res://"
	return result

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

func refresh_file_system():
	# Update the UI or any other necessary actions
	AssetDock.refresh_local_folder = true
	AssetDock.current_folder_path = last_folder_path
	AssetDock.editor.get_resource_filesystem().scan() # Refresh file system

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
	AssetDock.current_folder_path = path
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
	if line_edit.text != "":
		reset_line_edit()
		reset_grid(AssetDock.get_all_files(last_folder_path, SETTINGS.file_types))

func _on_tree_view_line_edit_text_changed(new_text: String):
	if new_text == "":
		# Show all items starting from the root item
		var root_item = tree.get_root()
		show_items(root_item)
	else:
		var root_item = tree.get_root()
		uncollapse_all(root_item)
		var current_text = new_text.to_lower()
		hide_non_matching_children(root_item, current_text)

func uncollapse_all(item: TreeItem):
	# Iterate through the children of the current item
	for i in range(item.get_child_count()):
		var child = item.get_child(i)
		var child_text = child.get_text(0).to_lower()
		if child.visible:
			child.collapsed = false
		# Recursively hide non-matching children of the current child
		uncollapse_all(child)

func hide_non_matching_children(item: TreeItem, search_text: String):
	# Iterate through the children of the current item
	for i in range(item.get_child_count()):
		var child = item.get_child(i)
		# Check if the child's text matches the search text
		var child_text = child.get_text(0).to_lower()
		if child_text.find(search_text) == -1:
			# Hide the child if it doesn't match the search text
			child.visible = false
		else:
			# Show the parent items of the matching child
			show_parent_items(child)
		# Recursively hide non-matching children of the current child
		hide_non_matching_children(child, search_text)

func show_items(item: TreeItem):
	# Show the current item
	item.visible = true
	if item != tree.get_root():
		item.collapsed = true
	# Show all children recursively
	for i in range(item.get_child_count()):
		var child = item.get_child(i)
		show_items(child)

func show_parent_items(item: TreeItem):
	# Show the current item
	item.visible = true
	item.collapsed = false
	# Show all parent items recursively
	var parent = item.get_parent()
	while parent:
		parent.visible = true
		parent = parent.get_parent()
