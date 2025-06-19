extends Control
@onready var shader_material: ShaderMaterial = $LightMask.material
var time := 0.0

func _process(delta):
	time += delta
	var mouse_pos = get_viewport().get_mouse_position()
	shader_material.set_shader_parameter("light_position", mouse_pos)

	var flicker = sin(time * 6.0) * 0.5 + randf_range(-0.2, 0.2)
	shader_material.set_shader_parameter("flicker_value", flicker)


func _on_map_1_button_2_pressed() -> void:
	var mapa_scene = load("res://Escenas/Mansion.tscn")
	get_tree().change_scene_to_packed(mapa_scene)
