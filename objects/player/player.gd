extends CharacterBody3D

@export var fireball_scene: PackedScene
@export var arrow_scene: PackedScene

@export var base_speed := 4.0
@export var run_speed := 6.0
@export var jump_velocity := 4.5
@export var max_lock_distance := 25.0
@export var lock_angle_threshold := 0.5

@export var max_health: int = 100
@export var health: int = 100
@export var gold: int = 0
@export var level: int = 1
@export var current_xp: int = 0
@export var xp_to_next_level: int = 100

# A utiliser lorsque les mouvements et les mouvements de la caméra doivent être bloqués
@warning_ignore("unused_signal")
signal pause
@warning_ignore("unused_signal")
signal unpause

@onready var http: HTTPRequest = $HTTPRequest

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

@onready var hud: CanvasLayer = $Hud/Hud
@onready var camera_compass: Camera3D = $Hud/SubViewport/CameraCompass
@onready var username_label: Label3D = $UsernameLabel

var _relogin_callback: Callable = Callable()
var weapon_meshes: Dictionary = {}

var active_quests = []

# Setup in ready
var classes: Array[ClassData]
var selected_class: ClassData
var inventory: InventoryData = InventoryData.new()
var username: String:
	set(value):
		username_label.text = value
		
		username = value

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
var invincibility := false:
	set(value):
		if value and not invincibility:
			invincibility_timer.start()
		
		invincibility = value

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	play_click_on_all_buttons(self)
	
	var character_name = MULTIPLAYER.get_character_name_by_peer_id(name.to_int())
	UTILS.print_local(self, "Je viens d'apparraitre sout le nom de " + character_name)
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
	
	#if not multiplayer.is_server():
		#rpc_id(1, "_request_initialize_class", name.to_int())
	
	username_label.show()
	add_to_group("players")
	if is_multiplayer_authority():
		camera.current = true
		username_label.hide()
	
	hud.update_health(health)
	hud.update_xp(current_xp)
	hud.update_money(gold)

	if GameState.sound_master_value != null:
		$PauseMenu/MenuBG/Options/Audio/Sliders/Master.value = GameState.sound_master_value
	if GameState.sound_music_value != null:
		$PauseMenu/MenuBG/Options/Audio/Sliders/Music.value = GameState.sound_music_value
	if GameState.sound_sfx_value != null:
		$PauseMenu/MenuBG/Options/Audio/Sliders/Sound.value = GameState.sound_sfx_value



#@rpc("any_peer")
#func _request_initialize_class(id: int) -> void:
	#if multiplayer.is_server() and name.to_int() == id:
		#rpc("_remote_initialize_class", id, selected_class.name)
#
#@rpc("any_peer")
#func _remote_initialize_class(id: int, var_class_name: String) -> void:
	#if not multiplayer.is_server() and name.to_int() == id:
		#initialize_class(var_class_name)
		#initialize_inventory()

func initialize_class(var_class_name: String) -> void:
	for custom_class in classes:
		if custom_class.name == var_class_name:
			selected_class = custom_class
	skin.select_class(selected_class)
	
	if selected_class.name == "Rogue":
		base_speed += 2.0
		run_speed += 2.0

func initialize_inventory() -> void:
	inventory.initialize_base_class(selected_class.name)
	for weapon_name in weapon_meshes:
		weapon_meshes[weapon_name].hide()
		if weapon_meshes[weapon_name].is_in_group("shield"):
			weapon_meshes[weapon_name].deactivate()
	
	if inventory.right_hand is WeaponData:
		weapon_meshes[inventory.right_hand.name].show()
		if weapon_meshes[inventory.right_hand.name].is_in_group("shield"):
			weapon_meshes[inventory.right_hand.name].activate()
	if inventory.left_hand is WeaponData:
		weapon_meshes[inventory.left_hand.name].show()
		if weapon_meshes[inventory.left_hand.name].is_in_group("shield"):
			weapon_meshes[inventory.left_hand.name].activate()

func _process(delta: float) -> void:
	print(health)

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
	#focus_logic(delta)
	attack_logic()
	label_logic()

