extends Button

var escena_precargada = preload("res://Escenas/menu_background_oficial.tscn")

func _on_button_pressed():
	get_tree().change_scene_to_file("res://scenes/MenuPrincipal.tscn")


func _on_pressed() -> void:
	pass # Replace with function body.
