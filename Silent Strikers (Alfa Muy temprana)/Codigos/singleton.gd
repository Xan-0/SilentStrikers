extends Node

var player_nodo = null

func _ready():
	set_process(false)

func registrar_player(player):
	player_nodo = player
	
func devolver_player():
	return player_nodo
