@tool
extends ConfirmationDialog
class_name CreateCollectionDialog

signal create_collection_clicked(collection_name: String)

var collection_name: String

func _on_confirmed():
	create_collection_clicked.emit(collection_name)
	$VBoxContainer/LineEdit.set_text("")

func _on_line_edit_text_changed(new_text):
	collection_name = new_text

func _on_line_edit_text_submitted(new_text):
	create_collection_clicked.emit(new_text)
	$VBoxContainer/LineEdit.set_text("")
	hide()
