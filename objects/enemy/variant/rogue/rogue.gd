extends Node3D

@onready var weapons = [
	$Rig/Skeleton3D/BoneAttachment3D/Dagger,
	$Rig/Skeleton3D/BoneAttachment3D/Crossbow
]

var parent

var attacking := false:
	set(value):
		if parent:
			parent.attacking = value
		attacking = value

func set_attacking(value: bool) -> void:
	attacking = value

func set_can_damage(value: bool) -> void:
	# Il faut selectionner la bonne arme au lieu de toutes les faire. Je le ferais plus tard
	for weapon in weapons:
		weapon.can_damage = value

func shoot() -> void:
	parent.shoot_arrow()

func show_crossbow() -> void:
	weapons[0].hide()
	weapons[1].show()

func show_dagger() -> void:
	weapons[1].hide()
	weapons[0].show()
