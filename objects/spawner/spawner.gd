extends Node3D

@onready var spawner: Marker3D = $Marker3D

var busy: bool = false
var occupants: Array[Node]

func get_global_pos() -> Vector3:
	return spawner.global_position

func is_busy() -> bool:
	return busy

func _on_area_3d_body_entered(body: Node3D) -> void:
	occupants.append(body)
	busy = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	occupants.pop_at(occupants.find(body))
	busy = occupants != []
