extends CharacterBody3D

@export var fireball_scene: PackedScene
@export var arrow_scene: PackedScene

@export var base_speed := 4.0
@export var run_speed := 6.0
@export var jump_velocity := 4.5
@export var max_lock_distance := 25.0
@export var lock_angle_threshold := 0.5

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
@onready var camera_controller = $CameraController
@onready var camera = $CameraController/Camera3D
@onready var skin = $Skin

@onready var invincibility_timer = $Timers/InvincibilityTimer
@onready var healzone_timer = $Timers/HealZoneTimer

@onready var fireball_spawn: Marker3D = $"Skin/Mage/Rig/Skeleton3D/1H_Wand/wand/SpawnFireball"
@onready var arrow_spawn: Marker3D = $Skin/Rogue/Rig/Skeleton3D/Knife/Crossbow/Marker3D

@onready var healzone = $HealZone

var weapon_meshes: Dictionary = {}

# Setup in ready
var classes: Array[ClassData]
var selected_class: ClassData
var inventory: InventoryData = InventoryData.new()

var state = "video"
var panel_selected = preload("res://addons/menu/panel_brown_arrows_dark_detail.png")
var panel = preload("res://addons/menu/panel_brown_damaged_dark.png")

var focusing := false:
	set(value):
		focusing = value
		camera_controller.focusing = focusing
var target = null

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
var speed_modifier := 1.0

var attacking := false
var blocking := false:
	set(value):
		if value and not blocking:
			skin.block()
			speed_modifier = 0.5
		elif not value and blocking:
			skin.unblock()
			speed_modifier = 1.0
		
		blocking = value
var healing := false:
	set(value):
		if value and not healing:
			healzone.spawn()
			healzone_timer.start()
		elif not value and healing:
			healzone.despawn()
		
		healing = value

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	# Initialize classes
	var knight_class = ClassData.new("Knight")
	knight_class.add_attack("base")
	knight_class.add_attack("base_2H")
	knight_class.add_attack("special")
	classes.append(knight_class)
	weapon_meshes["Sword_1H"] = $"Skin/Knight/Rig/Skeleton3D/1H_Sword/Sword_1H"
	weapon_meshes["Sword_2H"] = $"Skin/Knight/Rig/Skeleton3D/2H_Sword/Sword_2H"
	weapon_meshes["Sword_2H_Colored"] = $"Skin/Knight/Rig/Skeleton3D/2H_Sword/Sword_2H_Colored"
	weapon_meshes["Shield_Badge"] = $Skin/Knight/Rig/Skeleton3D/Badge_Shield/ShieldBadge
	weapon_meshes["Shield_Badge_Colored"] = $Skin/Knight/Rig/Skeleton3D/Badge_Shield/ShieldBadgeColored
	weapon_meshes["Shield_Round"] = $Skin/Knight/Rig/Skeleton3D/Badge_Shield/ShieldRound
	weapon_meshes["Shield_Round_Colored"] = $Skin/Knight/Rig/Skeleton3D/Badge_Shield/ShieldRoundColored
	weapon_meshes["Shield_Round_Barbarian"] = $Skin/Knight/Rig/Skeleton3D/Badge_Shield/ShieldRoundBarbarian
	weapon_meshes["Shield_Spikes"] = $Skin/Knight/Rig/Skeleton3D/Badge_Shield/ShieldSpikes
	weapon_meshes["Shield_Spikes_Colored"] = $Skin/Knight/Rig/Skeleton3D/Badge_Shield/ShieldSpikesColored
	weapon_meshes["Shield_Squared"] = $Skin/Knight/Rig/Skeleton3D/Badge_Shield/ShieldSquare
	weapon_meshes["Shield_Squared_Colored"] = $Skin/Knight/Rig/Skeleton3D/Badge_Shield/ShieldSquareColored
	
	var barbarian_class = ClassData.new("Barbarian")
	barbarian_class.add_attack("base")
	barbarian_class.add_attack("base_2H")
	barbarian_class.add_attack("special")
	classes.append(barbarian_class)
	weapon_meshes["Axe_1H"] = $"Skin/Barbarian/Rig/Skeleton3D/1H_Axe/Axe_1H"
	weapon_meshes["Axe_2H"] = $"Skin/Barbarian/Rig/Skeleton3D/2H_Axe/Axe_2H"
	weapon_meshes["Shield_Badge"] = $Skin/Barbarian/Rig/Skeleton3D/Barbarian_Round_Shield/ShieldBadge
	weapon_meshes["Shield_Badge_Colored"] = $Skin/Barbarian/Rig/Skeleton3D/Barbarian_Round_Shield/ShieldBadgeColored
	weapon_meshes["Shield_Round"] = $Skin/Barbarian/Rig/Skeleton3D/Barbarian_Round_Shield/ShieldRound
	weapon_meshes["Shield_Round_Colored"] = $Skin/Barbarian/Rig/Skeleton3D/Barbarian_Round_Shield/ShieldRoundColored
	weapon_meshes["Shield_Round_Barbarian"] = $Skin/Barbarian/Rig/Skeleton3D/Barbarian_Round_Shield/ShieldRoundBarbarian
	weapon_meshes["Shield_Spikes"] = $Skin/Barbarian/Rig/Skeleton3D/Barbarian_Round_Shield/ShieldSpikes
	weapon_meshes["Shield_Spikes_Colored"] = $Skin/Barbarian/Rig/Skeleton3D/Barbarian_Round_Shield/ShieldSpikesColored
	weapon_meshes["Shield_Squared"] = $Skin/Barbarian/Rig/Skeleton3D/Barbarian_Round_Shield/ShieldSquare
	weapon_meshes["Shield_Squared_Colored"] = $Skin/Barbarian/Rig/Skeleton3D/Barbarian_Round_Shield/ShieldSquareColored
	
	var mage_class = ClassData.new("Mage")
	mage_class.add_attack("base")
	mage_class.add_attack("special")
	classes.append(mage_class)
	weapon_meshes["Wand"] = $"Skin/Mage/Rig/Skeleton3D/1H_Wand/wand"
	weapon_meshes["Staff"] = $"Skin/Mage/Rig/Skeleton3D/1H_Wand/staff"
	
	var rogue_class = ClassData.new("Rogue")
	rogue_class.add_attack("base")
	rogue_class.add_attack("shoot")
	classes.append(rogue_class)
	weapon_meshes["Dagger"] = $Skin/Rogue/Rig/Skeleton3D/Knife/Dagger
	weapon_meshes["Crossbow"] = $Skin/Rogue/Rig/Skeleton3D/Knife/Crossbow
	
	add_to_group("players")
	if is_multiplayer_authority():
		camera.current = true

