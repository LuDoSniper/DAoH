extends CharacterBody3D

@export var base_speed := 4.0
@export var run_speed := 6.0
@export var jump_velocity := 4.5

# A utiliser lorsque les mouvements et les mouvements de la caméra doivent être bloqués
@warning_ignore("unused_signal")
signal pause
@warning_ignore("unused_signal")
signal unpause

@onready var camera = $CameraController/Camera3D
@onready var skin = $Skin

var paused: bool = false:
	set(value):
		paused = value
		if paused:
			pause.emit()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			unpause.emit()
var is_running := false
var player_is_lock = false
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	add_to_group("players")
	if is_multiplayer_authority():
		camera.current = true

func _physics_process(delta: float) -> void:
	move_logic(delta)
	jump_logic(delta)
	pause_logic()

func move_logic(delta: float) -> void:
	if is_multiplayer_authority():
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").rotated(-camera.global_rotation.y) # Rotate the direction with camera rotation
		is_running = Input.is_action_pressed("run") and input_dir != Vector2.ZERO
		
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction and not paused and not player_is_lock:
			# Rotate slowly to the desired vector (direction)
			var target_angle = -input_dir.angle() + PI/2
			skin.rotation.y = rotate_toward(skin.rotation.y, target_angle, 6.0 * delta)
			
			# Apply correct speed (run or sprint)
			var speed = run_speed if is_running else base_speed
			
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			skin.set_move_state('Run' if not is_running else "Sprint")
			rpc("sync_animation_movement", name.to_int(), 'Run' if not is_running else "Sprint")
		else:
			# Stop slowly
			velocity.x = move_toward(velocity.x, 0, base_speed)
			velocity.z = move_toward(velocity.z, 0, base_speed)
			skin.set_move_state('Idle')
			rpc("sync_animation_movement", name.to_int(), 'Idle')
		
		move_and_slide()

func jump_logic(delta: float) -> void:
	if is_multiplayer_authority():
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("jump") and is_on_floor() and not paused:
			velocity.y = jump_velocity
		
		# Update animation when falling
		if velocity.y != 0:
			skin.set_move_state('Fall')
			rpc("sync_animation_movement", name.to_int(), 'Fall')

@rpc("any_peer")
func sync_animation_movement(id: int, animation: String) -> void:
	if name.to_int() == id:
		skin.set_move_state(animation)

func pause_logic() -> void:
	if is_multiplayer_authority():
		if Input.is_action_just_pressed("pause"):
			paused = not paused

func _input(event: InputEvent) -> void:
	if not paused and event.is_action_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


#DIALOGUE - INTERACT
var current_npc: Node = null
var current_line = 0
var dialogue_active = false
var dialogue_lines: Array[String] = []

func _unhandled_input(event):
	if current_npc and event.is_action_pressed("interact") and is_multiplayer_authority():
		if not player_is_lock:
			player_is_lock = true
		if not dialogue_active:
			dialogue_lines = current_npc.get_dialogue_lines()
			DIALOGUEUI.show_dialogue(current_npc.npc_name, dialogue_lines)
			dialogue_active = true
			current_line = 1
		else:
			DIALOGUEUI._show_next_line()
			show_next_dialogue()

func show_next_dialogue():
	if current_line < dialogue_lines.size():
		current_line += 1
	else:
		dialogue_active = false
		current_line = 0
		player_is_lock = false
		current_npc = null
		
func set_current_npc(npc):
	current_npc = npc
