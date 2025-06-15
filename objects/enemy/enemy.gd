extends CharacterBody3D

enum variants {
	Minion,
	Warrior,
	Mage,
	Rogue
}
@export var variant = variants.Minion

@export var fireball_scene: PackedScene
@export var arrow_scene: PackedScene

# Skins
@onready var minion_skin = $Minion
@onready var warrior_skin = $Warrior
@onready var mage_skin = $Mage
@onready var rogue_skin = $Rogue
# Meshes
@onready var minion_meshes = [
	$Minion/Rig/Skeleton3D/Skeleton_Minion_ArmLeft,
	$Minion/Rig/Skeleton3D/Skeleton_Minion_ArmRight,
	$Minion/Rig/Skeleton3D/Skeleton_Minion_Body,
	$Minion/Rig/Skeleton3D/Skeleton_Minion_Cloak,
	$Minion/Rig/Skeleton3D/Skeleton_Minion_Head,
	$Minion/Rig/Skeleton3D/Skeleton_Minion_Jaw,
	$Minion/Rig/Skeleton3D/Skeleton_Minion_LegLeft,
	$Minion/Rig/Skeleton3D/Skeleton_Minion_LegRight
]
@onready var mage_meshes = [
	$Mage/Rig/Skeleton3D/Skeleton_Mage_Hat/Skeleton_Mage_Hat,
	$Mage/Rig/Skeleton3D/Skeleton_Mage_ArmLeft,
	$Mage/Rig/Skeleton3D/Skeleton_Mage_ArmRight,
	$Mage/Rig/Skeleton3D/Skeleton_Mage_Body,
	$Mage/Rig/Skeleton3D/Skeleton_Mage_Jaw,
	$Mage/Rig/Skeleton3D/Skeleton_Mage_LegLeft,
	$Mage/Rig/Skeleton3D/Skeleton_Mage_LegRight,
	$Mage/Rig/Skeleton3D/Skeleton_Mage_Skull
]
@onready var warrior_meshes = [
	$Warrior/Rig/Skeleton3D/Skeleton_Warrior_ArmLeft,
	$Warrior/Rig/Skeleton3D/Skeleton_Warrior_ArmRight,
	$Warrior/Rig/Skeleton3D/Skeleton_Warrior_Body,
	$Warrior/Rig/Skeleton3D/Skeleton_Warrior_Cloak,
	$Warrior/Rig/Skeleton3D/Skeleton_Warrior_Head,
	$Warrior/Rig/Skeleton3D/Skeleton_Warrior_Jaw,
	$Warrior/Rig/Skeleton3D/Skeleton_Warrior_LegLeft,
	$Warrior/Rig/Skeleton3D/Skeleton_Warrior_LegRight
]
@onready var rogue_meshes = [
	$Rogue/Rig/Skeleton3D/Skeleton_Rogue_ArmLeft,
	$Rogue/Rig/Skeleton3D/Skeleton_Rogue_ArmRight,
	$Rogue/Rig/Skeleton3D/Skeleton_Rogue_Body,
	$Rogue/Rig/Skeleton3D/Skeleton_Rogue_Head,
	$Rogue/Rig/Skeleton3D/Skeleton_Rogue_Jaw,
	$Rogue/Rig/Skeleton3D/Skeleton_Rogue_LegLeft,
	$Rogue/Rig/Skeleton3D/Skeleton_Rogue_LegRight
]
# Animation trees
@onready var minion_tree = $Minion/AnimationTree
@onready var warrior_tree = $Warrior/AnimationTree
@onready var mage_tree = $Mage/AnimationTree
@onready var rogue_tree = $Rogue/AnimationTree

@onready var navigation_agent = $NavigationAgent3D

# Raycasts
@onready var vision = $Raycasts/Vision

# Timers
@onready var random_path_timer = $Timers/RandomPathTimer
@onready var invincibility_timer = $Timers/InvincibilityTimer
@onready var attack_timer = $Timers/AttackTimer

# Particles
@onready var death_particles = $DeathParticles

# Markers
@onready var projectiles_spawn = $Markers/ProjectilesSpawn
@onready var arrow_spawn = $Rogue/Rig/Skeleton3D/BoneAttachment3D/Crossbow/Marker3D

var animation_tree
var move_state_machine
var hit_state_machine
var attack_state_machine

