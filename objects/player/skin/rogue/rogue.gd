extends Node3D

@onready var weapons = [
	$Rig/Skeleton3D/Knife/Dagger
]

var parent

func set_attacking(value: bool) -> void:
	parent.attacking = value

func set_can_damage(value: bool) -> void:
	for weapon in weapons:
		if weapon.data.name == parent.get_inventory().right_hand.name:
			weapon.can_damage = value

func shoot() -> void:
	parent.get_parent().shoot_arrow()
