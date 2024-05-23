@tool
extends HSplitContainer
class_name CollectionsPanel

const SAVE_COLLECTION_PATH = "res://addons/asset_dock/saved_collections/"
const COLLECTIONS_ASSET_BUTTON = preload("res://addons/asset_dock/collections_asset_button.tscn")
const COLLECTION_BUTTON = preload("res://addons/asset_dock/gui_elements/collection_button.tscn")

@onready var create_collection_dialog = $"../../CreateCollectionDialog"
@onready var collection_list_container = $CollectionsListPanel/VBoxContainer/ScrollContainer/CollectionListContainer
@onready var drag_asset_label_container = $CollectionsMainPanel/VBoxContainer/AssetContainer/DragAssetLabelContainer
@onready var drag_asset_label = $CollectionsMainPanel/VBoxContainer/AssetContainer/DragAssetLabelContainer/DragAssetLabel
@onready var collections_main_panel = $CollectionsMainPanel
@onready var collection_scroll_container = $CollectionsMainPanel/VBoxContainer/AssetContainer/CollectionScrollContainer
@onready var collections_grid_container = $CollectionsMainPanel/VBoxContainer/AssetContainer/CollectionScrollContainer/CollectionsGridContainer
@onready var delete_collection_confirmation_dialog = $"../../DeleteCollectionConfirmationDialog"
@onready var collections_list_line_edit = $CollectionsListPanel/VBoxContainer/CollectionsListLineEdit
@onready var collections_line_edit = $CollectionsMainPanel/VBoxContainer/SearchContainer/CollectionsLineEdit
@onready var remove_from_collection_dialog = $"../../RemoveFromCollectionDialog"

var all_collections: Array[CollectionsData]
var selected_collection: CollectionsData = null
var all_buttons: Array
var collection_to_delete: CollectionsData = null
var clicked_collection_button: Button = null
var asset_path_to_remove: String = ""
var collection_to_remove: CollectionsData = null

func _on_collections_main_panel_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		collections_line_edit.release_focus()
		collections_list_line_edit.release_focus()
		if clicked_collection_button != null:
			clicked_collection_button.release_focus()

func setup_collections(show_select_message: bool = true):
	if selected_collection != null:
		return
	if show_select_message:
		collections_main_panel.can_drag = false
		show_drag_label("Please Select A Collection")
	all_collections = AssetDock.get_all_collection_data()
	create_list()

func show_drag_label(message: String):
	drag_asset_label_container.visible = true
	drag_asset_label.text = message

func create_list():
	clear_list()
	for collection in all_collections:
		var button = COLLECTION_BUTTON.instantiate() as CollectionButton
		button.on_delete_pressed.connect(on_delete_collection_pressed)
		button.setup(collection)
		button.on_collection_selected.connect(on_collection_button_clicked)
		collection_list_container.add_child(button)

func clear_list():
	for i in range(collection_list_container.get_child_count()):
		var current = collection_list_container.get_child(i)
		current.queue_free()

func clear_grid():
	all_buttons.clear()
	for i in range(collections_grid_container.get_child_count()):
		var current = collections_grid_container.get_child(i)
		current.queue_free()

func on_collection_button_clicked(collection: CollectionsData, collection_button: Button):
	selected_collection = collection
	collections_main_panel.can_drag = true
	clicked_collection_button = collection_button
	setup_grid()

func on_delete_collection_pressed(collection: CollectionsData):
	collection_to_delete = collection
	delete_collection_confirmation_dialog.popup_centered()

func _on_delete_collection_confirmation_dialog_confirmed():
	selected_collection = null
	collection_scroll_container.visible = false
	DirAccess.remove_absolute(collection_to_delete.resource_path)
	AssetDock.editor.get_resource_filesystem().scan() # Refresh file system
	setup_collections()

func setup_grid():
	var data_to_use: CollectionsData = selected_collection
	if data_to_use != null:
		clear_grid()
		if data_to_use.collection_items.size() > 0:
			drag_asset_label_container.visible = false
			collection_scroll_container.visible = true
			create_icons(data_to_use.collection_items, data_to_use)
		else:
			show_drag_label("Drag Assets Here")
			collection_scroll_container.visible = false
	else:
		printerr("Failed to load collection collection was null")

func create_icons(asset_paths: Array, collection_data: CollectionsData):
	for asset_path in asset_paths:
		var string_path = ResourceUID.get_id_path(asset_path)
		var data = {
			"data": collection_data
		}
		AssetDock.get_preview(string_path, self, "create_asset_button", data)

