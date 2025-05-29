extends Node3D

var parent

func set_attacking(value: bool) -> void:
	parent.attacking = value

func shoot_fireball() -> void:
	get_parent().shoot_fireball()
