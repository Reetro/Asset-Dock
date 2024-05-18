@tool
extends HSplitContainer
class_name CollectionsPanel

const SAVE_COLLECTION_PATH = "res://addons/asset_dock/saved_collections/"
const COLLECTION_BUTTON = preload("res://addons/asset_dock/gui_elements/collection_button.tscn")

@onready var create_collection_dialog = $"../../CreateCollectionDialog"
@onready var collection_list_container = $CollectionsListPanel/VBoxContainer/ScrollContainer/CollectionListContainer

var all_collections: Array[CollectionsData]
var selected_collection: CollectionsData = null

func _drop_data(at_position, data):
	print("test")
	pass

func _can_drop_data(at_position, data):
	print("test3")
	return true

func _get_drag_data(position: Vector2):
	print("test2")

func setup_collections():
	all_collections = AssetDock.get_all_collection_data()
	create_list()

func create_list():
	# Clear current buttons
	for i in range(collection_list_container.get_child_count()):
		var current = collection_list_container.get_child(i)
		current.queue_free()
	# Create list
	for collection in all_collections:
		var button = COLLECTION_BUTTON.instantiate() as CollectionButton
		button.on_delete_pressed.connect(on_delete_collection_pressed)
		button.setup(collection.collection_name, collection.collection_items)
		button.on_collection_selected.connect(on_collection_button_clicked)
		collection_list_container.add_child(button)

func on_collection_button_clicked(asset_paths: Array[String]):
	pass

func on_delete_collection_pressed(name_of_collection: String):
	pass

func setup_grid():
	var data_to_use: CollectionsData = selected_collection
	if data_to_use != null:
		pass
	else:
		pass

func _on_add_collections_button_pressed():
	create_collection_dialog.popup_centered()

func _on_create_collection_dialog_create_collection_clicked(collection_name: String):
	# TODO check to see if a file with the same exists 
	var data = CollectionsData.new()
	data.collection_name = collection_name
	var path = SAVE_COLLECTION_PATH + collection_name + ".tres"
	var save_result = ResourceSaver.save(data, path)
	if save_result != OK:
		printerr("Failed To Save Data Error Code: " + save_result)
	setup_collections()