func initialize_class(var_class_name: String) -> void:
	if is_multiplayer_authority():
		UTILS.print_local(self, "[DEBUG] - var_class_name:" + var_class_name)
		for custom_class in classes:
			if custom_class.name == var_class_name:
				selected_class = custom_class
				UTILS.print_local(self, "[DEBUG] - selected_class:" + selected_class.name)
		skin.select_class(selected_class)
	else:
		UTILS.print_local(self, "[DEBUG] - Server:" + str(multiplayer.is_server()))
	
	if selected_class.name == "Rogue":
		base_speed += 2.0
		run_speed += 2.0

func initialize_inventory() -> void:
	inventory.initialize_base_class(selected_class.name)
	for weapon_name in weapon_meshes:
		weapon_meshes[weapon_name].hide()
		if weapon_meshes[weapon_name].is_in_group("shield"):
			weapon_meshes[weapon_name].get_node("StaticBody3D").get_node("CollisionShape3D").disabled = true
	
	if inventory.right_hand is WeaponData:
		weapon_meshes[inventory.right_hand.name].show()
		if weapon_meshes[inventory.right_hand.name].is_in_group("shield"):
			weapon_meshes[inventory.right_hand.name].get_node("StaticBody3D").get_node("CollisionShape3D").disabled = false
	if inventory.left_hand is WeaponData:
		weapon_meshes[inventory.left_hand.name].show()
		if weapon_meshes[inventory.left_hand.name].is_in_group("shield"):
			weapon_meshes[inventory.left_hand.name].get_node("StaticBody3D").get_node("CollisionShape3D").disabled = false

func _physics_process(delta: float) -> void:
	move_logic(delta)
	jump_logic(delta)
	pause_logic()
	#focus_logic(delta)
	attack_logic()

