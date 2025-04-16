extends Node3D

# Skins
@onready var rogue_skin: Node3D = $Rogue

# Animation trees
@onready var rogue_tree = $Rogue/AnimationTree

# A DEFINIR
var animation_tree
var move_state_machine

enum skins {
	Rogue
}
@export var skin := skins.Rogue

func _ready() -> void:
	if skin == skins.Rogue:
		rogue_skin.show()
		animation_tree = rogue_tree
	
	move_state_machine = animation_tree.get("parameters/MoveStateMachine/playback")
	get_move_state_current_node()

func set_move_state(state: String) -> void:
	move_state_machine.travel(state)

func get_move_state_current_node() -> StringName:
	return move_state_machine.get_current_node()
