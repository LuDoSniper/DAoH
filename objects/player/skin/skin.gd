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

enum skins {
	Knight,
	Barbarian,
	Mage,
	Rogue
}
@export var skin := skins.Rogue

func _ready() -> void:
	knight_skin.hide()
	barbarian_skin.hide()
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
	get_move_state_current_node()

func set_move_state(state: String) -> void:
	move_state_machine.travel(state)

func get_move_state_current_node() -> StringName:
	return move_state_machine.get_current_node()