func move_logic(delta: float) -> void:
	if is_multiplayer_authority():
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").rotated(-camera.global_rotation.y) # Rotate the direction with camera rotation
		is_running = Input.is_action_pressed("run") and input_dir != Vector2.ZERO and not blocking
		
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction and not paused and not player_is_lock:
			# Rotate slowly to the desired vector (direction)
			var target_angle = -input_dir.angle() + PI/2
			skin.rotation.y = rotate_toward(skin.rotation.y, target_angle, 10.0 * delta)
			
			# Apply correct speed (run or sprint)
			var speed = run_speed if is_running else base_speed
			speed *= speed_modifier
			
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

#func focus_logic(delta) -> void:
	#if is_multiplayer_authority():
		## Toggle focusing
		#if Input.is_action_just_pressed("focus"):
			#focusing = not focusing
		#
		## Correct focusing if necessary
		#if focusing and not target:
			#focusing = select_focus_target()
		#
		## Update camera if focusing
		#if focusing:
			##camera_controller.look_at(target.global_position)
			#var current_basis = global_transform.basis
			#var look_target = target.global_position
			#
			#var to_target = (look_target - global_transform.origin).normalized()
			#var target_basis = Basis().looking_at(to_target, Vector3.UP)
			#
			## Interpolation douce entre la rotation actuelle et la cible
			#global_transform.basis = current_basis.slerp(target_basis, 6.0 * delta)
#
#func select_focus_target() -> bool:
	#var enemies = get_parent().get_enemies()
	#var best_candidate = null
	#var best_score = -1.0
#
	#for enemy in enemies:
		#if not is_instance_valid(enemy): continue
		#var to_enemy = enemy.global_transform.origin - global_transform.origin
		#var distance = to_enemy.length()
#
		#if distance > max_lock_distance:
			#continue
#
		## Convert direction en vue caméra
		#var dir_to_enemy = (enemy.global_transform.origin - camera.global_transform.origin).normalized()
		#var camera_forward = -camera.global_transform.basis.z.normalized()
#
		## Dot product pour savoir à quel point l’ennemi est centré
		#var alignment = dir_to_enemy.dot(camera_forward)
		#
		#if alignment > lock_angle_threshold and alignment > best_score:
			#best_score = alignment
			#best_candidate = enemy
#
	#if best_candidate:
		#target = best_candidate
	#else:
		#target = null
	#
	#return target != null

func array_has(array: Array, items: Array) -> bool:
	for e in array:
		if e in items:
			return true
	
	return false

func attack_logic() -> void:
	if is_multiplayer_authority():
		attacking = skin.attacking
		
		if not attacking:
			if not blocking:
				if Input.is_action_just_pressed("attack"):
					# Selection arbitraire pour le moment
					var attack_name = "base"
					if selected_class.name in ["Knight", "Barbarian"]:
						if array_has(inventory.right_hand.hands, [WeaponData.hands_variants.Left, WeaponData.hands_variants.Right]):
							attack_name = "base"
						elif array_has(inventory.right_hand.hands, [WeaponData.hands_variants.Both]):
							attack_name = "base_2H"
					if selected_class.name == "Rogue":
						if inventory.right_hand is WeaponData and inventory.right_hand.name == "Dagger":
							attack_name = "base"
						else:
							attack_name = "shoot"
					
					var attack = selected_class.get_attack(attack_name)
					
					skin.attack(attack.name)
			
			if selected_class.name in ["Knight", "Barbarian"]:
				blocking = Input.is_action_pressed("special") and inventory.left_hand is WeaponData and inventory.left_hand.name.split('_')[0] == "Shield"
			elif selected_class.name == "Mage" and not healing:
				healing = Input.is_action_just_pressed("special") and inventory.right_hand is WeaponData and inventory.right_hand.name == "Staff"

func shoot_fireball() -> void:
	var fireball = fireball_scene.instantiate()
	get_parent().add_child(fireball)
	fireball.global_position = fireball_spawn.global_position
	fireball.scale = Vector3.ONE * 0.5
	fireball.rotation.y = skin.rotation.y

func shoot_arrow() -> void:
	var arrow = arrow_scene.instantiate()
	get_parent().add_child(arrow)
	arrow.global_position = arrow_spawn.global_position
	arrow.rotation.y = skin.rotation.y

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

func hit(_damage: float) -> void:
	skin.hit()

func _on_invincibility_timer_timeout() -> void:
	pass # Replace with function body.

func _on_heal_zone_timer_timeout() -> void:
	healing = false
