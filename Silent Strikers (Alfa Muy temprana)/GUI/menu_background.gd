extends CanvasLayer
@onready var shader_material: ShaderMaterial = $LightMask.material
var time := 0.0

func _process(delta):
	time += delta
	var mouse_pos = get_viewport().get_mouse_position()
	shader_material.set_shader_parameter("light_position", mouse_pos)

	# Flicker suave con aleatoriedad
	var flicker = sin(time * 6.0) * 0.5 + randf_range(-0.2, 0.2)
	shader_material.set_shader_parameter("flicker_value", flicker)
	



func _on_singleplayer_button_pressed() -> void:
	var mapa_scene = load("res://Escenas/map_select.tscn")
	get_tree().change_scene_to_packed(mapa_scene)


func _on_multiplayer_button_pressed() -> void:
	var mapa_scene = load("res://Escenas/multiplayer_scene.tscn")
	get_tree().change_scene_to_packed(mapa_scene)


func _on_options_button_pressed() -> void:
	var mapa_scene = load("res://Escenas/settings_screen.tscn")
	get_tree().change_scene_to_packed(mapa_scene)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
