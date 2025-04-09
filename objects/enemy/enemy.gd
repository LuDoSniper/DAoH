extends CharacterBody3D

# Skins
@onready var minion_skin = $Minion
@onready var warrior_skin = $Warrior
@onready var mage_skin = $Mage
@onready var rogue_skin = $Rogue
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

var animation_tree
var move_state_machine

var base_speed := 4.0
var run_speed := 5.0
var spot_radius := 10.0

var players

var is_combat := false

enum variants {
	Minion,
	Warrior,
	Mage,
	Rogue
}
@export var variant = variants.Minion

func _ready() -> void:
	minion_skin.hide()
	warrior_skin.hide()
	mage_skin.hide()
	rogue_skin.hide()
	if variant == variants.Minion:
		minion_skin.show()
		animation_tree = minion_tree
	elif variant == variants.Warrior:
		warrior_skin.show()
		animation_tree = warrior_tree
	elif variant == variants.Mage:
		mage_skin.show()
		animation_tree = mage_tree
	elif variant == variants.Rogue:
		rogue_skin.show()
		animation_tree = rogue_tree
	
	move_state_machine = animation_tree.get("parameters/MoveStateMachine/playback")
	
	if multiplayer.is_server():
		random_path_timer.start()

func _physics_process(delta: float) -> void:
	select_target()
	move_logic(delta)

func select_target() -> void:
	if multiplayer.is_server():
		var spoted_players = []
		# Listing all players nearby (spot_radius)
		if players:
			for player in players:
				if global_position.distance_to(player.global_position) <= spot_radius:
					spoted_players.append(player)
		# Verifying that spoted players are reachable by 'vision' (checking if the enemy can see the players)
		if spoted_players != []:
			for player in spoted_players:
				vision.target_position = player.global_position
				var collider = vision.get_collider()
				if collider:
					if collider.name.to_int() != player.name.to_int():
						spoted_players.pop_at(spoted_players.find(player))
		
		# Selection
		if spoted_players != []:
			# Select a random player and go toward
			is_combat = true
			var targeted_player = spoted_players[randi_range(0, len(spoted_players) - 1)]
			navigation_agent.set_target_position(targeted_player.global_position)
			# The enemy will go to the last known point of the player if he get out of his vision during the track
			random_path_timer.start()
		elif random_path_timer.time_left == 0:
			# Select a ranodom position nearby
			is_combat = false
			var target = Vector3.ZERO
			target.x = randf_range(-5.0, 5.0)
			target.z = randf_range(-5.0, 5.0)
			navigation_agent.set_target_position(target)
			rpc("remote_get_target", target)
			random_path_timer.start()

@rpc("any_peer")
func remote_get_target(target: Vector3) -> void:
	if not multiplayer.is_server():
		navigation_agent.set_target_position(target)

func move_logic(delta: float) -> void:
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
	if direction and rounded_current_position != rounded_final_position:
		# Rotate slowly to the desired vector (direction)
		var target_angle = -Vector2(direction.x, direction.z).angle() + PI/2
		rotation.y = rotate_toward(rotation.y, target_angle, 6.0 * delta)
		
		# Apply correct speed (run or sprint)
		var speed = run_speed if is_combat else base_speed
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		move_state_machine.travel('Run' if not is_combat else "Run_Combat")
	else:
		# Stop slowly
		velocity.x = move_toward(velocity.x, 0, base_speed)
		velocity.z = move_toward(velocity.z, 0, base_speed)
		move_state_machine.travel('Idle')
	
	move_and_slide()

func _on_random_path_timer_timeout() -> void:
	random_path_timer.wait_time = randf_range(2.5, 4.0)
