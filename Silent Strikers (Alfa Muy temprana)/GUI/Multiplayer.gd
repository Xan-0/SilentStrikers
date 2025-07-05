extends Node


func _on_back_menu_button_pressed() -> void:
	var main_menu = load("res://Escenas/main_menu.tscn")
	get_tree().change_scene_to_packed(main_menu)
