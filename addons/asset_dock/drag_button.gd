@tool
extends Button

var asset_path: String = ""

func _get_drag_data(position: Vector2):
	if asset_path.is_empty():
		return null
	return { files = [asset_path], type = "files", from_slot = get_index() }

func setup(path: String):
	asset_path = path
