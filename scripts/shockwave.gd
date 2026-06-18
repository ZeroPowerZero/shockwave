extends Node3D

## Scene-Based Shockwave
## Uses GPUParticles3D to spawn multiple distortion waves perfectly billboarded.

@onready var particles: GPUParticles3D = $GPUParticles3D

func _ready() -> void:
	if not particles.emitting:
		particles.emitting = true

func initialize(hit_position: Vector3, _surface_normal: Vector3) -> void:
	global_position = hit_position
	# Particles will automatically start emitting on _ready,
	# and they automatically billboard via their shader material!

func _process(_delta: float) -> void:
	# Clean up the scene once the particles finish emitting and all particles die
	if not particles.emitting:
		queue_free()
