extends Node3D

## Shockwave Effect
## Creates an expanding 3D ring shockwave when a bullet hits a surface.
## The ring expands outward, fades, and then frees itself.

@export var max_radius: float = 20.0
@export var expand_speed: float = 10.0
@export var lifetime: float = 0.7

var _time: float = 0.0
var _ring_mesh: MeshInstance3D
var _material: StandardMaterial3D
var _normal: Vector3 = Vector3.UP

const RING_SEGMENTS = 64

func _ready() -> void:
	_build_shockwave_ring()
	_build_inner_glow()
	_build_particles()

func initialize(hit_position: Vector3, surface_normal: Vector3) -> void:
	global_position = hit_position
	_normal = surface_normal.normalized()
	# Align the shockwave ring to the surface normal
	if _normal != Vector3.UP:
		var axis = Vector3.UP.cross(_normal).normalized()
		var angle = Vector3.UP.angle_to(_normal)
		if axis.length() > 0.001:
			rotation = Vector3.ZERO
			rotate(axis, angle)
	else:
		rotation = Vector3.ZERO

func _build_shockwave_ring() -> void:
	_ring_mesh = MeshInstance3D.new()
	add_child(_ring_mesh)
	
	# Use a torus mesh for the ring
	var torus = TorusMesh.new()
	torus.inner_radius = 0.0
	torus.outer_radius = 0.05
	torus.rings = RING_SEGMENTS
	torus.ring_segments = 8
	_ring_mesh.mesh = torus
	
	_material = StandardMaterial3D.new()
	_material.emission_enabled = true
	_material.emission = Color(0.3, 0.7, 1.0)
	_material.emission_energy_multiplier = 4.0
	_material.albedo_color = Color(0.3, 0.8, 1.0, 0.9)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ring_mesh.material_override = _material

func _build_inner_glow() -> void:
	# Inner sphere flash
	var sphere_instance = MeshInstance3D.new()
	add_child(sphere_instance)
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.2
	sphere_mesh.height = 0.4
	sphere_instance.mesh = sphere_mesh
	
	var sphere_mat = StandardMaterial3D.new()
	sphere_mat.emission_enabled = true
	sphere_mat.emission = Color(0.5, 0.9, 1.0)
	sphere_mat.emission_energy_multiplier = 8.0
	sphere_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
	sphere_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	sphere_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sphere_instance.material_override = sphere_mat
	
	# Fade the inner glow quickly
	var tween = create_tween()
	tween.tween_property(sphere_mat, "albedo_color:a", 0.0, 0.15)
	tween.tween_callback(sphere_instance.queue_free)

func _build_particles() -> void:
	# Spark particles at the impact point
	var particles = GPUParticles3D.new()
	add_child(particles)
	particles.amount = 24
	particles.lifetime = 0.5
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.emitting = true
	
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 80.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 6.0
	pm.gravity = Vector3(0, -9.8, 0)
	pm.scale_min = 0.05
	pm.scale_max = 0.12
	pm.color = Color(0.4, 0.85, 1.0)
	particles.process_material = pm
	
	var spark_mesh = SphereMesh.new()
	spark_mesh.radius = 0.04
	spark_mesh.height = 0.08
	var spark_mat = StandardMaterial3D.new()
	spark_mat.emission_enabled = true
	spark_mat.emission = Color(0.4, 0.85, 1.0)
	spark_mat.emission_energy_multiplier = 6.0
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_mesh.material = spark_mat
	particles.draw_pass_1 = spark_mesh

func _process(delta: float) -> void:
	_time += delta
	var t = clamp(_time / lifetime, 0.0, 1.0)
	
	# Expand the ring radius
	var current_radius = t * max_radius
	_ring_mesh.scale = Vector3(current_radius, 1.0, current_radius)
	
	# Fade out alpha as it expands
	var alpha = (1.0 - t) * (1.0 - t)
	_material.albedo_color.a = alpha * 0.9
	_material.emission_energy_multiplier = (1.0 - t) * 4.0
	
	if _time >= lifetime:
		queue_free()
