extends CharacterBody3D

## FPS Player Controller
## Full movement: WASD, sprint, jump, crouch, mouse-look
## Shoots raycasts and spawns shockwaves on impact

# Movement
@export var walk_speed: float = 6.0
@export var sprint_speed: float = 11.0
@export var jump_velocity: float = 5.5
@export var mouse_sensitivity: float = 0.002

# Gun
@export var fire_rate: float = 0.12      # seconds between shots
@export var max_shoot_distance: float = 200.0

# References
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var muzzle_flash: MeshInstance3D = $Head/Camera3D/GunArm/Gun/MuzzleFlash
@onready var muzzle_flash_light: OmniLight3D = $Head/Camera3D/GunArm/Gun/MuzzleLight
@onready var gun_arm: Node3D = $Head/Camera3D/GunArm
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var shoot_timer: Timer = $ShootTimer
@onready var crosshair: Control = $HUD/Crosshair
@onready var ammo_label: Label = $HUD/AmmoLabel
@onready var hit_marker: Control = $HUD/HitMarker

const GRAVITY: float = 22.0
const ShockwaveScene = preload("res://scenes/shockwave.tscn")

var _can_shoot: bool = true
var _ammo: int = 999
var _bob_time: float = 0.0
var _gun_recoil: float = 0.0
var _hit_marker_timer: float = 0.0
var _is_shooting: bool = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	muzzle_flash.visible = false
	muzzle_flash_light.visible = false
	shoot_timer.wait_time = fire_rate
	shoot_timer.one_shot = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_look(event.relative)
	
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _mouse_look(relative: Vector2) -> void:
	rotate_y(-relative.x * mouse_sensitivity)
	head.rotate_x(-relative.y * mouse_sensitivity)
	head.rotation.x = clamp(head.rotation.x, -PI / 2.2, PI / 2.2)

func _physics_process(delta: float) -> void:
	_handle_gravity(delta)
	_handle_movement(delta)
	_handle_headbob(delta)
	_handle_gun_sway(delta)
	_handle_shooting()
	_update_hitmarker(delta)
	move_and_slide()

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

func _handle_movement(delta: float) -> void:
	var is_sprinting = Input.is_action_pressed("sprint")
	var speed = sprint_speed if is_sprinting else walk_speed
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 12.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 12.0)
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		# Air control (limited)
		if direction:
			velocity.x = lerp(velocity.x, direction.x * speed * 0.7, delta * 4.0)
			velocity.z = lerp(velocity.z, direction.z * speed * 0.7, delta * 4.0)

func _handle_headbob(delta: float) -> void:
	var moving = velocity.length() > 0.5 and is_on_floor()
	if moving:
		_bob_time += delta * (1.8 if Input.is_action_pressed("sprint") else 1.2)
		var bob_x = sin(_bob_time * 2.0) * 0.025
		var bob_y = abs(sin(_bob_time)) * 0.018
		camera.position.x = lerp(camera.position.x, bob_x, delta * 10.0)
		camera.position.y = lerp(camera.position.y, bob_y, delta * 10.0)
	else:
		camera.position.x = lerp(camera.position.x, 0.0, delta * 8.0)
		camera.position.y = lerp(camera.position.y, 0.0, delta * 8.0)

func _handle_gun_sway(delta: float) -> void:
	_gun_recoil = lerp(_gun_recoil, 0.0, delta * 14.0)
	gun_arm.position.z = lerp(gun_arm.position.z, _gun_recoil, delta * 20.0)
	gun_arm.rotation.x = lerp(gun_arm.rotation.x, -_gun_recoil * 0.5, delta * 20.0)

func _handle_shooting() -> void:
	_is_shooting = Input.is_action_pressed("shoot") and _can_shoot and _ammo > 0
	if _is_shooting:
		_fire()

func _fire() -> void:
	_can_shoot = false
	_ammo -= 1
	_gun_recoil = -0.12
	
	# Muzzle flash
	_show_muzzle_flash()
	
	# Update ammo HUD
	if ammo_label:
		ammo_label.text = "∞"  # infinite ammo display
	
	# Shoot timer
	shoot_timer.start()
	await shoot_timer.timeout
	_can_shoot = true
	
	# Raycast hit check
	if raycast.is_colliding():
		var hit_pos = raycast.get_collision_point()
		var hit_normal = raycast.get_collision_normal()
		_spawn_shockwave(hit_pos, hit_normal)
		_show_hitmarker()

func _show_muzzle_flash() -> void:
	muzzle_flash.visible = true
	muzzle_flash_light.visible = true
	await get_tree().create_timer(0.05).timeout
	muzzle_flash.visible = false
	muzzle_flash_light.visible = false

func _spawn_shockwave(pos: Vector3, normal: Vector3) -> void:
	var sw = ShockwaveScene.instantiate()
	get_tree().current_scene.add_child(sw)
	sw.initialize(pos, normal)

func _show_hitmarker() -> void:
	_hit_marker_timer = 0.15
	if hit_marker:
		hit_marker.visible = true

func _update_hitmarker(delta: float) -> void:
	if _hit_marker_timer > 0.0:
		_hit_marker_timer -= delta
		if _hit_marker_timer <= 0.0 and hit_marker:
			hit_marker.visible = false
