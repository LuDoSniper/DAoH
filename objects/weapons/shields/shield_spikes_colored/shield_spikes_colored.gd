extends Node3D

@onready var collision_shape_3d: CollisionShape3D = $StaticBody3D/CollisionShape3D

func _ready() -> void:
	activate()

func activate() -> void:
	collision_shape_3d.disabled = false

func deactivate() -> void:
	collision_shape_3d.disabled = true