var base_speed := 4.0
var run_speed := 5.0
var spot_radius := 10.0
var minion_attack_radius := 2.0
var mage_attack_radius := 6.0
var attack_radius
var security_distance := 5.0
var rogue_shoot_distance := 6.0
var rogue_attack_distance := 2.0

var max_health := 20.0
var health := max_health

#var players
var targeted_player

var is_combat := false
var invincible := false:
	set(value):
		var meshes
		match variant:
			variants.Minion:
				meshes = minion_meshes
			variants.Warrior:
				meshes = warrior_meshes
			variants.Mage:
				meshes = mage_meshes
			variants.Rogue:
				meshes = rogue_meshes
		if value and not invincible:
			for mesh in meshes:
				mesh.get_active_material(0).set_shader_parameter("invincible", true)
		elif not value and invincible:
			for mesh in meshes:
				mesh.get_active_material(0).set_shader_parameter("invincible", false)
		
		invincible = value
var can_attack := false
var attacking := false:
	set(value):
		if value and can_attack:
			can_attack = false
		
		attacking = value
var blocking := false:
	set(value):
		if value and not blocking:
			block()
		elif not value and blocking:
			unblock()
		
		blocking = value

var skin

func _ready() -> void:
	minion_skin.hide()
	warrior_skin.hide()
	warrior_skin.deactivate()
	mage_skin.hide()
	rogue_skin.hide()
	if variant == variants.Minion:
		minion_skin.parent = self
		minion_skin.show()
		animation_tree = minion_tree
		attack_radius = minion_attack_radius
		skin = minion_skin
	elif variant == variants.Warrior:
		warrior_skin.parent = self
		warrior_skin.show()
		warrior_skin.activate()
		animation_tree = warrior_tree
		attack_radius = minion_attack_radius
		skin = warrior_skin
	elif variant == variants.Mage:
		mage_skin.show()
		animation_tree = mage_tree
		attack_radius = mage_attack_radius
		skin = mage_skin
	elif variant == variants.Rogue:
		rogue_skin.parent = self
		rogue_skin.show()
		animation_tree = rogue_tree
		attack_radius = rogue_shoot_distance
		skin = rogue_skin
	
	move_state_machine = animation_tree.get("parameters/MoveStateMachine/playback")
	hit_state_machine = animation_tree.get("parameters/HitStateMachine/playback")
	attack_state_machine = animation_tree.get("parameters/AttackStateMachine/playback")
	
	if multiplayer.is_server():
		random_path_timer.start()

func _physics_process(delta: float) -> void:
	select_target()
	move_logic(delta)
	attack_logic()
	if multiplayer.is_server():
		rpc("sync_movement", name.to_int(), global_position, skin.rotation.y)
	#print(get_node("Raycasts").global_rotation)

func select_target() -> void:
	if multiplayer.is_server():
		var spoted_players = []
		# Listing all players nearby (spot_radius)
		for player in get_tree().root.get_node("World").get_players():
			if global_position.distance_to(player.global_position) <= spot_radius:
				spoted_players.append(player)
		# Verifying that spoted players are reachable by 'vision' (checking if the enemy can see the players)
		if spoted_players != []:
			for player in spoted_players:
				vision.target_position = vision.to_local(player.global_position)
				#vision.look_at(player.global_position)
				#print("vision : ", vision.global_rotation)
				#print("enemy : ", global_rotation)
				#print("player : ", player.global_position, " - target : ", vision.target_position)
				var collider = vision.get_collider()
				if collider:
					#print("raycast : ", vision.target_position, " player : ", player.global_position)
					#print("collider : ", collider.name.to_int(), " - ", collider.name, " --- ", "player : ", player.name.to_int(), " - ", player.name)
					if collider.name.to_int() != player.name.to_int():
						spoted_players.pop_at(spoted_players.find(player))
		
		# Selection
		if spoted_players != []:
			# Select nearest player and go toward
			is_combat = true
			
			# Keep the targeted player until he's unreachable
			var distances = []
			var players_distances = []
			for player in spoted_players:
				distances.append(global_position.distance_to(player.global_position))
				players_distances.append(player)
			targeted_player = players_distances[distances.find(UTILS.custom_min(distances))] if targeted_player == null else targeted_player
			
			# Mages will maintain security distance while others no
			var target: Vector3
			if variant != variants.Mage:
				target = targeted_player.global_position
			else:
				var direction = (targeted_player.global_position - global_position).normalized()
				target = targeted_player.global_position - direction * security_distance
			
			if global_position.distance_to(targeted_player.global_position) > attack_radius:
				navigation_agent.set_target_position(target)
				can_attack = false
			else:
				can_attack = true
			
			# The enemy will go to the last known point of the player if he get out of his vision during the track
			random_path_timer.start()
		
		elif random_path_timer.time_left == 0:
			# Select a random position nearby
			is_combat = false
			targeted_player = null
			
			var target = Vector3.ZERO
			target.x = randf_range(global_position.x + -5.0, global_position.x + 5.0)
			target.z = randf_range(global_position.z + -5.0, global_position.z + 5.0)
			navigation_agent.set_target_position(target)
			
			rpc("remote_get_target", target)
			random_path_timer.start()

