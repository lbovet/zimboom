extends RigidBody2D


func _on_PickArea_body_entered(body):
	if body.is_in_group("tank") and body.life > 0:
		queue_free()
