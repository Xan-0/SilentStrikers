extends CharacterBody2D

## --- Variables de Movimiento y Navegación ---
var speed = 300
var acceleration = 7.0
var forward
@export var patrol_points: Array[NodePath] = []
@export var player: CharacterBody2D 

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

## --- Variables de Visión y Detección ---
var vision_range = 300.0
var vision_angle_degrees = 90.0
var wall_collision_mask = 1
@onready var vision_raycast: RayCast2D = $VisionRayCast

## --- Variables de Estado ---
enum State { PATROLLING, CHASING, SEARCHING }
var current_state = State.PATROLLING
var patrol_index = 0
var player_detected = false
var last_known_player_position = Vector2.ZERO

## --- Tiempo de búsqueda ---
var search_duration = 2.0 # Segundos que espera buscando
var search_timer = 0.0

## --- Dibujo ---
@export var draw_vision_cone: bool = true
@export var vision_cone_color: Color = Color(1, 1, 0, 0.3)

func _ready():
	vision_raycast.add_exception(self)
	vision_raycast.collision_mask = wall_collision_mask | player.collision_layer

	_set_next_patrol_point()

func _physics_process(delta):
	forward = (navigation_agent.get_next_path_position() - global_position).normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT.rotated(rotation) # fallback si no hay camino
	check_vision(forward)
	
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
	
	if draw_vision_cone:
		queue_redraw()


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

	# ROTACIÓN PARA BUSCAR AL JUGADOR
	var angle_offset = sin(Time.get_ticks_msec() / 300.0) * deg_to_rad(60)
	rotation = angle_offset

	# REEMPLAZA el forward con esta dirección aunque no haya navegación
	forward = Vector2.RIGHT.rotated(rotation)

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


func check_vision(guard_forward_direction: Vector2):
	var was_detected = player_detected
	var detected_now = false

	var dir_to_player = player.global_position - global_position
	var dist = dir_to_player.length()

	if dist <= vision_range:
		var dir_norm = dir_to_player.normalized()
		var dot = guard_forward_direction.dot(dir_norm)
		var limit_dot = cos(deg_to_rad(vision_angle_degrees / 2.0))

		if dot > limit_dot:
			# ACTUALIZA SIEMPRE el raycast
			vision_raycast.target_position = to_local(player.global_position)
			vision_raycast.force_raycast_update()
			if vision_raycast.is_colliding() and vision_raycast.get_collider() == player:
				detected_now = true
				last_known_player_position = player.global_position

	player_detected = detected_now
	if player_detected and not was_detected:
		_on_player_detected()
	elif not player_detected and was_detected:
		_on_player_lost()



func _on_player_detected():
	print("¡Jugador DETECTADO!")
	current_state = State.CHASING
	search_timer = 0.0 

func _on_player_lost():
	print("¡Jugador Perdido¡")

func _draw():
	var half_angle = deg_to_rad(vision_angle_degrees / 2.0)
	var segments = 20
	var points = PackedVector2Array()

	for i in range(segments + 1):
		var angle = -half_angle + (half_angle * 2.0 * i / segments)
		points.append(Vector2.RIGHT.rotated(angle) * vision_range)

	if points.size() > 0:
		draw_line(Vector2.ZERO, points[0], vision_cone_color, 1.0)
		draw_polyline(points, vision_cone_color, 1.0)
		draw_line(Vector2.ZERO, points[-1], vision_cone_color, 1.0)
