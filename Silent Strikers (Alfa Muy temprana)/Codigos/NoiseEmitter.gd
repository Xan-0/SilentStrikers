# NoiseEmitter.gd
extends Node

# El radio por defecto del ruido que emite este objeto.
@export var noise_radius: float = 300.0

# Una referencia a quién está haciendo el ruido (para que los guardias no se asusten de sus propios pasos).
@export var instigator: Node2D

func _ready():
	if not instigator:
		instigator = get_parent() # Por defecto, el instigador es el padre del emisor.

# Función para emitir un ruido.
func emit_noise():
	if not is_instance_valid(instigator):
		return
		
	# Llama a la función global del NoiseManager.
	Noisemanager.make_noise(instigator.global_position, noise_radius, instigator)

# Puedes personalizar esto. Por ejemplo, emitir un ruido con un radio específico.
func emit_custom_noise(radius):
	if not is_instance_valid(instigator):
		return
		
	Noisemanager.make_noise(instigator.global_position, radius, instigator)
