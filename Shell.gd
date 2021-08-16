extends Area2D

const HIT_REWARD = 2
var speed = 480
var shell_force = 70
var damage = 11
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
		body.apply_impulse(global_position-body.global_position, transform.basis_xform(Vector2(0,-shell_force)))

func _on_Shell_area_entered(area):	
	if area.is_in_group("target"):
		explode()
	if area.is_in_group("shell") and not exploding:
		if $Sprite.frame != 2:
			explode()

func setBig():
	var ratio = 207 / 160
	speed *= 0.5
	$Trail.process_material.emission_sphere_radius *= ratio
	$CollisionShape2D.scale = Vector2($CollisionShape2D.scale.x * ratio, 1)
	$Explosion.scale *= 2
	damage *= 3
	shell_force *= 2
	$Sprite.frame = 1
	
func setSmall():
	var ratio = 99 / 160.0
	speed *= 1.4
	$Trail.process_material.emission_sphere_radius *= ratio
	$CollisionShape2D.scale = Vector2($CollisionShape2D.scale.x * ratio, 1)
	$Explosion.scale *= ratio
	damage *= 0.8
	shell_force *= 0.6
	$Sprite.frame = 2

func explode():
	speed = 0
	exploding = true
	var damageRange = ($Explosion/ExplosionRange/Position2D.global_position - 
		$Explosion.global_position).length()
	for target in targets.values():		
		var distance = (target.global_position - $Explosion.global_position).length()
		var actualDamage = max(0, damage * (1 - (distance / damageRange)))		
		if target.is_in_group("tank") and target.life >= 0 and target != source:
			source.addPoints(HIT_REWARD)
		target.hit(actualDamage, source)
		
	$Sprite.hide()
	$Explosion/Particles2D.restart()
	$Explosion.show()
	$Explosion.play()				
	$CollisionShape2D.hide()

func _on_Explosion_animation_finished():	
	queue_free()
	
func _on_VisibilityNotifier2D_screen_exited():
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
