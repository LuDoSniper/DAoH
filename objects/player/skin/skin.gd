extends Node3D

# Skins
@onready var knight_skin = $Knight
@onready var barbarian_skin = $Barbarian
@onready var mage_skin = $Mage
@onready var rogue_skin = $Rogue
# Animation trees
@onready var knight_tree = $Knight/AnimationTree
@onready var barbarian_tree = $Barbarian/AnimationTree
@onready var mage_tree = $Mage/AnimationTree
@onready var rogue_tree = $Rogue/AnimationTree

# A DEFINIR
var animation_tree
var move_state_machine
var attack_state_machine
var hit_state_machine

enum skins {
	Knight,
	Barbarian,
	Mage,
	Rogue
}
@export var skin := skins.Rogue

var attacking := false

func _ready() -> void:
	knight_skin.parent = self
	barbarian_skin.parent = self
	mage_skin.parent = self
	rogue_skin.parent = self

func select_class(var_class: ClassData) -> void:
	match var_class.name:
		"Knight":
			skin = skins.Knight
		"Barbarian":
			skin = skins.Barbarian
		"Mage":
			skin = skins.Mage
		"Rogue":
			skin = skins.Rogue
	
	knight_skin.hide()
	barbarian_skin.hide()
	mage_skin.hide()
	rogue_skin.hide()
	if skin == skins.Knight:
		knight_skin.show()
		animation_tree = knight_tree
	elif skin == skins.Barbarian:
		barbarian_skin.show()
		animation_tree = barbarian_tree
	elif skin == skins.Mage:
		mage_skin.show()
		animation_tree = mage_tree
	elif skin == skins.Rogue:
		rogue_skin.show()
		animation_tree = rogue_tree
	
	move_state_machine = animation_tree.get("parameters/MoveStateMachine/playback")
	attack_state_machine = animation_tree.get("parameters/AttackStateMachine/playback")
	hit_state_machine = animation_tree.get("parameters/HitStateMachine/playback")
	#! A supprimé si prouvé inutile
	get_move_state_current_node()

func set_move_state(state: String) -> void:
	move_state_machine.travel(state)

#? A quoi ça sert ??
func get_move_state_current_node() -> StringName:
	return move_state_machine.get_current_node()

func attack(attack_name: String) -> void:
	var animation_name = null
	match skin:
		skins.Knight:
			match attack_name:
				"base":
					animation_name = "Slice_Horizontal"
				"base_2H":
					animation_name = "2H_Slice"
		skins.Barbarian:
			match attack_name:
				"base":
					animation_name = "Slice_Horizontal"
				"base_2H":
					animation_name = "2H_Slice"
		skins.Mage:
			match attack_name:
				"base":
					animation_name = "Spellcast_Shoot"
				"special":
					animation_name = "Spellcast_Raise"
		skins.Rogue:
			match attack_name:
				"base":
					animation_name = "Slice_Horizontal"
				"shoot":
					animation_name = "Shoot"
	attack_state_machine.travel(animation_name)
	animation_tree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	rpc("_sync_attack", name.to_int(), animation_name)

@rpc("any_peer")
func _sync_attack(id: int, animation_name: String) -> void:
	if name.to_int() == id:
		attack_state_machine.travel(animation_name)
		animation_tree.set("parameters/AttackOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func block() -> void:
	var tween = create_tween()
	var current_value = animation_tree.get("parameters/SpecialBlockBlend2/blend_amount")
	tween.tween_method(_tween_block, current_value, 1.0, 0.25)

func unblock() -> void:
	var tween = create_tween()
	var current_value = animation_tree.get("parameters/SpecialBlockBlend2/blend_amount")
	tween.tween_method(_tween_block, current_value, 0.0, 0.25)

func _tween_block(value: float) -> void:
	animation_tree.set("parameters/SpecialBlockBlend2/blend_amount", value)
	rpc("_sync_block", name.to_int(), value)

@rpc("any_peer")
func _sync_block(id: int, value: float) -> void:
	if not multiplayer.is_server() and name.to_int() == id:
		animation_tree.set("parameters/SpecialBlockBlend2/blend_amount", value)

func hit() -> void:
	if multiplayer.is_server():
		var animations = [
			"Hit_A",
			"Hit_B"
		]
		var animation_name = animations[randi_range(0, len(animations) - 1)]
		
		hit_state_machine.travel(animation_name)
		animation_tree.set("parameters/HitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		attacking = false
		
		rpc("_sync_hit", name.to_int(), animation_name)

@rpc("any_peer")
func _sync_hit(id: int, animation_name: String) -> void:
	if not multiplayer.is_server() and name.to_int() == id:
		hit_state_machine.travel(animation_name)
		animation_tree.set("parameters/HitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		attacking = false

func shoot_fireball() -> void:
	if not multiplayer.is_server() and get_parent().is_multiplayer_authority():
		get_parent().shoot_fireball()

func get_inventory() -> InventoryData:
	return get_parent().inventory
