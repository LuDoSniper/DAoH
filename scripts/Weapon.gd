class_name Weapon
extends Node3D

@onready var raycast = $RayCast3D

var data: WeaponData

var can_damage := false

func _process(_delta):
	if can_damage:
		var collider = raycast.get_collider()
		if collider and collider.has_method("hit"):
			collider.hit(data.damage)
