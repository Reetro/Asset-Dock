@tool
extends EditorPlugin
class_name AssetDock

const ASSET_DOCK_GRID = preload("res://addons/asset_dock/asset_dock_grid.tscn")
const SETTINGS = preload("res://addons/asset_dock/settings.tres")

var asset_dock_grid: AssetDockGrid
static var editor: EditorInterface
static var preview: EditorResourcePreview
static var instance: AssetDock
static var loaded: bool = false
static var need_to_reload: bool = false
static var refresh_local_folder: bool = false
static var current_folder_path: String

func _enter_tree():
	editor = get_editor_interface()
	preview = editor.get_resource_previewer()
	asset_dock_grid = ASSET_DOCK_GRID.instantiate()
	SETTINGS.setting_changed.connect(on_settings_changed)
	add_control_to_bottom_panel(asset_dock_grid, "Asset Dock")
	call_deferred("setup_library") # Need to wait for editor to finish loading before loading asset files

func on_settings_changed():
	if DirAccess.dir_exists_absolute(SETTINGS.root_folder_path):
		var all_assets := get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types)
		asset_dock_grid.setup_grid(all_assets, true)
	else:
		var error = "Failed to load asssets at path %s target path was not found"
		var fianl = error % SETTINGS.root_folder_path
		printerr(fianl)

func setup_library():
	if DirAccess.dir_exists_absolute(SETTINGS.root_folder_path):
		var all_assets := get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types)
		asset_dock_grid.setup_grid(all_assets)
		call_deferred("setup_signals") # Wait to setup these signals to avoid assets getting duplicated on 1st load
	else:
		var error = "Failed to load asssets at path %s target path was not found"
		var fianl = error % SETTINGS.root_folder_path
		printerr(fianl)

func setup_signals():
	get_editor_interface().get_resource_filesystem().filesystem_changed.connect(filesystem_changed)
	get_editor_interface().get_resource_filesystem().resources_reimported.connect(resources_reimported)
	call_deferred("set_loaded") # Wait for next frame to set loaded to true so that signals to cause a reload

func set_loaded():
	loaded = true

func filesystem_changed():
	if loaded:
		if need_to_reload: # I hate this hack so much only I could get it to not trigger multiple times when 1st loaded in
			if asset_dock_grid.has_asset_search() or asset_dock_grid.has_folder_search():
				return
			if refresh_local_folder or current_folder_path != "":
				refresh_local_folder = false
				var all_assets := get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types)
				asset_dock_grid.refresh_current_path(current_folder_path, all_assets)
			else:
				var all_assets := get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types)
				asset_dock_grid.setup_grid(all_assets)
		else:
			need_to_reload = true

func resources_reimported(resources: PackedStringArray):
	if loaded:
		if refresh_local_folder:
			refresh_local_folder = false
			var all_assets := get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types)
			asset_dock_grid.refresh_current_path(current_folder_path, all_assets)
		else:
			var all_assets := get_all_files(SETTINGS.root_folder_path, SETTINGS.file_types)
			asset_dock_grid.setup_grid(all_assets)

func _exit_tree():
	if asset_dock_grid:
		remove_control_from_bottom_panel(asset_dock_grid)
		asset_dock_grid.queue_free()

static func get_preview(scene: String, receiver: Object, function: StringName, data = {}) -> void:
	preview.queue_resource_preview(scene, receiver, function, data)

static func get_all_files(path: String, file_ext: Array) -> Array:
	var files: Array = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				if !file_name.contains(".godot"):
					var new_path = path + "/" + file_name
					var dic = {}
					dic["folder_name"] = new_path
					dic["folder_files"] = get_all_files(new_path, SETTINGS.file_types)
					files.append(dic)
			else:
				if has_ext(file_name, file_ext) or file_ext.size() <= 0:
					files.append(path + "/" + file_name)
			file_name = dir.get_next()
		if not SETTINGS.show_empty_folders:
			files = remove_empty_folders(files)
		return fix_paths(files)
	else:
		printerr("An error occurred when trying to access path " + path)
		return []

static func get_all_collection_data() -> Array[CollectionsData]:
	var dir = DirAccess.open("res://addons/asset_dock/saved_collections/")
	var result: Array[CollectionsData] = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = "res://addons/asset_dock/saved_collections/" + file_name
			if has_ext(file_name, ["tres"]):
				var resource = ResourceLoader.load(full_path) as CollectionsData
				result.append(resource)
			file_name = dir.get_next()
		return result
	else:
		DirAccess.make_dir_absolute("res://addons/asset_dock/saved_collections/")
		editor.get_resource_filesystem().scan() # Refresh file system
		return []

static func has_ext(file_name: String, file_ext: Array) -> bool:
	var result = false
	for ext in file_ext:
		if file_name.contains(ext) and !file_name.contains(".import"):
			result = true
	return result

static func fix_paths(data: Array) -> Array:
	var fixed_data: Array = []
	for item in data:
		if typeof(item) == TYPE_DICTIONARY:
			# Fix the folder name
			var folder_name = item["folder_name"]
			if folder_name.begins_with("res:///"):
				folder_name = folder_name.replace("res:///", "res://")
			folder_name = "res://" + folder_name.substr(6, folder_name.length()).replace("//", "/")
			
			# Recursively fix the folder files
			var folder_files = fix_paths(item["folder_files"])
			fixed_data.append({"folder_name": folder_name, "folder_files": folder_files})
		else:
			# Fix individual file path
			if item.begins_with("res:///"):
				item = item.replace("res:///", "res://")
			item = "res://" + item.substr(6, item.length()).replace("//", "/")
			fixed_data.append(item)
	return fixed_data

static func remove_empty_folders(data: Array) -> Array:
	var cleaned_data: Array = []
	for item in data:
		if typeof(item) == TYPE_DICTIONARY:
			item["folder_files"] = remove_empty_folders(item["folder_files"])
			if item["folder_files"].size() > 0:
				cleaned_data.append(item)
		else:
			cleaned_data.append(item)
	return cleaned_data
