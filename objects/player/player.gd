extends CharacterBody3D

@export var base_speed := 4.0
@export var run_speed := 6.0
@export var jump_velocity := 4.5

# A utiliser lorsque les mouvements et les mouvements de la caméra doivent être bloqués
@warning_ignore("unused_signal")
signal pause
@warning_ignore("unused_signal")
signal unpause

@onready var video_type_button: Button = $PauseMenu/MenuBG/Options/TypeMenu/Video
@onready var audio_type_button: Button = $PauseMenu/MenuBG/Options/TypeMenu/Audio
@onready var video: HBoxContainer = $PauseMenu/MenuBG/Options/Video
@onready var audio: HBoxContainer = $PauseMenu/MenuBG/Options/Audio

@onready var pause_menu_content: Control = $PauseMenu/MenuBG/Pause
@onready var options_menu_content: Control = $PauseMenu/MenuBG/Options
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var camera = $CameraController/Camera3D
@onready var skin = $Skin

var state = "video"
var panel_selected = preload("res://addons/menu/panel_brown_arrows_dark_detail.png")
var panel = preload("res://addons/menu/panel_brown_damaged_dark.png")

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
	# si en gestion de tchat -> on desactive les mouvements joueur
	if GameState.chat_active:
		return
	if GameState.ignore_pause:
		GameState.ignore_pause = false 
		return  

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
			pause_menu.visible = not pause_menu.visible

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


func _on_reprendre_pressed() -> void:
	paused = not paused
	pause_menu.visible = not pause_menu.visible


func _on_options_pressed() -> void:
	pause_menu_content.visible = false
	options_menu_content.visible = true


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/home/home_menu.tscn")


func _on_quitter_pressed() -> void:
	get_tree().quit()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_borderless_toggled(toggled_on: bool) -> void:
	# Ne s'applique que si on est en mode fenêtré
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, toggled_on)

func _on_v_sync_toggled(toggled_on: bool) -> void:
	# Active ou désactive la V-Sync
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED
	)

func _on_master_value_changed(value: float) -> void:
	volume(0, value)

func _on_music_value_changed(value: float) -> void:
	volume(1, value)

func _on_sound_fx_value_changed(value: float) -> void:
	volume(2, value)

func volume(bus_index, value):
	AudioServer.set_bus_volume_db(bus_index, value)

func _on_back_settings_pressed() -> void:
	pause_menu_content.visible = true
	options_menu_content.visible = false

func _on_video_pressed() -> void:
	if state != "video":
		state = "video"
		video.visible = true
		audio.visible = false
		_update_button_styles()

func _on_audio_pressed() -> void:
	if state != "audio":
		state = "audio"
		video.visible = false
		audio.visible = true
		_update_button_styles()

func _update_button_styles() -> void:
	var selected_stylebox = StyleBoxTexture.new()
	selected_stylebox.texture = panel_selected

	var default_stylebox = StyleBoxTexture.new()
	default_stylebox.texture = panel

	if state == "video":
		video_type_button.add_theme_stylebox_override("normal", selected_stylebox)
		audio_type_button.add_theme_stylebox_override("normal", default_stylebox)
		
		video_type_button.add_theme_stylebox_override("hover", selected_stylebox)
		audio_type_button.add_theme_stylebox_override("hover", default_stylebox)
	else:
		audio_type_button.add_theme_stylebox_override("normal", selected_stylebox)
		video_type_button.add_theme_stylebox_override("normal", default_stylebox)
		
		audio_type_button.add_theme_stylebox_override("hover", selected_stylebox)
		video_type_button.add_theme_stylebox_override("hover", default_stylebox)
