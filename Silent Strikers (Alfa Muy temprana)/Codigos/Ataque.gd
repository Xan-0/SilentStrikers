extends Area2D

var player_in_range = false

func _ready():
	body_entered.connect(_on_body_entered)

#Detecta si el Ladrón entro al rango
func _on_body_entered(body):
	if body.name == "Ladron":
		body.perder_salud(1)
