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