func move_logic(delta: float) -> void:
	if is_multiplayer_authority():
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward").rotated(-camera.global_rotation.y) # Rotate the direction with camera rotation
		is_running = Input.is_action_pressed("run") and input_dir != Vector2.ZERO and not blocking
		
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction and not paused and not player_is_lock:
			if not GameState.player_moving:
				$audio_walking.play()
				$audio_walking.stream.loop = true
				GameState.player_moving = true
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
			if GameState.player_moving:
				$audio_walking.stop()
				# pb: dès que l'audio est finit, il ne redémarre pas
				GameState.player_moving = false
			# Stop slowly
			velocity.x = move_toward(velocity.x, 0, base_speed)
			velocity.z = move_toward(velocity.z, 0, base_speed)
			skin.set_move_state('Idle')
			rpc("sync_animation_movement", name.to_int(), 'Idle')
		
		camera_compass.global_transform.origin.x = self.global_transform.origin.x
		camera_compass.global_transform.origin.z = self.global_transform.origin.z
		move_and_slide()
		rpc("sync_movement", name.to_int(), global_position, skin.rotation.y)

@rpc("any_peer")
func sync_movement(id: int, var_global_position: Vector3, skin_rotation: float) -> void:
	if name.to_int() == id:
		global_position = var_global_position
		skin.rotation.y = skin_rotation

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
	if not multiplayer.is_server() and name.to_int() == id:
		skin.set_move_state(animation)

func pause_logic() -> void:
	if is_multiplayer_authority():
		if Input.is_action_just_pressed("pause"):
			SoundManager.play_click()
			paused = not paused
			pause_menu.visible = not pause_menu.visible

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

@rpc("any_peer")
func _request_shoot_fireball(pos: Vector3, fireball_rotation: float) -> void:
	if multiplayer.is_server():
		var fireball = fireball_scene.instantiate()
		get_parent().add_child(fireball)
		fireball.global_position = pos
		fireball.scale = Vector3.ONE * 0.5
		fireball.rotation.y = fireball_rotation
		
		rpc("_remote_shoot_fireball", pos, fireball_rotation)

@rpc("any_peer")
func _remote_shoot_fireball(pos: Vector3, fireball_rotation: float) -> void:
	if not multiplayer.is_server():
		var fireball = fireball_scene.instantiate()
		get_parent().add_child(fireball)
		fireball.global_position = pos
		fireball.scale = Vector3.ONE * 0.5
		fireball.rotation.y = fireball_rotation

func shoot_fireball() -> void:
	$audio_fireball.play()
	rpc_id(1, "_request_shoot_fireball", fireball_spawn.global_position, skin.rotation.y)

@rpc("any_peer")
func _request_shoot_arrow(pos: Vector3, arrow_rotation: float) -> void:
	if multiplayer.is_server():
		var arrow = arrow_scene.instantiate()
		get_parent().add_child(arrow)
		arrow.global_position = pos
		arrow.rotation.y = arrow_rotation
		
		rpc("_remote_shoot_arrow", pos, arrow_rotation)

@rpc("any_peer")
func _remote_shoot_arrow(pos: Vector3, arrow_rotation: float) -> void:
	if not multiplayer.is_server():
		var arrow = arrow_scene.instantiate()
		get_parent().add_child(arrow)
		arrow.global_position = pos
		arrow.rotation.y = arrow_rotation

func shoot_arrow() -> void:
	rpc_id(1, "_request_shoot_arrow", arrow_spawn.global_position, skin.rotation.y)

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
var dialogue = null

func _unhandled_input(event):
	if current_npc and event.is_action_pressed("interact") and is_multiplayer_authority():
		if not player_is_lock:
			player_is_lock = true
		if not dialogue_active:
			$audio_hey.play()
			var quest = current_npc.quest_to_give
			var active_quest = quest if quest == null else get_quest_by_id(quest.id)
			dialogue = current_npc.get_dialogue_lines(active_quest)

			if dialogue != null and dialogue.has("is_quester") and dialogue["is_quester"]:
				add_quest(dialogue["quest"])

			if dialogue != null:
				var dialogue_line = dialogue["lines"]
				DIALOGUEUI.show_dialogue(current_npc.npc_name, dialogue_line)
				dialogue_active = true
				current_line = 1
		else:
			DIALOGUEUI._show_next_line()
			show_next_dialogue()

