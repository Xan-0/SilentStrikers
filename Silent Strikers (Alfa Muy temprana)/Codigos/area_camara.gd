# Camera.gd
extends Area2D

signal alerta_enviada(posicion)

func _on_Area2D_body_entered(body):
	if body.name == "Ladron":  # o cualquier condición que dispare la alerta
		return
