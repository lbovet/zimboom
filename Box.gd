extends RigidBody2D

export (PackedScene) var Shell

enum Content { SHELL=0, SMALL_SHELLS=1, BIG_SHELL=2, SPRING=3 }

var content = null
var targetScale = Vector2(1, 1)
var scaleDelta = Vector2(0.4, 0.4)
var blinks = 5
var shells = 0
var life = 8

func _ready():
	content = $Sprite/Content.frame

func setScale(scale):
	self.scale = scale
	scaleDelta = scale - targetScale

func _physics_process(delta):	
	if scale.length() > 1:
		var ratio = $FallTimer.time_left / $FallTimer.wait_time			
		scale = targetScale + ratio * scaleDelta

func setContent(content):
	$Sprite/Content.frame = content
	self.content = content

func hit(damage, source):
	life -= damage
	if life < 0:
		if content != Content.SPRING:
			fire(source)
		queue_free()
		
func fire(source, angle=0):	
	var s = Shell.instance()
	if content == Content.BIG_SHELL:
		s.setBig()
	elif content == Content.SMALL_SHELLS:
		s.setSmall()	
		if angle == 0:	
			fire(source, randf() * PI + PI / 3)
			fire(source, -randf() * PI + PI / 3)	
	s.transform = transform
	s.rotate(angle)
	get_parent().add_child(s)
	s.setSource(source)

func _on_PickArea_body_entered(body):
	if body.is_in_group("tank") and body.life > 0:
		collision_layer = 256
		collision_mask = 256
		$PickTimer.start()
		z_index = 0
		if content == Content.SPRING:
			body.addSpring()
		if content == Content.SHELL:
			body.addPoints(shells)
		if content == Content.BIG_SHELL:
			body.addBigShell()
		if content == Content.SMALL_SHELLS:
			body.addSmallShells()
			
func _on_FallTimer_timeout():
	z_index = 1
	collision_layer = 1
	set_angular_velocity(0)

func _on_PickTimer_timeout():
	if blinks % 2:
		modulate.a = 0
	else:
		modulate.a = 1
	blinks -= 1
	if blinks == 0:
		queue_free()