func show_next_dialogue():
	if current_line < dialogue["lines"].size():
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
	pause_menu_content.hide()
	options_menu_content.show()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/home/home_menu.tscn")

func _on_quitter_pressed() -> void:
	#get_tree().quit()
	UTILS.print_local(self, "I WANT TO LEAVE")
	rpc_id(1, "_request_disconnect", name.to_int(), MULTIPLAYER.owner_id)

@rpc("any_peer")
func _request_disconnect(id: int, owner_id: int, due_to_error: bool = false) -> void:
	if multiplayer.is_server() and name.to_int() == id:
		MULTIPLAYER.owners_id.pop_at(MULTIPLAYER.owners_id.find(owner_id))
		UTILS.print_local(self, "AUTHORIZING " + str(id) + " TO LEAVE")

		var character_name = MULTIPLAYER.get_character_name_by_peer_id(name.to_int())

		var message = "lost connection" if due_to_error else "hast left the game"
		get_tree().root.get_node("World").send_message("[" + character_name + "] " + message, id, false)
		if not due_to_error:
			rpc_id(id, "_remote_can_disconnect", id)
		rpc("_remote_player_disconnected", id)
		
		for enemy in get_tree().root.get_node("World").get_enemies():
			if enemy.targeted_player and enemy.targeted_player.name == name:
				enemy.targeted_player = null
				enemy.is_combat = false
				enemy.can_attack = false
		
		queue_free()

@rpc("any_peer")
func _remote_can_disconnect(id: int) -> void:
	if not multiplayer.is_server() and name.to_int() == id:
		UTILS.print_local(self, "I'M LEAVING'")
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		save_data()

@rpc("any_peer")
func _remote_player_disconnected(id: int) -> void:
	if not multiplayer.is_server() and name.to_int() == id:
		UTILS.print_local(self, "RECIEVING THAT " + str(id) + " HAS LEFT")
		queue_free()

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
	GameState.sound_master_value = value
	volume(0, value)

func _on_music_value_changed(value: float) -> void:
	GameState.sound_music_value = value
	volume(1, value)

func _on_sound_fx_value_changed(value: float) -> void:
	GameState.sound_sfx_value = value
	volume(2, value)

func volume(bus_index, value):
	if value <= -3.9:
		AudioServer.set_bus_volume_db(bus_index, -80)  # Silence complet
	else:
		AudioServer.set_bus_volume_db(bus_index, value)

func _on_back_settings_pressed() -> void:
	pause_menu_content.show()
	options_menu_content.hide()

func _on_video_pressed() -> void:
	if state != "video":
		state = "video"
		video.show()
		audio.hide()
		_update_button_styles()

func _on_audio_pressed() -> void:
	if state != "audio":
		state = "audio"
		video.hide()
		audio.show()
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

func hit(damage: float) -> void:
	if multiplayer.is_server():
		skin.hit()
		if not invincibility:
			print("[DEBUG]: HIT : ", health," - ", damage, " = ", max(0, health - damage))
			health = max(0, health - damage)
			hud.update_health(health)
			invincibility = true
			if health == 0:
				_die()
		
		rpc("_remote_hit", name.to_int(), damage)

@rpc("any_peer")
func _remote_hit(id: int, new_health: float) -> void:
	if not multiplayer.is_server() and name.to_int() == id:
		skin.hit()
		health = new_health
		hud.update_health(health)

func _on_invincibility_timer_timeout() -> void:
	invincibility = false

func _on_heal_zone_timer_timeout() -> void:
	healing = false

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	hud.update_health(health)

func _die() -> void:
	print("💀 Le joueur est mort")

func add_gold(amount: int) -> void:
	gold += amount
	hud.update_money(gold)

func remove_gold(amount: int) -> void:
	gold = max(0, gold - amount)
	hud.update_money(gold)

func add_xp(amount: int) -> void:
	current_xp += amount
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level += 1
		_on_level_up()

func _on_level_up() -> void:
	xp_to_next_level = int(xp_to_next_level * 1.25)
	max_health += 10
	health = max_health
	hud.update_xp(current_xp)

