extends Area3D

@export var damage := 2.0
@export var speed := 6.0

func _physics_process(delta: float) -> void:
	# Calculer la direction vers l'avant de l'objet (en tenant compte de sa rotation)
	var direction = global_transform.basis.z.normalized()
	
	# Déplacer le projectile en ligne droite dans cette direction
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("hit"):
		body.hit(damage)
	
	queue_free()

func _on_life_timer_timeout() -> void:
	queue_free()
