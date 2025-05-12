extends AnimationPlayer
func _process(delta):
	if Input.is_action_pressed("ui_right"):
		play("Derecha")
	if Input.is_action_pressed("ui_left"):
		play("Izquierda")

	if Input.is_action_pressed("ui_down") or (Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_left")) or (Input.is_action_pressed("ui_down") and Input.is_action_pressed("ui_right")):
		play("Abajo")
	if Input.is_action_pressed("ui_up") or (Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_left")) or (Input.is_action_pressed("ui_up") and Input.is_action_pressed("ui_right")):
		play("Arriba")
		
