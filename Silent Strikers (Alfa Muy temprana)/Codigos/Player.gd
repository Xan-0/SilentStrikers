extends CharacterBody2D

#Hay spawns diferentes para los items y potenciadores, con posiciones por defecto pero aleatorias
#no deberían de poder spawnear 2 veces en el mismo lugar
#en el código del guardia se puso un hit_cooldown, se reinicia cada vez que el jugador pierde vida

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
var potenciador_duplicado: Area2D #instancia duplicada del potenciador
var item_duplicado: Area2D #instancia duplicada del item robable
var mapa: Node2D
#colocar manuealmente los puntos posibles de spawn
@export var spawn_points_it: Array[NodePath] = []
@export var spawn_points_pd: Array[NodePath] = []
var spawn_index = 0
var invisibilidad_usada = false #para que el cooldown empiece a correr sólo cuando se usó
var item_recogido = false #para que se cambie la posicion del item robable
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	Singleton.registrar_player(self)
	salud = 3
	jugador = get_node(".")
	mapa = get_node("..")
	puntaje = 0
	muerto = false

# Actualización del movimiento y las animaciones
func _process(delta):
	if muerto:
		return
	
	velocity = Vector2()
	if invisible():
		invisibility_time -= delta
	if invisibility_time <= 0:
		invisibility_time = 5
		jugador.collision_layer = 1|2|3
		modulate.a = 1
		potenciador_duplicado = preload("res://Escenas/potenciador.tscn").instantiate()
		mapa.add_child(potenciador_duplicado)
		potenciador_duplicado.scale = Vector2(0.3, 0.3)
		_set_next_spawn_point_pd()
		invisibilidad_usada = false
	
	if item_recogido:
		item_recogido = false
		item_duplicado = preload("res://Escenas/item.tscn").instantiate()
		mapa.add_child(item_duplicado)
		item_duplicado.scale = Vector2(0.2, 0.2)
		_set_next_spawn_point_it()

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
	
	update_animation()


	move_and_slide()

func update_animation():
	if velocity.length() > 0:
		animated_sprite.play()
		if velocity.x != 0:
			animated_sprite.animation = "Derecha" 
			animated_sprite.flip_h = velocity.x < 0
		elif velocity.y != 0:
			if velocity.y > 0:
				animated_sprite.animation = "Abajo"
			else:
				animated_sprite.animation = "Arriba"
	else:
		animated_sprite.stop()

func aumentar_puntaje(cantidad):
	puntaje += cantidad
	print("Puntaje actual: ", puntaje)
	if puntaje >= puntaje_win:
		game = true
		print("Se banco")
		get_tree().change_scene_to_file("res://Escenas/victory_screen.tscn")

func perder_salud(cantidad):
	salud -= cantidad
	print("Salud actual: ", salud)
	if salud <= 0:
		muerto = true
		print("gg.")
		get_tree().change_scene_to_file("res://Escenas/defeat_screen.tscn")
	
func aumentar_velocidad(cantidad):
	if muerto or speed >= velMax:
		speed = velMax
		return
	speed += cantidad * initial_speed
	print("Velocidad actual: ", speed)

#hace que el jugador sea indetectable y cambia la opacidad del sprite
func transparentar(transparencia):
	jugador.collision_layer = 0
	modulate.a = transparencia
	invisibilidad_usada = true

func invisible():
	return invisibilidad_usada

func recoger():
	item_recogido = true

func _set_next_spawn_point_pd():
	if spawn_points_pd.size() == 0:
		return
	var new_index = randi_range(0, spawn_points_pd.size()-1)
	if spawn_index != new_index:
		spawn_index = new_index
	else:
		spawn_index -= 2
	
	var spawn_node = get_node_or_null(spawn_points_pd[spawn_index])
	if spawn_node:
		potenciador_duplicado.position = spawn_node.global_position

func _set_next_spawn_point_it():
	if spawn_points_it.size() == 0:
		return
	var new_index = randi_range(0, spawn_points_it.size()-1)
	if spawn_index != new_index:
		spawn_index = new_index
	else:
		spawn_index -= 2
	
	var spawn_node = get_node_or_null(spawn_points_it[spawn_index])
	if spawn_node:
		item_duplicado.position = spawn_node.global_position