func _on_enemy_killed():
	add_xp(20)
	add_gold(10)

func set_username(var_username: String) -> void:
	username = var_username

func save_data() -> void:
	reset_http_signal()
	http.connect("request_completed", Callable(self, "_on_save_data_receive"))
	
	var err = http.request(
		"https://" + MULTIPLAYER.get_server_by_id(MULTIPLAYER.current_server)["address"] + "/api/character/update/" + str(MULTIPLAYER.current_character),
		[
			"Content-Type: application/json",
			"Authorization: Bearer " + MULTIPLAYER.token
		],
		HTTPClient.METHOD_POST,
		JSON.stringify({
			#"name": username, # Peut causer un 400 (le name est immuable)
			"saved_data": {
				"class": MULTIPLAYER.get_character_by_id(MULTIPLAYER.current_character)["saved_data"]["class"],
				"pos": global_position,
				"rot": skin.rotation.y,
				"camera_rot": camera_controller.rotation,
				"health": health,
				"xp": current_xp,
				"gold": gold
			}
		})
	)
	
	if err != OK:
		print("Erreur lors de l'envoi de la requête :", err)

func _on_save_data_receive(_result, response_code, _headers, _body) -> void:
	if response_code == 200:
		MULTIPLAYER.characters = []
		MULTIPLAYER.servers = []
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
	elif response_code == 401:
		# JWT expired, get new token
		_relogin_callback = Callable(self, "save_data")
		relogin()
	else:
		print("Erreur inconnue: ", response_code)

func relogin() -> void:
	reset_http_signal()
	http.connect("request_completed", Callable(self, "_on_relogin_receive"))
	
	var err = http.request(
		"https://" + MULTIPLAYER.get_server_by_id(MULTIPLAYER.current_server)["address"] + "/login",
		[
			"Content-Type: application/json",
		],
		HTTPClient.METHOD_POST,
		JSON.stringify({
			"username": MULTIPLAYER.username,
			"password": MULTIPLAYER.password
		})
	)
	
	if err != OK:
		print("Erreur lors de l'envoi de la requête :", err)

func _on_relogin_receive(_result, response_code, _headers, body) -> void:
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		MULTIPLAYER.token = data["token"]
		
		if _relogin_callback.is_valid():
			_relogin_callback.call()
			_relogin_callback = Callable()
	elif response_code == 401:
		print("Mauvais identifiants")
	else:
		print("Erreur inconnue: ", response_code)

func reset_http_signal():
	for callback in [
		Callable(self, "_on_save_data_receive"),
		Callable(self, "_on_relogin_receive"),
	]:
		if http.is_connected("request_completed", callback):
			http.disconnect("request_completed", callback)

func label_logic():
	var local_position = camera.global_transform.origin
	var distance = global_transform.origin.distance_to(local_position)
	if distance > 8:
		username_label.hide()
	else:
		username_label.show()
		var cam_basis = camera.global_transform.basis
		var look_position = username_label.global_transform.origin + (-cam_basis.z)
		username_label.look_at(look_position, Vector3.UP)
		username_label.rotate_y(deg_to_rad(180))

#Player.gd

func add_quest(quest):
	if quest == null:
		return
	
	if get_quest_by_id(quest.id) == null:
		quest.state = Quest.QuestState.IN_PROGRESS
		active_quests.append(quest)


func has_quest(quest_id: String) -> bool:
	for q in active_quests:
		if q.id == quest_id:
			return true
	return false

func update_quest(quest_id, quest_amount):
	for quest in active_quests:
		if quest.state == Quest.QuestState.IN_PROGRESS and quest.id == quest_id:
			quest.current_amount += quest_amount
			if quest.current_amount >= quest.required_amount:
				quest.state = Quest.QuestState.COMPLETED

func get_quest_by_id(quest_id: String) -> Quest:
	for q in active_quests:
		if q.id == quest_id:
			return q
	return null


func play_click_on_all_buttons(node):
	for child in node.get_children():
		if child is Button:
			child.pressed.connect(SoundManager.play_click)
		elif child.has_method("get_children"):
			play_click_on_all_buttons(child)
