@tool
extends Resource
class_name AssetDockSettings

signal setting_changed

# Root Folder To Look For Files In
@export_dir var root_folder_path: String: set = update_root_folder
# Types Of Files To Add To Asset Library
@export var file_types: Array[String]: set = update_file_types
# Should empty folders be shown
@export var show_empty_folders: bool = false: set = update_show_empty_folders

func update_root_folder(value):
	root_folder_path = value
	setting_changed.emit()
	
func update_file_types(value):
	file_types = value
	setting_changed.emit()

func update_show_empty_folders(value):
	show_empty_folders = value
	setting_changed.emit()
