extends AnimationPlayer

func _process(delta):
	var vertical = false
	if Input.is_action_pressed("ui_down") or (Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_left")) or (Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_right")):
		play("Abajo")
		vertical = true
	elif Input.is_action_pressed("ui_up") or (Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_left")) or (Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_right")):
		play("Arriba")
		vertical = true
	if not vertical:
		if Input.is_action_pressed("ui_right"):
			play("Derecha")
		elif Input.is_action_pressed("ui_left"):
			play("Izquierda")
