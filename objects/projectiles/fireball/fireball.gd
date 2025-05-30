extends Area3D

@export var damage := 2.0
@export var speed := 6.0

func _physics_process(delta: float) -> void:
	# Calculer la direction vers l'avant de l'objet (en tenant compte de sa rotation)
	var direction = global_transform.basis.z.normalized()
	
	# Déplacer le projectile en ligne droite dans cette direction
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if multiplayer.is_server():
		if body.has_method("hit"):
			body.hit(damage)
	
		rpc("_remote_queue_free", name.to_int())
		queue_free()

@rpc("any_peer")
func _remote_queue_free(id: int) -> void:
	if not multiplayer.is_server() and name.to_int() == id:
		queue_free()

func _on_life_timer_timeout() -> void:
	queue_free()
