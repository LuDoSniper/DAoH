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
	match skin:
		skins.Knight:
			match attack_name:
				"base":
					attack_state_machine.travel("Slice_Horizontal")
				"base_2H":
					attack_state_machine.travel("2H_Slice")
		skins.Barbarian:
			match attack_name:
				"base":
					attack_state_machine.travel("Slice_Horizontal")
				"base_2H":
					attack_state_machine.travel("2H_Slice")
		skins.Mage:
			match attack_name:
				"base":
					attack_state_machine.travel("Spellcast_Shoot")
				"special":
					attack_state_machine.travel("Spellcast_Raise")
		skins.Rogue:
			match attack_name:
				"base":
					attack_state_machine.travel("Slice_Horizontal")
				"shoot":
					attack_state_machine.travel("Shoot")
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

func hit() -> void:
	var animations = [
		"Hit_A",
		"Hit_B"
	]
	hit_state_machine.travel(animations[randi_range(0, len(animations) - 1)])
	animation_tree.set("parameters/HitOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	attacking = false

func shoot_fireball() -> void:
	get_parent().shoot_fireball()

func get_inventory() -> InventoryData:
	return get_parent().inventory
