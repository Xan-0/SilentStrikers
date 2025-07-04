extends Area2D

var player_in_range = false
@export var potenciado = 0.25  # Cuántos puntos da este ítem

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

#Detecta si el Ladrón entro al rango
func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

#Detecta si el Ladrón salió del rango
func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

#Si el jugador esta en rango y presiona "interactuar", se recoge el item
func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interactuar"):
		potenciar()
		invisibilizar()
		queue_free()

#Llama a la funcion aumentar puntaje del ladron
func potenciar():
	var jugador = get_node("../Player")
	jugador.aumentar_velocidad(potenciado)

func invisibilizar():
	var jugador = get_node("../Player")
	jugador.transparentar(0.5)
