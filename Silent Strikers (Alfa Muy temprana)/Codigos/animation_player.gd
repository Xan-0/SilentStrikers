extends AnimationPlayer
func _process(delta):
	if Input.is_action_pressed("ui_right"):
		play("Derecha")
	if Input.is_action_pressed("ui_left"):
		play("Izquierda")

	if Input.is_action_pressed("ui_down"):
		play("Abajo")
	if Input.is_action_pressed("ui_up"):
		play("Arriba")
		
