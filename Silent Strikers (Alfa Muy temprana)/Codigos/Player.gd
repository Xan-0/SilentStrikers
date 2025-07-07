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

# === SISTEMA DE HECHIZOS SIMPLES ===
var spell_z_cost = 100      # Costo hechizo Z
var spell_x_cost = 500      # Costo hechizo X  
var spell_c_cost = 800      # Costo hechizo C

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
	
	# Conectar señales para recibir hechizos del oponente
	if WebSocketManager:
		WebSocketManager.connect("game_data_received", _on_spell_received)

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

# === SISTEMA DE HECHIZOS SIMPLIFICADO ===

func _input(event):
	if muerto:
		return
		
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Z:
				try_cast_spell_z()
			KEY_X:
				try_cast_spell_x()
			KEY_C:
				try_cast_spell_c()

func try_cast_spell_z():
	if puntaje < spell_z_cost:
		print("❌ Hechizo Z - Puntos insuficientes. Necesitas: ", spell_z_cost, " | Tienes: ", puntaje)
		return
	
	# Restar puntos y enviar hechizo
	puntaje -= spell_z_cost
	send_spell("Z")
	print("🔥 HECHIZO Z ENVIADO! Costo: ", spell_z_cost, " | Puntos restantes: ", puntaje)

func try_cast_spell_x():
	if puntaje < spell_x_cost:
		print("❌ Hechizo X - Puntos insuficientes. Necesitas: ", spell_x_cost, " | Tienes: ", puntaje)
		return
	
	# Restar puntos y enviar hechizo
	puntaje -= spell_x_cost
	send_spell("X")
	print("⚡ HECHIZO X ENVIADO! Costo: ", spell_x_cost, " | Puntos restantes: ", puntaje)

func try_cast_spell_c():
	if puntaje < spell_c_cost:
		print("❌ Hechizo C - Puntos insuficientes. Necesitas: ", spell_c_cost, " | Tienes: ", puntaje)
		return
	
	# Restar puntos y enviar hechizo
	puntaje -= spell_c_cost
	send_spell("C")
	print("💥 HECHIZO C ENVIADO! Costo: ", spell_c_cost, " | Puntos restantes: ", puntaje)

func send_spell(spell_type: String):
	# Enviar hechizo simple al oponente usando send-game-data
	if WebSocketManager:
		var spell_data = {
			"spell": spell_type
		}
		
		WebSocketManager.send_game_data(spell_data)
		print("📡 Hechizo ", spell_type, " enviado: ", spell_data)
		
		# Efecto visual local
		show_spell_cast_effect(spell_type)
	else:
		print("⚠️ WebSocketManager no disponible")

func show_spell_cast_effect(spell: String):
	# Efecto visual simple cuando se envía un hechizo
	match spell:
		"Z":
			modulate = Color.BLUE
		"X":
			modulate = Color.PURPLE
		"C":
			modulate = Color.RED
	
	# Restaurar color después de 1 segundo
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(func(): modulate = Color.WHITE)
	add_child(timer)
	timer.start()

# === RECIBIR HECHIZOS DEL OPONENTE ===

func _on_spell_received(data: Dictionary):
	var spell = data.get("spell", "")
	
	if spell != "":
		print("🎯 Hechizo recibido del oponente: ", spell)
		apply_spell_effect(spell)

func apply_spell_effect(spell: String):
	match spell:
		"Z":
			apply_spell_z_effect()
		"X":
			apply_spell_x_effect()
		"C":
			apply_spell_c_effect()
		_:
			print("⚠️ Hechizo desconocido: ", spell)

func apply_spell_z_effect():
	# Hechizo Z: Ralentizar por 8 segundos
	print("🐌 Has sido ralentizado por el oponente")
	
	var original_speed = speed
	speed = max(100, speed - 200)  # Reducir velocidad
	modulate = Color.CYAN
	
	# Timer para restaurar
	var timer = Timer.new()
	timer.wait_time = 8.0
	timer.one_shot = true
	timer.timeout.connect(func(): 
		speed = original_speed
		modulate = Color.WHITE
		print("⭐ Efecto de ralentización terminado")
	)
	add_child(timer)
	timer.start()

func apply_spell_x_effect():
	# Hechizo X: Reducir visibilidad por 12 segundos
	print("👁️ Tu visibilidad ha sido reducida por el oponente")
	
	modulate.a = 0.3  # Más transparente
	
	# Timer para restaurar
	var timer = Timer.new()
	timer.wait_time = 12.0
	timer.one_shot = true
	timer.timeout.connect(func(): 
		modulate.a = 1.0
		print("⭐ Efecto de visión reducida terminado")
	)
	add_child(timer)
	timer.start()

var controls_confused = false

func apply_spell_c_effect():
	# Hechizo C: Confundir controles por 10 segundos
	print("🌀 Tus controles han sido confundidos por el oponente")
	
	controls_confused = true
	modulate = Color.MAGENTA
	
	# Timer para restaurar
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.timeout.connect(func(): 
		controls_confused = false
		modulate = Color.WHITE
		print("⭐ Efecto de confusión terminado")
	)
	add_child(timer)
	timer.start()

# === FUNCIONES ORIGINALES ===

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
	
	# Mostrar hechizos disponibles (simple)
	if puntaje >= spell_z_cost:
		print("  ✅ Z disponible (", spell_z_cost, " pts)")
	if puntaje >= spell_x_cost:
		print("  ✅ X disponible (", spell_x_cost, " pts)")
	if puntaje >= spell_c_cost:
		print("  ✅ C disponible (", spell_c_cost, " pts)")
	
	if puntaje >= puntaje_win:
		game = true
		print("¡Ganaste!")
		
		# Enviar victoria usando finish-game
		if WebSocketManager:
			WebSocketManager.finish_game({})
		
		get_tree().change_scene_to_file("res://Escenas/victory_screen.tscn")

func perder_salud(cantidad):
	salud -= cantidad
	print("Salud actual: ", salud)
	if salud <= 0:
		muerto = true
		print("Perdiste")
		
		# La derrota se maneja cuando recibes "game-ended" del oponente
		# No necesitas enviar nada aquí
		
		get_tree().change_scene_to_file("res://Escenas/defeat_screen.tscn")
	
func aumentar_velocidad(cantidad):
	if muerto or speed >= velMax:
		speed = velMax
		return
	speed += cantidad
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
