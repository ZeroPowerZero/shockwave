extends Node3D

## Shockwave Effect
## Creates a transparent 3D shockwave that distorts the screen.
## It is billboarded to always face the player.

@export var max_radius: float = 20.0
@export var expand_speed: float = 10.0
@export var lifetime: float = 0.7

var _time: float = 0.0
var _quad_mesh: MeshInstance3D
var _material: ShaderMaterial
var _camera: Camera3D

const SHADER_CODE = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float strength = 0.1;
uniform float thickness = 0.15;
uniform float alpha = 1.0;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	
	// Smooth circle mask to cut off the quad edges
	float circle = smoothstep(0.5, 0.49, dist);
	
	// Ring mask for the distortion
	float ring = smoothstep(0.5, 0.5 - thickness, dist) * smoothstep(0.5 - thickness * 2.0, 0.5 - thickness, dist);
	
	// Direction outward from center
	vec2 dir = normalize(uv);
	
	// Screen distortion offset
	vec2 offset = dir * ring * strength * alpha;
	
	// Sample the screen behind this object
	vec3 col = texture(screen_texture, SCREEN_UV - offset).rgb;
	
	ALBEDO = col;
	ALPHA = circle;
}
"""

func _ready() -> void:
	_camera = get_viewport().get_camera_3d()
	_build_shockwave_quad()

func initialize(hit_position: Vector3, _surface_normal: Vector3) -> void:
	global_position = hit_position
	# We ignore _surface_normal since we billboard it to the camera

func _build_shockwave_quad() -> void:
	_quad_mesh = MeshInstance3D.new()
	add_child(_quad_mesh)
	
	var quad = QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	_quad_mesh.mesh = quad
	
	var shader = Shader.new()
	shader.code = SHADER_CODE
	
	_material = ShaderMaterial.new()
	_material.shader = shader
	_material.set_shader_parameter("strength", 0.06)
	_material.set_shader_parameter("thickness", 0.12)
	_quad_mesh.material_override = _material

func _process(delta: float) -> void:
	_time += delta
	var t = clamp(_time / lifetime, 0.0, 1.0)
	
	# Expand diameter (radius * 2)
	var current_scale = t * max_radius * 2.0
	_quad_mesh.scale = Vector3(current_scale, current_scale, current_scale)
	
	# Fade out distortion strength over time
	var alpha_val = (1.0 - t) * (1.0 - t)
	_material.set_shader_parameter("alpha", alpha_val)
	
	# Billboard: face the camera
	if is_instance_valid(_camera):
		var cam_pos = _camera.global_position
		if global_position.distance_to(cam_pos) > 0.01:
			var up = Vector3.UP
			# Prevent look_at error if looking straight up or down
			if abs(global_position.direction_to(cam_pos).y) > 0.99:
				up = Vector3.RIGHT
			look_at(cam_pos, up)
			# QuadMesh faces +Z natively, look_at points -Z at target. So we rotate 180.
			rotate_object_local(Vector3.UP, PI)
			
	if _time >= lifetime:
		queue_free()
