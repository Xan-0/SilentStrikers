extends Node2D

@onready var jugador_icono = $jugador_icono
@onready var player = Singleton.devolver_player()
@onready var icono_guardia_texture = preload("res://assets/Sprites/guardia 1 ajustado/map1enemy_down.png")

var iconos_guardias = []

func _ready():
	var guardias = get_tree().get_nodes_in_group("GuardiasM1")
	print(guardias.size())
	for guardia in guardias:
		var icono = Sprite2D.new()
		icono.texture = icono_guardia_texture
		icono.scale = Vector2(0.3, 0.3) 
		add_child(icono)
		iconos_guardias.append({
			"guardia": guardia,
			"icono": icono
		})


func _process(_delta):
	jugador_icono.global_position = player.global_position
	
	for par in iconos_guardias:
		par["icono"].global_position = par["guardia"].global_position
