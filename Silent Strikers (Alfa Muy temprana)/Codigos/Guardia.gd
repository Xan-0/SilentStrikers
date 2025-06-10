extends CharacterBody2D

# ===================================================================
# SCRIPT DE GUARDIA - VERSIÓN FINAL, COMPLETA Y FUNCIONAL
# ===================================================================

# --- ESTADOS DE LA IA ---
enum State { PATROLLING, CHASING, SEARCHING }

# --- VARIABLES CONFIGURABLES EN EL EDITOR ---
@export_group("Patrullaje Dinámico")
@export var patrol_area_node: NodePath # Para asignar nuestra ZonaDePatrulla
@export var patrol_idle_duration = 3.0 # Segundos que espera antes de buscar otro punto
@export_group("Stats Base")
@export var patrol_speed = 150.0
@export var chase_speed = 300.0
@export var acceleration = 8.0

@export_group("Vision")
@export var patrol_vision_range = 350.0
@export var patrol_vision_angle = 90.0
@export_group("Tiempos")
@export var chase_duration = 8.0  # Tiempo que persigue tras perderte de vista
@export var search_duration = 5.0 # Tiempo que se queda buscando

# --- NODOS HIJOS REQUERIDOS ---
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var vision_raycast: RayCast2D = $VisionRayCast
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var vision_polygon: Polygon2D = $VisionPolygon
@onready var debug_label: Label = $DebugLabel

# --- VARIABLES INTERNAS ---
var player: CharacterBody2D
var current_state = State.PATROLLING
var last_known_player_position = Vector2.ZERO
var facing_direction = Vector2.DOWN # Dirección persistente para la visión
var chasing_timer = 0.0
var search_timer = 0.0
var patrol_area: Area2D
var patrol_idle_timer = 0.0

## --- Variables de Visión y Detección ---
var vision_range = 300.0
var vision_angle_degrees = 90.0

# --- AÑADE ESTAS CUATRO LÍNEAS AQUÍ ---
var chase_vision_range = 500.0
var chase_vision_angle = 120.0
# -----------------------------------------

var wall_collision_mask = 1
@onready var vision_area: Area2D = $Vision


# ===================================================================
# FUNCIONES PRINCIPALES DE GODOT
# ===================================================================
func _ready():
	player = get_node_or_null("../Ladron")
	if patrol_area_node:
		patrol_area = get_node_or_null(patrol_area_node)
	if not patrol_area:
		print_rich("[color=yellow]ADVERTENCIA: No se asignó un área de patrullaje. El guardia se quedará quieto.[/color]")
	if not player:
		print_rich("[color=red]ERROR CRÍTICO: No se encontró el nodo del Ladrón. La IA se desactivará.[/color]")
		set_physics_process(false)
		return
	
	add_to_group("Guardias")
	vision_raycast.add_exception(self)
	# Asume que las paredes están en la capa 1 y el jugador en la capa 2.
	vision_raycast.collision_mask = 1 | 2
	_enter_patrol_state()

func _physics_process(delta: float):
	# El ciclo de la IA es: PERCIBIR -> DECIDIR -> ACTUAR
	var can_see_player_now = _check_vision()
	_update_debug_info()
	
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
	
	_update_animations_and_facing_direction()
	_update_vision_cone_visuals()

# ===================================================================
# LÓGICA DE CADA ESTADO
# ===================================================================
func _enter_patrol_state():
	current_state = State.PATROLLING
	# Forzamos a que busque un destino la primera vez, sin esperar.
	_set_new_random_destination() 
	print("Entrando en estado: PATRULLA DINÁMICA")

func _enter_chase_state():
	current_state = State.CHASING
	chasing_timer = chase_duration
	if player and _check_vision(): # Solo actualiza si lo ve en este instante
		last_known_player_position = player.global_position

func _enter_search_state():
	current_state = State.SEARCHING
	search_timer = search_duration
	navigation_agent.target_position = last_known_player_position

func _act_patrolling(delta):
	# Si hemos llegado a nuestro destino...
	if navigation_agent.is_navigation_finished():
		# ...detenemos al guardia y activamos el timer de descanso.
		velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)
		patrol_idle_timer -= delta
		
		# Cuando el timer de descanso llega a cero, busca un nuevo destino.
		if patrol_idle_timer <= 0:
			_set_new_random_destination()
	else:
		# Si todavía no hemos llegado, nos seguimos moviendo.
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
# FUNCIONES DE APOYO (MOVIMIENTO, VISIÓN, ETC.)
# ===================================================================
func _move_towards_target(current_speed, delta):
	if navigation_agent.is_target_reachable():
		var direction = global_position.direction_to(navigation_agent.get_next_path_position())
		velocity = velocity.lerp(direction * current_speed, acceleration * delta)
	else:
		velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)
	move_and_slide()

