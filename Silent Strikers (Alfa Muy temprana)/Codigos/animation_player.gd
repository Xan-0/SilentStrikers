extends AnimationPlayer

func _process(delta):
	# Usamos una bandera para saber si se ha detectado movimiento vertical.
	var vertical_movement_detected = false
	
	# Primero, revisamos la entrada vertical.
	if Input.is_action_pressed("ui_down"):
		play("Abajo")
		vertical_movement_detected = true
	elif Input.is_action_pressed("ui_up"):
		play("Arriba")
		vertical_movement_detected = true
	
	# Si NO se detectó movimiento vertical, entonces revisamos el horizontal.
	if not vertical_movement_detected:
		if Input.is_action_pressed("ui_right"):
			play("Derecha")
		elif Input.is_action_pressed("ui_left"):
			play("Izquierda")