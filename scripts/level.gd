extends Node3D

## Main Level Script — Prototype Level Manager
## Sets up the arena, spawns the player, and manages environment.

func _ready() -> void:
	# Atmosphere
	RenderingServer.set_default_clear_color(Color(0.04, 0.04, 0.08))
