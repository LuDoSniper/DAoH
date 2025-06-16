extends Node3D

@onready var weapon = $Rig/Skeleton3D/BoneAttachment3D/Skeleton_Axe
@onready var skeleton_shield: Node3D = $Rig/Skeleton3D/BoneAttachment3D2/Skeleton_Shield

var parent

var attacking := false:
	set(value):
		if parent:
			parent.attacking = value
		attacking = value

func set_attacking(value: bool) -> void:
	attacking = value

func set_can_damage(value: bool) -> void:
	weapon.can_damage = value

func deactivate() -> void:
	skeleton_shield.deactivate()

func activate() -> void:
	skeleton_shield.activate()
