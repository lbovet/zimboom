extends RigidBody2D

func _ready():
	rotate(randf()*PI)
	var yellow = 0.7+randf()*0.1
	modulate = Color(yellow, yellow, 0.7+randf()*0.1)

func hit(damage, source):
	pass
