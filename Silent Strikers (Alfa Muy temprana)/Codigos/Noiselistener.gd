# NoiseListener.gd
extends Node

# Referencia al guardia al que pertenece este oyente.
@export var guard: CharacterBody2D 

func _ready():
	# La línea de abajo es la importante. ¿Es NoiseManager o Noisemanager?
	# Corrígelo si es necesario.
	Noisemanager.register_listener(self) 
	Noisemanager.noise_made.connect(_on_noise_made)
	
	# AÑADE ESTA LÍNEA PARA DEPURAR:
	print(guard.name + ": NoiseListener listo y conectado.")
	
# Esta función se activa cada vez que NoiseManager emite la señal "noise_made".
func _on_noise_made(noise_position, noise_radius, instigator):
	# Añadimos una comprobación para asegurarnos de que la variable 'guard' está asignada.
	if not is_instance_valid(guard):
		return
		
	# Comprobamos que el guardia no sea quien ha hecho el ruido.
	if instigator == guard:
		return

	# Calculamos la distancia desde la POSICIÓN DEL GUARDIA hasta el origen del ruido.
	var distance_to_noise = guard.global_position.distance_to(noise_position)

	# Si el ruido está dentro del radio de audición...
	if distance_to_noise <= noise_radius:
		# ¡El guardia ha escuchado algo!
		print(guard.name + " ha escuchado un ruido en " + str(noise_position))
		
		# Ejemplo de lógica para el guardia:
		guard.look_at(noise_position)
