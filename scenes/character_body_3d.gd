extends CharacterBody3D

const SPEED := 5.0
const MOUSE_SENS := 0.002
const GRAVITY := 9.8
# 1. Add a Jump Force constant
const JUMP_VELOCITY := 4.5 

@onready var camera = $Camera3D

var pitch := 0.0

func _ready():
	camera.make_current()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# 1. Recapture mouse on click
	if event is InputEventMouseButton:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# 2. Mouse Look logic (only runs if mouse is captured)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENS)
		pitch -= event.relative.y * MOUSE_SENS
		pitch = clamp(pitch, -1.5, 1.5)
		camera.rotation.x = pitch

	# 3. Release mouse with Escape
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta):
	# 2. Add Gravity if not on floor
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# 3. Handle Jump Input
	# We check "is_on_floor" so the player can't infinite-jump in the air
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var dir := Vector3.ZERO

	if Input.is_action_pressed("move-forward"):
		dir -= transform.basis.z
	if Input.is_action_pressed("move-back"):
		dir += transform.basis.z
	if Input.is_action_pressed("move-left"):
		dir -= transform.basis.x
	if Input.is_action_pressed("move-right"):
		dir += transform.basis.x

	dir = dir.normalized()

	# Apply movement
	if dir != Vector3.ZERO:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	else:
		# Smoothly stop if no keys are pressed
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
