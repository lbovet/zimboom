extends Area2D

var speed = 480
const SHELL_FORCE = 70
const HIT_REWARD = 10
const DAMAGE = 11
var exploding = false

var targets = {}

var source

func _ready():
	$Explosion.hide()

func _physics_process(delta):
	position += -transform.y * speed * delta

func _on_shell_body_entered(body : PhysicsBody2D):
	explode()		
	if body is RigidBody2D:
		body.apply_impulse(global_position-body.global_position, transform.basis_xform(Vector2(0,-SHELL_FORCE)))

func _on_Shell_area_entered(area):	
	if area.is_in_group("target"):
		explode()
	if area.is_in_group("shell") and not exploding:
		explode()

func explode():
	speed = 0
	exploding = true
	var damageRange = ($Explosion/ExplosionRange/Position2D.global_position - 
		$Explosion.global_position).length()
		
	for target in targets.values():		
		var distance = (target.global_position - $Explosion.global_position).length()
		var damage = max(0, DAMAGE * (1 - (distance / damageRange)))		
		if target.is_in_group("tank") and target.life >= 0 and target != source:
			source.addPoints(HIT_REWARD)
		target.hit(damage, source)
		
	$Sprite.hide()
	$Particles2D.restart()
	$Explosion.show()
	$Explosion.play()				
	$CollisionShape2D.hide()

func _on_Explosion_animation_finished():	
	queue_free()
	
func _on_shell_area_exited(area):
	if area.is_in_group("range"):		
		queue_free()

func setSource(tank):
	addTarget(tank) # To enable close range self-damage
	source = tank

func addTarget(target):
	if target.is_in_group("target"):
		targets[target.get_instance_id()] = target
	
func removeTarget(target):
	if target.is_in_group("target"):
		targets.erase(target.get_instance_id())

func _on_ExplosionRange_area_entered(area):
	addTarget(area)

func _on_ExplosionRange_area_exited(area):
	removeTarget(area)

func _on_ExplosionRange_body_entered(body):
	addTarget(body)

func _on_ExplosionRange_body_exited(body):
	removeTarget(body)
