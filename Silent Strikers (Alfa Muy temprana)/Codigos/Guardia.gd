extends CharacterBody2D


# --- ESTADOS DE LA IA ---
enum State { PATROLLING, CHASING, SEARCHING }

# --- VARIABLES CONFIGURABLES EN EL EDITOR ---
@export_group("Patrullaje")
@export var patrol_points: Array[NodePath] = [] # Para patrullaje fijo
@export var patrol_area_node: NodePath # Para patrullaje dinámico
@export var patrol_idle_duration = 3.0 # Segundos que espera

@export_group("Stats Base")
@export var patrol_speed = 150.0
@export var chase_speed = 300.0
@export var acceleration = 8.0

@export_group("Vision")
@export var patrol_vision_range = 350.0
@export var patrol_vision_angle = 90.0
@export var chase_vision_range = 500.0
@export var chase_vision_angle = 120.0

@export_group("Tiempos")
@export var chase_duration = 8.0
@export var search_duration = 5.0

# --- NODOS HIJOS REQUERIDOS ---
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var vision_raycast: RayCast2D = $VisionRayCast
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var vision_polygon: Polygon2D = $VisionPolygon
# @onready var debug_label: Label = $DebugLabel # Descomenta si usas la etiqueta de debug

# --- VARIABLES INTERNAS ---
var player: CharacterBody2D
var current_state = State.PATROLLING
var last_known_player_position = Vector2.ZERO
var facing_direction = Vector2.DOWN
var patrol_index = 0
var chasing_timer = 0.0
var search_timer = 0.0
var patrol_area: Area2D
var patrol_idle_timer = 0.0
var player_detected = false # Tu variable de detección
var rotation2 = rotation # Tu variable de rotación para el cono visual

# ===================================================================
# FUNCIONES PRINCIPALES DE GODOT
# ===================================================================

func _ready():
	player = get_node_or_null("../Ladron")
	if not player:
		print_rich("[color=red]ERROR: Nodo 'Ladron' no encontrado.[/color]")
		set_physics_process(false)
		return
	
	add_to_group("Guardias")
	vision_raycast.add_exception(self)
	vision_raycast.collision_mask = 1 | 2 # Asume: Capa 1 Mundo, Capa 2 Jugador
	
	# Iniciar patrullaje
	_enter_patrol_state()

func _physics_process(delta: float):
	# Ciclo de la IA: PERCIBIR -> DECIDIR -> ACTUAR
	var can_see_player_now = _check_vision()
	player_detected = can_see_player_now # Actualizamos tu variable de detección
	
	# --- FASE DE DECISIÓN ---
	match current_state:
		State.PATROLLING:
			if can_see_player_now:
				_enter_chase_state()
		State.CHASING:
			if can_see_player_now:
				last_known_player_position = player.global_position
				chasing_timer = chase_duration
			else:
				chasing_timer -= delta
			
			if chasing_timer <= 0 or (navigation_agent.is_navigation_finished() and not can_see_player_now):
				_enter_search_state()
		State.SEARCHING:
			search_timer -= delta
			if can_see_player_now:
				_enter_chase_state()
			elif search_timer <= 0:
				_enter_patrol_state()

	# --- FASE DE ACCIÓN ---
	match current_state:
		State.PATROLLING:
			_act_patrolling(delta)
		State.CHASING:
			_act_chasing(delta)
		State.SEARCHING:
			_act_searching(delta)
			
	_update_animations_and_rotation(delta)
	_update_vision_cone_visuals()
	# if debug_label: _update_debug_info() # Descomenta si usas la etiqueta de debug

# ===================================================================
# LÓGICA DE CADA ESTADO
# ===================================================================

func _enter_patrol_state():
	current_state = State.PATROLLING
	# Decide si usar patrullaje dinámico o fijo
	if patrol_area_node:
		patrol_idle_timer = 0 # Para que busque un punto aleatorio inmediatamente
	else:
		_set_next_patrol_point() # Usa los puntos fijos

func _enter_chase_state():
	current_state = State.CHASING
	chasing_timer = chase_duration
	if player and player_detected:
		last_known_player_position = player.global_position

func _enter_search_state():
	current_state = State.SEARCHING
	search_timer = search_duration
	navigation_agent.target_position = last_known_player_position

