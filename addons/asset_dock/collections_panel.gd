@tool
extends HSplitContainer
class_name CollectionsPanel

const SAVE_COLLECTION_PATH = "res://addons/asset_dock/saved_collections/"
const ASSET_BUTTON = preload("res://addons/asset_dock/asset_button.tscn")
const COLLECTION_BUTTON = preload("res://addons/asset_dock/gui_elements/collection_button.tscn")

@onready var create_collection_dialog = $"../../CreateCollectionDialog"
@onready var collection_list_container = $CollectionsListPanel/VBoxContainer/ScrollContainer/CollectionListContainer
@onready var drag_asset_label_container = $CollectionsMainPanel/VBoxContainer/AssetContainer/DragAssetLabelContainer
@onready var drag_asset_label = $CollectionsMainPanel/VBoxContainer/AssetContainer/DragAssetLabelContainer/DragAssetLabel
@onready var collections_main_panel = $CollectionsMainPanel
@onready var collection_scroll_container = $CollectionsMainPanel/VBoxContainer/AssetContainer/CollectionScrollContainer
@onready var collections_grid_container = $CollectionsMainPanel/VBoxContainer/AssetContainer/CollectionScrollContainer/CollectionsGridContainer

var all_collections: Array[CollectionsData]
var selected_collection: CollectionsData = null
var all_buttons: Array

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
	# Clear current buttons
	for i in range(collection_list_container.get_child_count()):
		var current = collection_list_container.get_child(i)
		current.queue_free()
	# Create list
	for collection in all_collections:
		var button = COLLECTION_BUTTON.instantiate() as CollectionButton
		button.on_delete_pressed.connect(on_delete_collection_pressed)
		button.setup(collection)
		button.on_collection_selected.connect(on_collection_button_clicked)
		collection_list_container.add_child(button)

func on_collection_button_clicked(collection: CollectionsData):
	selected_collection = collection
	collections_main_panel.can_drag = true
	setup_grid()

func on_delete_collection_pressed(name_of_collection: String):
	pass

func setup_grid():
	var data_to_use: CollectionsData = selected_collection
	if data_to_use != null:
		if data_to_use.collection_items.size() > 0:
			drag_asset_label_container.visible = false
			collection_scroll_container.visible = true
			create_icons(data_to_use.collection_items)
		else:
			show_drag_label("Drag Assets Here")
	else:
		printerr("Failed to load collection collection was null")

func create_icons(asset_paths: Array):
	for asset_path in asset_paths:
		AssetDock.get_preview(asset_path, self, "create_asset_button")

func create_asset_button(path: String, preview: Texture2D, thumbnail: Texture2D, userdata):
	if not created_button_for_path(path):
		var asset_button = ASSET_BUTTON.instantiate() as AssetButton
		var name = path.get_file()
		all_buttons.append(asset_button)
		asset_button.add_button(preview, name, path)
		collections_grid_container.add_child(asset_button)

func created_button_for_path(path: String) -> bool:
	for button in all_buttons:
		if is_instance_valid(button):
			if button.asset_path == path:
				return true
	return false

func _on_add_collections_button_pressed():
	create_collection_dialog.popup_centered()

func is_folder(path: String) -> bool:
	var dir = DirAccess.open(path)
	return dir != null

func _on_create_collection_dialog_create_collection_clicked(collection_name: String):
	# TODO check to see if a file with the same exists 
	var data = CollectionsData.new()
	data.collection_name = collection_name
	var path = SAVE_COLLECTION_PATH + collection_name + ".tres"
	var save_result = ResourceSaver.save(data, path)
	if save_result != OK:
		printerr("Failed To Save Data Error Code: " + save_result)
	setup_collections()

func _on_collections_main_panel_assets_dropped(asset_paths):
	if selected_collection != null:
		for asset_path in asset_paths:
			if is_folder(asset_path):
				var all_assets = AssetDock.get_all_files(asset_path, [])
				print(all_assets)
				for sub_path in all_assets:
					add_path_to_selected_collection(sub_path)
			else:
				add_path_to_selected_collection(asset_path)
		var path = SAVE_COLLECTION_PATH + selected_collection.collection_name + ".tres"
		ResourceSaver.save(selected_collection, path)

func add_path_to_selected_collection(path: String):
	if selected_collection:
		if not selected_collection.collection_items.has(path) and not path.contains(".import"):
			selected_collection.collection_items.append(path)
