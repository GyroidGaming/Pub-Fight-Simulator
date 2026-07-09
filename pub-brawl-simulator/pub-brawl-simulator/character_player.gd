extends CharacterBody3D

var speed
const WALK_SPEED = 3.0
const SPRINT_SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = .001 

#head bob
const BOB_FREQ = 3.0
const BOB_AMP = 0.01
var t_bob = 0.0

#fov
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

var gravity = 9.8

#crouch
var crouch_height = 0.5
var stand_height = 2.0
var crouching = false
const CROUCH_SPEED = 1.0

#object
var pickedObject

# References to nodes that are on the player character
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var collision = $CollisionShape3D
@onready var mesh = $Head/MeshInstance3D
@onready var object_marker = %CarryObjectMarker
@onready var interact = $Head/Camera3D/Interact

#--------------------------------------------
# Set the mouse to not be visible upon start
#--------------------------------------------
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

#--------------------------------------------
# Calculate the crouch height and state
#--------------------------------------------
func _crouch():
	if Input.is_action_just_pressed("crouch"):
		crouching = !crouching
		if crouching:
			collision.shape.height = crouch_height
		else:
			collision.shape.height = stand_height

#--------------------------------------------
# Input actions
#--------------------------------------------
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if event.is_action_pressed("Interact") and pickedObject:
		pickedObject.reparent(get_tree().current_scene)
		pickedObject = null

#--------------------------------------------
# Rotate the camera with the mouse movements
#--------------------------------------------
func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

#--------------------------------------------
# Perform all physics based actions
#--------------------------------------------
func _physics_process(delta: float) -> void:
	#Detect the current interactable object
	if (interact.is_colliding()):
		var object = interact.get_collider().get_parent()
		
		print(object.name)
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	#Sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	if crouching:
		speed = CROUCH_SPEED
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
	
	_crouch()
	move_and_slide()
	
	#head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	#FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

#--------------------------------------------
# Calculate the headbob
#--------------------------------------------
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
	
#--------------------------------------------
# Pick up objects
#--------------------------------------------

func pick_up_object(object):
	object.reparent(self)
	object.global_position = object_marker.global_position
	
	await get_tree().create_timer(0.1).timeout
	pickedObject = object
