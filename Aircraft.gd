extends Area2D
	
export (PackedScene) var Box
	
var speed = 400

var obstacles = 0
var dropAllowed = false
var dropped = false

func _ready():
	$DropTimer.start(0.9 + (0.2 - randf()*0.4))

func _physics_process(delta):
	position += -transform.y * speed * delta
	if not dropped and dropAllowed and obstacles == 0:
		drop()
	
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
	
func drop():	
	var box = Box.instance()
	box.global_position = global_position
	box.apply_central_impulse(-transform.y * 500)
	box.rotation = rotation + rand_range(-PI / 2, PI / 2)
	var rnd = randf()
	if rnd < 0.5:
		box.setContent(1)
	elif rnd < 0.9: 		
		box.setContent(2)
	else:
		box.setContent(3)		
	box.z_index = z_index - 1
	box.collision_layer = 128
	box.collision_mask = 128
	box.set_angular_velocity(5)
	get_parent().add_child(box)
	box.setScale(Vector2(1.5, 1.5))
	dropped = true

func _on_DropTimer_timeout():
	dropAllowed = true

func _on_Aircraft_body_entered(body):
	obstacles += 1

func _on_Aircraft_body_exited(body):
	obstacles -= 1
