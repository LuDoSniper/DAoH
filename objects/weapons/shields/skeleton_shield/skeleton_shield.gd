extends Node3D

@onready var collision_shape_3d: CollisionShape3D = $StaticBody3D/CollisionShape3D

@onready var variants = [
	$Skeleton_Shield_Large_A2,
	$Skeleton_Shield_Large_B2,
	$Skeleton_Shield_Small_A2,
	$Skeleton_Shield_Small_B2
]

func _ready() -> void:
	for variant in variants:
		variant.hide()
	
	variants[randi_range(0, len(variants) - 1)].show()
	activate()

func activate() -> void:
	collision_shape_3d.disabled = false

func deactivate() -> void:
	collision_shape_3d.disabled = true
