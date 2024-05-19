@tool
extends Panel

signal assets_dropped(asset_paths: Array[String])

var can_drag: bool = true

func _drop_data(at_position, data):
	if data.has("files"):
		var paths = data["files"] as Array[String]
		assets_dropped.emit(paths)

func _can_drop_data(at_position, data):
	return can_drag