func create_asset_button(path: String, preview: Texture2D, thumbnail: Texture2D, userdata):
	if not created_button_for_path(path):
		var asset_button = COLLECTIONS_ASSET_BUTTON.instantiate() as CollectionsAssetButton
		var name = path.get_file()
		all_buttons.append(asset_button)
		var collection = userdata["data"]
		asset_button.add_button(preview, name, path, collection)
		asset_button.remove_button_clicked.connect(on_remove_from_collection_clicked)
		collections_grid_container.add_child(asset_button)

func on_remove_from_collection_clicked(collection: CollectionsData, asset_path: String):
	collection_to_remove = collection
	asset_path_to_remove = asset_path
	remove_from_collection_dialog.popup_centered()

func created_button_for_path(path: String) -> bool:
	for button in all_buttons:
		if is_instance_valid(button):
			if button.asset_path == path:
				return true
	return false

func _on_add_collections_button_pressed():
	create_collection_dialog.popup_centered()

func _on_remove_from_collection_dialog_confirmed():
	var uuid = ResourceLoader.get_resource_uid(asset_path_to_remove)
	if collection_to_remove.collection_items.has(uuid):
		var index_remove: int = -1
		for i in range(collection_to_remove.collection_items.size()):
			var current = collection_to_remove.collection_items[i]
			if current == uuid:
				index_remove = i
				break
		if index_remove > -1:
			collection_to_remove.collection_items.remove_at(index_remove)
			var save_result = ResourceSaver.save(collection_to_remove, collection_to_remove.resource_path)
			if save_result != OK:
				printerr("Failed To Save Data Error Code: " + save_result)
			setup_grid()
		else:
			printerr("Failed remove " + asset_path_to_remove + " from collection " + collection_to_remove.collection_name + " failed to find item in collection")
	else:
		printerr("Failed remove " + asset_path_to_remove + " from collection " + collection_to_remove.collection_name + " target item was not in collection")

func is_folder(path: String) -> bool:
	var dir = DirAccess.open(path)
	return dir != null

func _on_create_collection_dialog_create_collection_clicked(collection_name: String):
	if does_collection_exist(collection_name):
		printerr("Failed to create collection " + collection_name + " collection already exists")
		return 
	var data = CollectionsData.new()
	data.collection_name = collection_name
	var path = SAVE_COLLECTION_PATH + collection_name + ".tres"
	var save_result = ResourceSaver.save(data, path)
	if save_result != OK:
		printerr("Failed To Save Data Error Code: " + save_result)
	selected_collection = null
	clear_grid()
	collection_scroll_container.visible = false
	setup_collections()

func does_collection_exist(collection_name: String) -> bool:
	var collections = AssetDock.get_all_collection_data()
	for collection in collections:
		if collection.collection_name == collection_name:
			return true
	return false

func _on_collections_main_panel_assets_dropped(asset_paths):
	if selected_collection != null:
		for asset_path in asset_paths:
			if is_folder(asset_path):
				var all_assets = AssetDock.get_all_files(asset_path, [])
				for sub_path in all_assets:
					add_path_to_selected_collection(sub_path)
			else:
				add_path_to_selected_collection(asset_path)

func add_path_to_selected_collection(path: String):
	if selected_collection:
		if path.contains(".import"):
			return
		var uuid = ResourceLoader.get_resource_uid(path)
		if not selected_collection.collection_items.has(uuid):
			selected_collection.collection_items.append(uuid)
			setup_grid()
			var save_path = SAVE_COLLECTION_PATH + selected_collection.collection_name + ".tres"
			ResourceSaver.save(selected_collection, save_path)
		else:
			printerr("Failed to add asset to collection collection all ready has asset " + path)

func _on_collections_line_edit_text_changed(new_text: String):
	if selected_collection != null:
		if new_text != "":
			var current_text_lowered = new_text.to_lower()
			for i in range(collections_grid_container.get_child_count()):
				var button = collections_grid_container.get_child(i) as CollectionsAssetButton
				var button_name = button.asset_name as String
				var name_lowerd = button_name.to_lower()
				if not name_lowerd.contains(current_text_lowered):
					button.visible = false
				else:
					button.visible = true
		else:
			for i in range(collections_grid_container.get_child_count()):
				var button = collections_grid_container.get_child(i) as CollectionsAssetButton
				button.visible = true

func _on_collections_list_line_edit_text_changed(new_text: String):
	if new_text != "":
		var current_text_lowered = new_text.to_lower()
		for i in range(collection_list_container.get_child_count()):
			var button = collection_list_container.get_child(i) as CollectionButton
			var button_name = button.my_collection.collection_name as String
			var name_lowerd = button_name.to_lower()
			if not name_lowerd.contains(current_text_lowered):
				button.visible = false
			else:
				button.visible = true
	else:
		for i in range(collection_list_container.get_child_count()):
			var button = collection_list_container.get_child(i) as CollectionButton
			button.visible = true
