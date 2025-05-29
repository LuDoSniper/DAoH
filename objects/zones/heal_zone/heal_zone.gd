extends Node3D

@onready var decal = $Decal
@onready var particles = $GPUParticles3D

func _ready() -> void:
	decal.size = Vector3.ZERO
	particles.emitting = false

func spawn() -> void:
	var tween = create_tween()
	tween.tween_method(_set_decal_size, 0.0, 15.0, 0.5)
	particles.emitting = true

func despawn() -> void:
	var tween = create_tween()
	tween.tween_method(_set_decal_size, 15.0, 0.0, 0.5)
	particles.emitting = false

func _set_decal_size(value: float) -> void:
	decal.size = Vector3.ONE * value