func _set_new_random_destination():
	print("--- Buscando nuevo destino de patrulla... ---")
	if not patrol_area: 
		print_rich("[color=red]ERROR: 'patrol_area' no está asignada. El guardia no se puede mover.[/color]")
		return

	# 1. Obtenemos los límites del área de patrullaje
	var patrol_shape = patrol_area.get_node_or_null("CollisionShape2D")
	if not patrol_shape:
		print_rich("[color=red]ERROR: No se encontró 'CollisionShape2D' dentro del área de patrulla.[/color]")
		return
		
	var bounds = patrol_shape.shape.get_rect()
	
	# 2. Elegimos un punto X e Y aleatorio
	var random_point = Vector2(
		randf_range(bounds.position.x, bounds.end.x),
		randf_range(bounds.position.y, bounds.end.y)
	)
	var global_random_point = patrol_area.to_global(random_point)
	print("Punto aleatorio generado: ", global_random_point)
	
	# 3. Ajustamos el punto a la zona caminable más cercana
	var map = get_world_2d().navigation_map
	var safe_point = NavigationServer2D.map_get_closest_point(map, global_random_point)
	print("Punto seguro en navmesh: ", safe_point)
	
	# 4. Asignamos el nuevo destino y reseteamos el timer
	navigation_agent.target_position = safe_point
	patrol_idle_timer = patrol_idle_duration
	print("--- Nuevo objetivo asignado. ---")



func _check_vision() -> bool:
	if not player: return false
	
	var vision_range_current = patrol_vision_range
	if current_state == State.CHASING:
		vision_range_current = chase_vision_range
		
	var vector_to_player = player.global_position - global_position
	if vector_to_player.length() > vision_range_current: return false
	
	vision_raycast.target_position = vector_to_player
	vision_raycast.force_raycast_update()

	var vision_angle_current = patrol_vision_angle
	if current_state == State.CHASING:
		vision_angle_current = chase_vision_angle

	if facing_direction.dot(vector_to_player.normalized()) < cos(deg_to_rad(vision_angle_current / 2.0)):
		return false
	
	if not vision_raycast.is_colliding() or vision_raycast.get_collider() != player:
		return false
	
	return true

func _update_animations_and_facing_direction():
	if velocity.length() > 10:
		facing_direction = velocity.normalized()
		var angle_deg = rad_to_deg(facing_direction.angle())
		if angle_deg > -45 and angle_deg <= 45: animations.play("Derecha")
		elif angle_deg > 45 and angle_deg <= 135: animations.play("Abajo")
		elif angle_deg > 135 or angle_deg <= -135: animations.play("Izquierda")
		else: animations.play("Arriba")
	else:
		animations.stop()

func _update_vision_cone_visuals():
	var vision_range = patrol_vision_range
	if current_state == State.CHASING:
		vision_range = chase_vision_range
	var vision_angle = patrol_vision_angle
	if current_state == State.CHASING:
		vision_angle = chase_vision_angle
	
	var points = PackedVector2Array([Vector2.ZERO])
	var segments = 20
	var half_angle_rad = deg_to_rad(vision_angle / 2.0)
	
	for i in range(segments + 1):
		var angle = facing_direction.angle() - half_angle_rad + (half_angle_rad * 2 * i / segments)
		points.append(Vector2.RIGHT.rotated(angle) * vision_range)
		
	vision_polygon.polygon = points
	vision_polygon.color = Color(1, 1, 0, 0.2)

# ===================================================================
# FUNCIÓN PÚBLICA PARA REACCIONAR AL RUIDO
# ===================================================================
func hear_noise(noise_position: Vector2):
	if current_state == State.PATROLLING:
		var map = get_world_2d().navigation_map
		var closest_valid_point = NavigationServer2D.map_get_closest_point(map, noise_position)
		last_known_player_position = closest_valid_point
		_enter_chase_state()
		
func _update_debug_info():
	# Formateamos el texto que queremos mostrar.
	# El \n crea un salto de línea. 
	var state_text = "ESTADO: %s" % State.keys()[current_state]
	var chase_timer_text = "Chase Timer: %.1f" % chasing_timer
	var search_timer_text = "Search Timer: %.1f" % search_timer

	# Unimos todo en un solo string y lo asignamos al texto de la etiqueta.
	debug_label.text = "%s\n%s\n%s" % [state_text, chase_timer_text, search_timer_text]
