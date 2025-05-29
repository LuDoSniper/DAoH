extends Node3D

@onready var weapons = [
	$"Rig/Skeleton3D/1H_Axe/Axe_1H",
	$"Rig/Skeleton3D/2H_Axe/Axe_2H"
]

var parent

func set_attacking(value: bool) -> void:
	parent.attacking = value

func set_can_damage(value: bool) -> void:
	for weapon in weapons:
		if weapon.data.name == parent.get_inventory().right_hand.name:
			weapon.can_damage = value
