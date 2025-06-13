extends CharacterBody3D

@onready var knight: Node3D = $Skins/Knight
@onready var mage: Node3D = $Skins/Mage
@onready var barbarian: Node3D = $Skins/Barbarian
@onready var rogue: Node3D = $Skins/Rogue

@onready var animation_tree: AnimationTree = $Skins/AnimationTree
@onready var move_state_mahcine = animation_tree.get("parameters/MoveStateMachine/playback")

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D
@onready var wait_timer: Timer = $Timers/WaitTimer

enum variants {
	Knight,
	Mage,
	Barbarian,
	Rogue
}
@export var variant: variants:
	set(value):
		if knight != null and mage != null and barbarian != null and rogue != null:
			match value:
				variants.Knight:
					knight.show()
					mage.hide()
					barbarian.hide()
					rogue.hide()
					animation_tree.anim_player = knight.get_node("AnimationPlayer").get_path()
				variants.Mage:
					knight.hide()
					mage.show()
					barbarian.hide()
					rogue.hide()
					animation_tree.anim_player = mage.get_node("AnimationPlayer").get_path()
				variants.Barbarian:
					knight.hide()
					mage.hide()
					barbarian.show()
					rogue.hide()
					animation_tree.anim_player = barbarian.get_node("AnimationPlayer").get_path()
				variants.Rogue:
					knight.hide()
					mage.hide()
					barbarian.hide()
					rogue.show()
					animation_tree.anim_player = rogue.get_node("AnimationPlayer").get_path()
		
		variant = value

var base_speed := 2.0
var movment_radius := 5.0

var rng = RandomNumberGenerator.new()
var target = null
var moving: bool = false

var bodies := []

func _ready() -> void:
	knight.hide()
	mage.hide()
	barbarian.hide()
	rogue.hide()
	
	variant = variant
	navigation_agent.max_speed = base_speed
	
	set_move_state("Idle")

func _physics_process(delta: float) -> void:
	move_logic(delta)
	if Input.is_action_just_pressed("ui_accept"):
		moving = true
	#if bodies != []:
		#var targets_to_avoid = []
		#for body in bodies:
			#targets_to_avoid.append(body.global_position)
		#select_target(true, targets_to_avoid)

func move_logic(delta: float) -> void:
	if moving:
		if target == null:
			select_target()
		
		if navigation_agent.is_navigation_finished():
			moving = false
			target = null
			wait_timer.wait_time = rng.randf_range(3.0, 10.0)
			wait_timer.start()
			set_move_state('Idle')
		
		var destination = navigation_agent.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()
		
		if direction:
			var target_angle = -Vector2(direction.x, direction.z).angle() + PI/2
			rotation.y = rotate_toward(rotation.y, target_angle, 6.0 * delta)
			
			# Apply correct speed (run or sprint)
			var speed = base_speed
			
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			
			set_move_state('Walk')
		else:
			velocity.x = move_toward(velocity.x, 0, base_speed)
			velocity.z = move_toward(velocity.z, 0, base_speed)
			set_move_state('Idle')
		
		move_and_slide()

#func select_target() -> void:
	#var distance = rng.randf_range(2.0, 5.0)
	#var angle = rng.randf_range(0, 2 * PI)
	#
	#target = Vector3(
		#cos(angle),
		#global_position.y,
		#sin(angle)
	#)
	#navigation_agent.set_target_position(target)

func select_target(avoid: bool = false, targets_to_avoid: Array = []) -> void:
	var valid_target = false
	var distance = 0.0
	var angle = 0.0
	var new_target: Vector3

	# Boucle jusqu'à ce que la distance soit suffisante si avoid est vrai
	while not valid_target:
		distance = rng.randf_range(0.5, 1.0)  # Distance aléatoire entre 2m et 5m
		angle = rng.randf_range(0, 2 * PI)    # Angle aléatoire entre 0 et 2π

		# Calcul de la nouvelle position
		new_target = Vector3(
			cos(angle) * distance,
			global_position.y,
			sin(angle) * distance
		)

		# Si avoid est vrai, vérifie que la nouvelle position est à plus de 2,5 mètres de target_to_avoid
		if avoid:
			for target_to_avoid in targets_to_avoid:
				var target_distance = new_target.distance_to(target_to_avoid)
				if target_distance >= 2.5:  # Si la position est à au moins 2,5 mètres de target_to_avoid
					valid_target = true  # Sortie de la boucle si la condition est respectée
				else:
					valid_target = false
					break
		else:
			valid_target = true  # Si avoid est false, on accepte directement la position

	# Une fois la position valide trouvée, on définit la cible du NavigationAgent
	target = new_target
	navigation_agent.set_target_position(target)

func set_move_state(state: String) -> void:
	move_state_mahcine.travel(state)

func _on_wait_timer_timeout() -> void:
	moving = true

func _on_navigation_agent_3d_velocity_computed(safe_velocity: Vector3) -> void:
	#velocity = safe_velocity
	#move_and_slide()
	pass

func _on_area_3d_body_entered(body: Node3D) -> void:
	bodies.append(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	bodies.pop_at(bodies.find(body))
