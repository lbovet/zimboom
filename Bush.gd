extends Area2D

var life = 25

func _ready():
	rotate(randf()*PI)
	modulate = Color(0.4+randf()*0.2, 0.4+randf()*0.2, 0.4+randf()*0.2)
	$Sprite.frame = randi() % 3
	var r = int($CollisionShape2D.shape.radius * randf())
	$CollisionShape2D.shape.radius = r

func hit(damage, source):
	life -= damage
	if life < 0:
		destroy()
		source.addPoints(-2)
	
func destroy():
	$Sprite.hide()
	$Particles2D.restart()
	if $CollisionShape2D != null:
		$CollisionShape2D.remove_and_skip()
	if $Area2D/CollisionShape2D != null:
		$Area2D/CollisionShape2D.remove_and_skip()

func _on_Bush1_body_entered(body):
	if body.is_in_group("heavy"):
		destroy()
		if body.is_in_group("tank"):
			body.addPoints(-2)
