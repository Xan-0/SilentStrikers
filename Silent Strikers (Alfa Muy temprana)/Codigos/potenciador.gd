extends Area2D

var player_in_range = false
@export var potenciado = 0.25  # Cuántos puntos da este ítem
@onready var jugador = Singleton.devolver_player()

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

#Si el jugador esta en rango y presiona "interactuar", se recoge el item, dependiendo de la textura se elige su función.
func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interactuar"):
		match $Sprite2D.texture:
			preload("res://assets/Imagenes/item_robable_01.png"): #cambiar por monster
				invisibilizar()
			preload("res://assets/Imagenes/item_robable_02.png"): #cambiar por poción
				potenciar()
			_:
				print("Sprite potenciador inválido")
		
		queue_free()

#Llama a la funcion aumentar puntaje del ladron
func potenciar():
	jugador.aumentar_velocidad(potenciado)

func invisibilizar():
	jugador.transparentar(0.5)
