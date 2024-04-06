@tool
extends Resource
class_name AssetDockSettings

signal setting_changed

# Root Folder To Look For Files In
@export_dir var root_folder_path: String: set = update_root_folder
# Types Of Files To Add To Asset Library
@export var file_types: Array[String]: set = update_file_types
# If true empty folders are hidden in the dock
@export var hide_empty_folders: bool = false: set = update_hide_empty

func update_hide_empty(value):
	hide_empty_folders = value
	setting_changed.emit()

func update_root_folder(value):
	root_folder_path = value
	setting_changed.emit()
	
func update_file_types(value):
	file_types = value
	setting_changed.emit()
