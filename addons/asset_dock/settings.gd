@tool
extends Resource
class_name AssetDockSettings

# Root Folder To Look For Files In
@export_dir var root_folder_path: String
# Types Of Files To Add To Asset Library
@export var file_types: Array[String]
# If true empty folders are hidden in the dock
@export var hide_empty_folders: bool = false