func _act_patrolling(delta):
	# Lógica para patrullaje dinámico
	if patrol_area_node:
		if navigation_agent.is_navigation_finished():
			velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)
			patrol_idle_timer -= delta
			if patrol_idle_timer <= 0:
				_set_new_random_destination()
		else:
			_move_towards_target(patrol_speed, delta)
	# Lógica para patrullaje por puntos fijos
	else:
		if navigation_agent.is_navigation_finished():
			_set_next_patrol_point()
		_move_towards_target(patrol_speed, delta)

func _act_chasing(delta):
	navigation_agent.target_position = last_known_player_position
	_move_towards_target(chase_speed, delta)

func _act_searching(delta):
	if navigation_agent.is_navigation_finished():
		velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)
	else:
		_move_towards_target(patrol_speed, delta)

# ===================================================================
# FUNCIONES DE APOYO
# ===================================================================

func _move_towards_target(speed, delta):
	if navigation_agent.is_target_reachable():
		var direction = global_position.direction_to(navigation_agent.get_next_path_position())
		velocity = velocity.lerp(direction * speed, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)
	move_and_slide()

func _set_next_patrol_point():
	if patrol_points.is_empty(): return
	patrol_index = (patrol_index + 1) % patrol_points.size()
	var new_target_node = get_node_or_null(patrol_points[patrol_index])
	if new_target_node:
		navigation_agent.target_position = new_target_node.global_position

func _set_new_random_destination():
	if not patrol_area:
		patrol_area = get_node_or_null(patrol_area_node)
		if not patrol_area: return

	var patrol_shape_node = patrol_area.get_node_or_null("CollisionShape2D")
	if not patrol_shape_node: return
	
	var global_bounds = patrol_shape_node.global_transform * patrol_shape_node.shape.get_rect()
	var global_random_point = Vector2(
		randf_range(global_bounds.position.x, global_bounds.end.x),
		randf_range(global_bounds.position.y, global_bounds.end.y)
	)
	
	var map = get_world_2d().navigation_map
	var safe_point = NavigationServer2D.map_get_closest_point(map, global_random_point)
	
	navigation_agent.target_position = safe_point
	patrol_idle_timer = patrol_idle_duration

func _check_vision() -> bool:
	if not player: return false
	
	var vision_range_current = patrol_vision_range
	var vision_angle_current = patrol_vision_angle
	if current_state == State.CHASING:
		vision_range_current = chase_vision_range
		vision_angle_current = chase_vision_angle
		
	var vector_to_player = player.global_position - global_position
	if vector_to_player.length() > vision_range_current: return false
	
	vision_raycast.target_position = vector_to_player
	vision_raycast.force_raycast_update()
	
	if facing_direction.dot(vector_to_player.normalized()) < cos(deg_to_rad(vision_angle_current / 2.0)):
		return false
	
	if not vision_raycast.is_colliding() or vision_raycast.get_collider() != player:
		return false
	
	return true

func _update_animations_and_rotation(delta):
	var move_dir = velocity.normalized()
	if move_dir.length() > 0.1:
		facing_direction = move_dir
		rotation2 = move_dir.angle()
		
		var horizontal = false
		if move_dir.x > 0 and (move_dir.y > -0.3 and move_dir.y < 0.3): animations.play("Derecha")
		elif move_dir.x < 0 and (move_dir.y > -0.3 and move_dir.y < 0.3): animations.play("Izquierda")
		else:
			if move_dir.y > 0: animations.play("Abajo")
			elif move_dir.y < 0: animations.play("Arriba")
	else:
		animations.stop()

func _update_vision_cone_visuals():
	if not vision_polygon: return
	
	var vision_range_current = patrol_vision_range
	var vision_angle_current = patrol_vision_angle
	if current_state == State.CHASING:
		vision_range_current = chase_vision_range
		vision_angle_current = chase_vision_angle
		
	var points = PackedVector2Array([Vector2.ZERO])
	var segments = 20
	var half_angle_rad = deg_to_rad(vision_angle_current / 2.0)
	
	for i in range(segments + 1):
		var angle = facing_direction.angle() - half_angle_rad + (half_angle_rad * 2 * i / segments)
		points.append(Vector2.RIGHT.rotated(angle) * vision_range_current)
		
	vision_polygon.polygon = points
	vision_polygon.color = Color(1, 1, 0, 0.2)