@rpc("any_peer")
func remote_get_target(target: Vector3) -> void:
	if not multiplayer.is_server():
		navigation_agent.set_target_position(target)

func move_logic(delta: float) -> void:
	if multiplayer.is_server():
		# Add the gravity.
		if not is_on_floor():
			velocity += get_gravity() * delta
		
		# Get the direction with the navigation agent
		var destination = navigation_agent.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()
		
		var rounded_current_position = Vector2(
			round(global_position.x),
			round(global_position.z)
		)
		var rounded_final_position = Vector2(
			round(navigation_agent.get_final_position().x),
			round(navigation_agent.get_final_position().z)
		)
		if direction and rounded_current_position != rounded_final_position and not can_attack:
			# Rotate slowly to the desired vector (direction)
			var target_angle = -Vector2(direction.x, direction.z).angle() + PI/2
			skin.rotation.y = rotate_toward(skin.rotation.y, target_angle, 6.0 * delta)
			
			# Apply correct speed (run or sprint)
			var speed = run_speed if is_combat else base_speed
			
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			move_state_machine.travel('Run' if not is_combat else "Run_Combat")
			rpc("sync_animation_movement", name.to_int(), 'Run' if not is_combat else "Run_Combat")
		else:
			# Rotate if in combat
			if is_combat:
				direction = (targeted_player.global_position - global_position).normalized()
				var target_angle = -Vector2(direction.x, direction.z).angle() + PI/2
				skin.rotation.y = rotate_toward(skin.rotation.y, target_angle, 6.0 * delta)
			
			# Stop slowly
			velocity.x = move_toward(velocity.x, 0, base_speed)
			velocity.z = move_toward(velocity.z, 0, base_speed)
			move_state_machine.travel('Idle')
			rpc("sync_animation_movement", name.to_int(), 'Idle')
		
		move_and_slide()

@rpc("any_peer")
func sync_animation_movement(id: int, animation: String) -> void:
	if name.to_int() == id:
		move_state_machine.travel(animation)

@rpc("any_peer")
func sync_movement(id: int, var_global_position: Vector3, var_rotation: float) -> void:
	if name.to_int() == id:
		global_position = var_global_position
		skin.rotation.y = var_rotation

func attack_logic() -> void:
	if multiplayer.is_server():
		if can_attack:
			if attack_timer.is_stopped() and typeof(targeted_player) != TYPE_NIL and targeted_player != null:
				var animation_name = ""
				var rogue_instruction = "nothing"
				
				match variant:
					variants.Minion:
						animation_name = "Slice"
					variants.Warrior:
						animation_name = "Slice"
					variants.Mage:
						animation_name = "Shoot"
						shoot_fireball()
					variants.Rogue:
						var player_distance = global_position.distance_to(targeted_player.global_position)
						if rogue_attack_distance < player_distance and player_distance < rogue_shoot_distance:
							animation_name = "Crossbow_Shoot"
							rogue_skin.show_crossbow()
							rogue_instruction = "crossbow"
						else:
							animation_name = "Slice"
							rogue_skin.show_dagger()
							rogue_instruction = "dagger"
				
				attack_state_machine.travel(animation_name)
				animation_tree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				attack_timer.start()
				rpc("_remote_attack", name.to_int(), animation_name, rogue_instruction)
				
				blocking = false
			
			elif not attacking and variant == variants.Warrior and not blocking:
				blocking = true

@rpc("any_peer")
func _remote_attack(id: int, animation: String, rogue_instruction: String) -> void:
	if name.to_int() == id:
		match rogue_instruction:
			"crossbow":
				rogue_skin.show_crossbow()
			"dagger":
				rogue_skin.show_dagger()
		
		attack_state_machine.travel(animation)
		animation_tree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func block() -> void:
	var tween = create_tween()
	tween.tween_method(blend, animation_tree.get("parameters/BlockBlend2/blend_amount"), 1.0, 0.25)

