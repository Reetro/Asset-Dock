@tool
extends ConfirmationDialog

signal create_folder_clicked(folder_name: String)

var folder_name: String

func _on_confirmed():
	create_folder_clicked.emit(folder_name)
	$VBoxContainer/LineEdit.set_text("")

func _on_line_edit_text_changed(new_text):
	folder_name = new_text

func _on_line_edit_text_submitted(new_text):
	create_folder_clicked.emit(new_text)
	$VBoxContainer/LineEdit.set_text("")
	hide()
