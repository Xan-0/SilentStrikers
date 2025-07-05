extends Control

func _on_back_menu_button_pressed() -> void:
	var mapa_scene = load("res://Escenas/main_menu.tscn")
	get_tree().change_scene_to_packed(mapa_scene)
	

func _on_try_again_button_pressed() -> void:
	var mapa_scene = load("res://Escenas/Mansion.tscn")
	get_tree().change_scene_to_packed(mapa_scene)
