# NoiseManager.gd
extends Node

signal noise_made(noise_position, noise_radius, instigator)

var listeners = {}

# --- No es necesario cambiar nada en esta función ---
func register_listener(listener):
	if not is_instance_valid(listener.guard):
		push_error("Se intentó registrar un NoiseListener pero su variable 'guard' no está asignada.")
		return

	if not listeners.has(listener):
		listeners[listener] = listener.guard.global_position
		# ESTA LÍNEA ES LA CLAVE DE LA AUTOMATIZACIÓN:
		# Conecta la señal 'tree_exited' del listener a nuestra función local.
		listener.tree_exited.connect(_on_listener_exited.bind(listener))

# --- MODIFICA ESTA FUNCIÓN ---
func make_noise(position, radius, noise_instigator):
	# 1. Emitimos la señal como siempre para que los guardias reaccionen
	emit_signal("noise_made", position, radius, noise_instigator)
	
	# 2. AÑADIMOS LA LLAMADA A NUESTRA NUEVA FUNCIÓN DE DIBUJO
	_draw_debug_radius(position, radius)

# --- AÑADE ESTA FUNCIÓN NUEVA AL FINAL DEL SCRIPT ---
func _draw_debug_radius(pos, rad):
	# Creamos un nodo Node2D temporal que usaremos para dibujar
	var circle_drawer = Node2D.new()
	
	# Lo añadimos a la escena actual para que sea visible
	get_tree().current_scene.add_child(circle_drawer)
	
	# Lo movemos a la posición donde ocurrió el ruido
	circle_drawer.global_position = pos
	
	# Conectamos nuestra función de dibujo a la señal "draw" del nodo.
	# Esto dibujará un círculo amarillo semitransparente.
	circle_drawer.draw.connect(func():
		circle_drawer.draw_circle(Vector2.ZERO, rad, Color(1, 1, 0, 0.4))
	) # <--- ¡Asegúrate de cerrar el paréntesis aquí!
		
	# Creamos un temporizador para que el círculo se borre solo después de 0.8 segundos
	var timer = get_tree().create_timer(0.8)
	timer.timeout.connect(circle_drawer.queue_free)


func _on_listener_exited(listener):
	print("Un listener ha salido del árbol. Eliminándolo del registro.")
	# Comprueba si el listener existe en nuestro diccionario y lo borra.
	if listeners.has(listener):
		listeners.erase(listener)
