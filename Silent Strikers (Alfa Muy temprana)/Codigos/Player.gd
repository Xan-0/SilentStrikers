extends CharacterBody2D
var puntaje 
var speed = 500
var initial_speed = 500
@export var velMax = 750
var salud
var muerto: bool = false # Para cambiar el salud <= 0
var puntaje_win = 1000 # La cantidad de pts para ganar
var game = false # Para ver si la partida termino o sigue
var invisibility_time = 5

var jugador: CharacterBody2D
var potenciador: Area2D
var potenciador_duplicado: Area2D #instancia duplicada del potenciador
var mapa: Node2D
@export var spawn_points: Array[NodePath] = []
var spawn_index = 0
var invisibilidad_usada = false #para que el cooldown empiece a correr sólo cuando se usó

func _ready():
	salud = 3
	jugador = get_node(".")
	mapa = get_node("..")
	potenciador = get_node("../Area2D")
	potenciador_duplicado = preload("res://Escenas/potenciador.tscn").instantiate()
	mapa.agregar(potenciador_duplicado)
	potenciador_duplicado.scale = Vector2(0.39,0.39)
	potenciador_duplicado.position = Vector2(-81.0,248.0)
	puntaje = 0
	muerto = false

# Actualización del movimiento
func _process(delta):
	if muerto:
		return
	
	velocity = Vector2()
	if invisibilidad_usada:
		invisibility_time-=delta
	if invisibility_time <= 0:
		invisibility_time = 5
		jugador.collision_layer = 1|2|3
		modulate.a = 1
		potenciador_duplicado = preload("res://Escenas/potenciador.tscn").instantiate()
		mapa.agregar(potenciador_duplicado)
		potenciador_duplicado.scale = Vector2(0.39,0.39)
		_set_next_spawn_point()
		invisibilidad_usada = false
		


	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1

	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1
		
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed

	move_and_slide()
	
func aumentar_puntaje(cantidad):
	puntaje += cantidad
	print("Puntaje actual: ", puntaje)
	if puntaje >= puntaje_win:
		game = true
		print("Se banco")
		## HAY QUE CREAR LA ESCENA WIN O COMO LO VAMOS A HACER T.T
		get_tree().change_scene_to_file("res://Escenas/victory_screen.tscn")

func perder_salud(cantidad):
	salud -= cantidad
	print("Salud actual: ", salud)
	if salud <= 0:
		muerto = true
		print("gg.")
		## Podriamos repetir o hacer una escena para q repita el mapa o mande al menu
		get_tree().change_scene_to_file("res://Escenas/defeat_screen.tscn")
	
func aumentar_velocidad(cantidad):
	if muerto or speed >= velMax: 
		speed = velMax
		return
	speed += cantidad * initial_speed
	print("Velocidad actyal: ", speed)
#hace que el jugador sea indetectable y cambia la opacidad del sprite
func transparentar(transparencia):
	jugador.collision_layer = 0
	modulate.a = transparencia
	invisibilidad_usada = true

func invisible():
	return invisibilidad_usada

#misma función que en Guardia.gd
func _set_next_spawn_point():
	if spawn_points.size() == 0:
		return
	var spawn_node = get_node_or_null(spawn_points[spawn_index])
	if spawn_node:
		potenciador_duplicado.position = spawn_node.global_position
	spawn_index = (spawn_index + 1) % spawn_points.size()
