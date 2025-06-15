extends Node3D

@export var healing_force := 2.5

@onready var decal = $Decal
@onready var particles = $GPUParticles3D

@onready var timer: Timer = $Timer

var players := []

func _ready() -> void:
	decal.size = Vector3.ZERO
	particles.emitting = false

func spawn() -> void:
	var tween = create_tween()
	tween.tween_method(_set_decal_size, 0.0, 15.0, 0.5)
	particles.emitting = true
	timer.start()
	rpc("_sync_emitting", name.to_int(), true)

func despawn() -> void:
	var tween = create_tween()
	tween.tween_method(_set_decal_size, 15.0, 0.0, 0.5)
	particles.emitting = false
	timer.stop()
	rpc("_sync_emitting", name.to_int(), false)

@rpc("any_peer")
func _sync_emitting(id: int, value: bool) -> void:
	if not multiplayer.is_server() and name.to_int() == id:
		particles.emitting = value

func _set_decal_size(value: float) -> void:
	decal.size = Vector3.ONE * value
	rpc("_sync_decal_size", name.to_int(), value)

@rpc("any_peer")
func _sync_decal_size(id: int, value: float) -> void:
	if not multiplayer.is_server() and name.to_int() == id:
		decal.size = Vector3.ONE * value

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		players.append(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		players.pop_at(players.find(body))

func _on_timer_timeout() -> void:
	if multiplayer.is_server():
		print(players)
		for player in players:
			player.heal(healing_force)
