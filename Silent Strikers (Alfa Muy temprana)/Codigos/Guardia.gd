extends CharacterBody2D

## --- Variables de Movimiento y Navegación ---
var speed = 300
var acceleration = 7.0
var forward
@export var navigation_region: NavigationRegion2D
@export var player: CharacterBody2D
var rotation2 = rotation
@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

## --- Variables de Visión y Detección ---
var vision_range = 300.0
var vision_angle_degrees = 90.0
var wall_collision_mask = 1
@onready var vision_raycast: RayCast2D = $VisionRayCast
@onready var vision_area: Area2D = $Vision

## --- Variables de Estado ---
enum State { PATROLLING, CHASING, SEARCHING }
var current_state = State.PATROLLING
var player_detected = false
var last_known_player_position = Vector2.ZERO

## --- Tiempo de búsqueda ---
var search_duration = 10.0
var search_timer = 0.0

## --- Tiempo de persecución ---
var chase_duration = 8.0
var chasing_timer = 0.0

## --- Dibujo y Animación ---
@export var draw_vision_cone: bool = true
@export var vision_cone_color: Color = Color(1, 1, 0, 0.3)
@onready var animations: AnimatedSprite2D = get_node("AnimatedSprite2D")

func _ready():
	add_to_group("Guardias")
	vision_raycast.add_exception(self)
	vision_raycast.collision_mask = wall_collision_mask | player.collision_layer

	if navigation_region == null:
		print("[ERROR] ¡No se ha asignado un NavigationRegion2D al guardia!")
		set_physics_process(false)
		return
	
	call_deferred("_set_next_patrol_point")

func _physics_process(delta: float):
	forward = (navigation_agent.get_next_path_position() - global_position).normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.RIGHT.rotated(rotation)
	check_vision(forward)
	
	match current_state:
		State.PATROLLING:
			vision_range = 300
			vision_angle_degrees = 90
			speed = 200
			_process_patrolling(delta)
		State.CHASING:
			vision_range = 600
			vision_angle_degrees = 120
			speed = 300
			_process_chasing(delta)
		State.SEARCHING:
			vision_range = 400
			vision_angle_degrees = 90
			speed = 200
			_process_searching(delta)

	var move_dir = velocity.normalized()
	if move_dir != Vector2.ZERO:
		var horizontal = false
		if move_dir.x > 0 and (move_dir.y > -0.3 and move_dir.y < 0.3):
			animations.play("Derecha")
			horizontal = true
		elif move_dir.x < 0 and (move_dir.y > -0.3 and move_dir.y < 0.3):
			animations.play("Izquierda")
			horizontal = true
		if not horizontal:
			if move_dir.y > 0  or (move_dir.y > 0 and move_dir.x < 0) or (move_dir.y > 0 and move_dir.x > 0):
				animations.play("Abajo")
			elif move_dir.y < 0 or (move_dir.y < 0 and move_dir.x < 0) or (move_dir.y < 0 and move_dir.x > 0):
				animations.play("Arriba")
		rotation2 = move_dir.angle()
	
	move_and_slide()
	
	if draw_vision_cone:
		queue_redraw()

func _process_patrolling(delta):
	if navigation_agent.is_navigation_finished():
		_set_next_patrol_point()
	_update_navigation_velocity(delta)

func _process_chasing(delta):
	chasing_timer -= delta
	navigation_agent.target_position = last_known_player_position
	if navigation_agent.is_navigation_finished():
		if not player_detected:
			current_state = State.SEARCHING
			search_timer = search_duration
	_update_navigation_velocity(delta)

func _process_searching(delta):
	search_timer -= delta
	velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)
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

# --- FUNCIÓN DE PATRULLA CORREGIDA ---
func _set_next_patrol_point():
	if navigation_region == null or navigation_region.navigation_polygon == null:
		print("[Guardia] NavigationRegion2D o su polígono no están asignados.")
		return

	var nav_poly = navigation_region.navigation_polygon
	if nav_poly.get_outline_count() == 0:
		print("[Guardia] El NavigationPolygon no tiene contornos definidos.")
		return

	var overall_bounds: Rect2
	var first_outline = nav_poly.get_outline(0)
	if not first_outline.is_empty():
		overall_bounds = Rect2(first_outline[0], Vector2.ZERO)
	else:
		print("[Guardia] El primer contorno de la región de navegación está vacío.")
		return
		
	for i in range(nav_poly.get_outline_count()):
		for point in nav_poly.get_outline(i):
			overall_bounds = overall_bounds.expand(point)

	const MAX_ATTEMPTS = 30
	for i in range(MAX_ATTEMPTS):
		var random_point = Vector2(
			randf_range(overall_bounds.position.x, overall_bounds.end.x),
			randf_range(overall_bounds.position.y, overall_bounds.end.y)
		)

		for outline_index in range(nav_poly.get_outline_count()):
			var polygon_points = nav_poly.get_outline(outline_index)
			
			if Geometry2D.is_point_in_polygon(random_point, polygon_points):
				var map = navigation_region.get_navigation_map()
				var closest_valid_point = NavigationServer2D.map_get_closest_point(map, random_point)
				
				navigation_agent.target_position = closest_valid_point
				return

	print("[Guardia] No se pudo encontrar un punto de patrulla válido después de %d intentos." % MAX_ATTEMPTS)


# (El resto de funciones no necesitan cambios)

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
			if vision_raycast.is_colliding() and vision_raycast.get_collider() == player:
				detected_now = true
		
		if chasing_timer > 0:
			detected_now = true

	if detected_now:
		last_known_player_position = player.global_position
		current_state = State.CHASING

	player_detected = detected_now
	if player_detected and not was_detected:
		_on_player_detected()
	elif not player_detected and was_detected:
		_on_player_lost()

func _on_player_detected():
	print("¡Jugador DETECTADO!")
	current_state = State.CHASING
	chasing_timer = chase_duration
	search_timer = 0.0

func _on_player_lost():
	print("¡Jugador Perdido!")

func _draw():
	var half_angle = deg_to_rad(vision_angle_degrees / 2.0)
	var segments = 20
	var points = PackedVector2Array()

	for i in range(segments + 1):
		var angle = -half_angle + ((half_angle) * 2.0 * i / segments)
		points.append(Vector2.RIGHT.rotated(angle + rotation2) * vision_range)

	if points.size() > 0:
		draw_line(Vector2.ZERO, points[0], vision_cone_color, 1.0)
		draw_polyline(points, vision_cone_color, 1.0)
		draw_line(Vector2.ZERO, points[-1], vision_cone_color, 1.0)
