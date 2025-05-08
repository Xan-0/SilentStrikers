extends CharacterBody2D

## --- Variables de Movimiento y Navegación ---
var speed = 300
var acceleration = 7.0
var forward
@export var patrol_points: Array[NodePath] = []
@export var player: CharacterBody2D 

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

## --- Variables de Estado ---
enum State { PATROLLING, CHASING, SEARCHING }
var current_state = State.PATROLLING
var patrol_index = 0
var player_detected = false
var last_known_player_position = Vector2.ZERO

## --- Tiempo de búsqueda ---
var search_duration = 0.0 # Segundos que espera buscando
var search_timer = 0.0


func _ready():
	_set_next_patrol_point()

func _physics_process(delta):
	if not is_instance_valid(navigation_agent):
		return

	match current_state:
		State.PATROLLING:
			_process_patrolling(delta)
		State.CHASING:
			_process_chasing(delta)
		State.SEARCHING:
			_process_searching(delta)

	# Rotación
	var move_dir = velocity.normalized()
	if move_dir != Vector2.ZERO:
		rotation = move_dir.angle()
	
	move_and_slide()
	
	forward = (navigation_agent.get_next_path_position() - global_position).normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT.rotated(rotation) # fallback si no hay camino
	

func _process_patrolling(delta):
	# Patrulla normal
	if navigation_agent.is_navigation_finished():
		_set_next_patrol_point()
	_update_navigation_velocity(delta)


func _process_chasing(delta):
	navigation_agent.target_position = last_known_player_position
	if navigation_agent.is_navigation_finished():
		# Si llegó a la última posición conocida y no ve al jugador, inicia búsqueda
		if not player_detected:
			current_state = State.SEARCHING
			search_timer = search_duration

	_update_navigation_velocity(delta)


func _process_searching(delta):
	search_timer -= delta
	velocity = velocity.lerp(Vector2.ZERO, acceleration * delta) # Se queda quieto
	if search_timer <= 0.0:
		current_state = State.PATROLLING
		_set_next_patrol_point()


func _update_navigation_velocity(delta):
	if not navigation_agent.is_navigation_finished():
		var next_pos = navigation_agent.get_next_path_position()
		var dir = (next_pos - global_position).normalized()
		velocity = velocity.lerp(dir * speed, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)


func _set_next_patrol_point():
	if patrol_points.size() == 0:
		return
	var patrol_node = get_node_or_null(patrol_points[patrol_index])
	if patrol_node:
		navigation_agent.target_position = patrol_node.global_position
	patrol_index = (patrol_index + 1) % patrol_points.size()

func _on_player_detected():
	print("¡Jugador DETECTADO!")
	current_state = State.CHASING


func _on_player_lost():
	print("Jugador PERDIDO.")
	# No cambia a patrulla inmediatamente, entra en SEARCHING al llegar al último punto
