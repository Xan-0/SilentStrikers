extends Node2D

@onready var jugador_icono = $jugador_icono
@onready var player = Singleton.devolver_player()
@onready var icono_guardia_escena = preload("res://Sprites/guardia 1 ajustado/map1enemy_down.png")  # ícono del guardia

var iconos_guardias = []

func _ready():
	var guardias = get_tree().get_nodes_in_group("guardiasM1")
	for guardia in guardias:
		var icono = icono_guardia_escena.instantiate()
		add_child(icono)
		iconos_guardias.append({
			"guardia": guardia,
			"icono": icono
		})

func _process(_delta):
	jugador_icono.global_position = player.global_position
	
	for par in iconos_guardias:
		par["icono"].global_position = par["guardia"].global_position
