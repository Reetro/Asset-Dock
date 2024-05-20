@tool
extends Button

var scene_path: String = ""

func _get_drag_data(position: Vector2) -> Variant:
	if scene_path.is_empty():
		return null
	return { files = [scene_path], type = "files", from_slot = get_index() }
