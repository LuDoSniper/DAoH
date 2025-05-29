extends Node3D

@onready var weapons = [
	$"Rig/Skeleton3D/1H_Sword/Sword_1H",
	$"Rig/Skeleton3D/2H_Sword/Sword_2H",
	$"Rig/Skeleton3D/2H_Sword/Sword_2H_Colored"
]

var parent

func set_attacking(value: bool) -> void:
	parent.attacking = value

func set_can_damage(value: bool) -> void:
	for weapon in weapons:
		if weapon.data.name == parent.get_inventory().right_hand.name:
			weapon.can_damage = value
