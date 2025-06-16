extends Node3D

@onready var spawner: Marker3D = $Marker3D
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D

var busy: bool = false
var occupants: Array[Node]

func get_global_pos() -> Vector3:
	return spawner.global_position

func is_busy() -> bool:
	return busy

func _on_area_3d_body_entered(body: Node3D) -> void:
	add_occupant(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	remove_occupant(body)

func add_occupant(occupant: Node3D) -> void:
	occupants.append(occupant)
	busy = true

func remove_occupant(occupant: Node3D) -> void:
	occupants.pop_at(occupants.find(occupant))
	busy = occupants != []

func emitt() -> void:
	gpu_particles_3d.emitting = true
