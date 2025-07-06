extends Node2D

#signal revenge_response(accepted: bool)

#func _ready():
	# Conectar los botones
	#$UI/Panel2/VBoxContainer/RevengeButton.pressed.connect(_on_accept_pressed)
	#$UI/Panel2/VBoxContainer/RejectButton.pressed.connect(_on_reject_pressed)

#func _on_accept_pressed():
	#emit_signal("revenge_response", true)
	#hide() # Opcional: ocultar popup después de aceptar

#func _on_reject_pressed():
	#emit_signal("revenge_response", false)
	#hide() # Opcional: ocultar popup después de rechazar
	
#Desde otro script se puede hacer:
#var popup = preload("res://scenes/tu_popup.tscn").instantiate()
#popup.revenge_response.connect(_on_revenge_response)

#func _on_revenge_response(accepted: bool):
	#if accepted:
		#print("El jugador aceptó la revancha")
	#else:
		#print("El jugador rechazó la revancha")