func unblock() -> void:
	var tween = create_tween()
	tween.tween_method(blend, animation_tree.get("parameters/BlockBlend2/blend_amount"), 0.0, 0.25)

func blend(value: float) -> void:
	animation_tree.set("parameters/BlockBlend2/blend_amount", value)
	if multiplayer.is_server():
		rpc("_sync_block", name.to_int(), value)

@rpc("any_peer")
func _sync_block(id: int, value: float) -> void:
	if name.to_int() == id:
		animation_tree.set("parameters/BlockBlend2/blend_amount", value)

func shoot_fireball() -> void:
	if multiplayer.is_server():
		var fireball = fireball_scene.instantiate()
		get_parent().add_child(fireball)
		fireball.global_position = projectiles_spawn.global_position
		fireball.scale = Vector3.ONE * 0.5
		fireball.rotation.y = skin.rotation.y
		
		rpc("_remote_shoot_fireball", projectiles_spawn.global_position, skin.rotation.y)

@rpc("any_peer")
func _remote_shoot_fireball(pos: Vector3, fireball_rotation: float) -> void:
	if not multiplayer.is_server():
		var fireball = fireball_scene.instantiate()
		get_parent().add_child(fireball)
		fireball.global_position = pos
		fireball.scale = Vector3.ONE * 0.5
		fireball.rotation.y = fireball_rotation

func shoot_arrow() -> void:
	if multiplayer.is_server():
		var arrow = arrow_scene.instantiate()
		get_parent().add_child(arrow)
		arrow.global_position = arrow_spawn.global_position
		arrow.rotation.y = skin.rotation.y
	
	rpc("_remote_shoot_arrow", arrow_spawn.global_position, skin.rotation.y)

@rpc("any_peer")
func _remote_shoot_arrow(pos: Vector3, arrow_rotation: float) -> void:
	if not multiplayer.is_server():
		var arrow = arrow_scene.instantiate()
		get_parent().add_child(arrow)
		arrow.global_position = pos
		arrow.rotation.y = arrow_rotation

func hit(damage: float) -> void:
	if multiplayer.is_server():
		if not invincible:
			health -= damage
			if health <= 0:
				minion_skin.hide()
				warrior_skin.hide()
				warrior_skin.deactivate()
				mage_skin.hide()
				rogue_skin.hide()
				death_particles.emitting = true
				
				var players = get_tree().root.get_node("World").get_players()
				if players != []:
					var min_dist = global_position.distance_to(players[0].global_position)
					var min_player = players[0]
					for player in players:
						if global_position.distance_to(player.global_position) < min_dist:
							min_dist = global_position.distance_to(player.global_position)
							min_player = player
					
					#min_player.add_xp(10.0)
					min_player._on_enemy_killed()
					rpc("_remote_add_xp", min_player.name.to_int(), 10.0)
			
			var animations = [
				"Hit_A",
				"Hit_B"
			]
			var animation = animations[randi_range(0, len(animations) - 1)]
			hit_state_machine.travel(animation)
			animation_tree.set("parameters/HitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			invincible = true
			invincibility_timer.start()
			
			rpc("_remote_hit", name.to_int(), health, animation)

@rpc("any_peer")
func _remote_add_xp(id: int, value: float) -> void:
	if not multiplayer.is_server():
		var players = get_tree().root.get_node("World").get_players()
		for player in players:
			if player.name.to_int() == id:
				#player.add_xp(value)
				player._on_enemy_killed()
				return

@rpc("any_peer")
func _remote_hit(id: int, new_health: float, animation: String) -> void:
	if name.to_int() == id:
		health = new_health
		
		if health <= 0:
			minion_skin.hide()
			warrior_skin.hide()
			warrior_skin.deactivate()
			mage_skin.hide()
			rogue_skin.hide()
			death_particles.emitting = true
		
		hit_state_machine.travel(animation)
		animation_tree.set("parameters/HitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		invincible = true
		invincibility_timer.start()

func _on_random_path_timer_timeout() -> void:
	random_path_timer.wait_time = randf_range(2.5, 4.0)

func _on_invincibility_timer_timeout() -> void:
	invincible = false

func _on_death_particles_finished() -> void:
	queue_free()

func _on_attack_timer_timeout() -> void:
	attack_timer.wait_time = randf_range(2.5, 3.5)
