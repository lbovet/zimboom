extends RigidBody2D

export (PackedScene) var Shell
export (PackedScene) var Box

export (int) var player

signal dead
signal zero
signal robot

const SMALL_ROTATE_RATIO = 0.2
const ROTATE_IMPULSE = 6000
const THROTTLE_IMPULSE = 600
const FIRE_IMPULSE = 60
const FIRE_SKEW = 40
const LOAD_TIME = 0.260
const SHOTS_PER_SEQUENCE = 3
const DAMAGE_RATIO = 1.4
const DESTROY_REWARD = 15
const SHOW_OFF_IMPULSE = 100
const FULL_LIFE = Color(0.1, 0.7, 0.1)
const HIGH_LIFE = Color(0.6, 0.7, 0.1)
const MEDIUM_LIFE = Color(0.9, 0.7, 0.1)
const LOW_LIFE = Color(0.9, 0.1, 0.1)
const OFF = Color(0.1, 0.1, 0.1, 0)

const MAX_LIFE = 32
var life = MAX_LIFE

var buttonDuration = 0
var loading = false
var shot = 0
var points = 30
var lastDelta = 0
var focused = false
var ready = false
var virgin = true
var springed = false
var bigShell = 0
var smallShells = 0
var robot = false
var others = []
var color

enum Type { HUMAN, ROBOT, REMOVE }
var type = Type.HUMAN

func _ready():	
	if player == 1:
		color = Color(0.8, 0.6, 0)
	if player == 2:
		color = Color(0, 0.6, 0.9)		
	if player == 3:
		color = Color(0.7, 0.4, 0.7)		
	$Sprite.modulate = color
	$InitTimer.start()
	$Remove.hide()
	$Robot/Sprite.hide()
	$Label.hide()
	$Life.hide()

func _physics_process(delta):
	if focused:
		apply_torque_impulse(SHOW_OFF_IMPULSE)
	
	if life < 0 or focused or not ready:
		return 
		
	var buttonPressed = Input.is_action_pressed("p"+str(player)+"_button")
	var rightPressed = Input.is_action_pressed("p"+str(player)+"_right")
	var leftPressed = Input.is_action_pressed("p"+str(player)+"_left")
	var amplitude = SMALL_ROTATE_RATIO if Input.is_action_just_pressed("p"+str(player)+"_right") or \
		Input.is_action_just_pressed("p"+str(player)+"_left") else 1

	var n = 0
	n += 1 if buttonPressed else 0
	n += 1 if leftPressed else 0
	n += 1 if rightPressed else 0
	if n > 1:
		return
	if n == 1:
		virgin = false

	if rightPressed:		
		rotation_impulse(delta, true, amplitude)	
		return
	
	if leftPressed:
		rotation_impulse(delta, false, amplitude)
		return
			
	if buttonPressed:
		buttonDuration += delta
		if buttonDuration > 0.15:
			throttle(delta)	
	else:
		if buttonDuration > 0 && buttonDuration < 0.15:
			fire()
		buttonDuration = 0				

func throttle(delta):
	apply_impulse(Vector2(0,0), transform.basis_xform(Vector2(0,-THROTTLE_IMPULSE*delta)))	

func rotation_impulse(delta, inverse, amplitude=1):
	if inverse:
		apply_torque_impulse(ROTATE_IMPULSE*delta*amplitude)		
	else:
		apply_torque_impulse(-ROTATE_IMPULSE*delta*amplitude)
		
func fire(angle=0):
	if not loading and points > 0 or bigShell > 0 or smallShells > 0:		
		var s = Shell.instance()
		if bigShell > 0:
			s.setBig()
			bigShell -= 1
		elif smallShells > 0:
			s.setSmall()
			smallShells -= 1		
			if angle == 0:	
				fire(-PI/28)
				fire(PI/28)
		else:
			shot += 1
			addPoints(-1)		
		s.transform = transform * $Muzzle.transform
		s.rotate(angle)
		get_parent().add_child(s)
		$Muzzle/MuzzleFire/Timer.start_default()	
		s.setSource(self)
		if shot == SHOTS_PER_SEQUENCE:
			showPoints()
			$LoadTimer.start(2 * LOAD_TIME)
			shot = 0
		else:
			$LoadTimer.start(LOAD_TIME)
		# recoil
		if not springed and angle == 0 or bigShell:
			apply_impulse(Vector2(FIRE_SKEW*randf()-FIRE_SKEW/2,FIRE_SKEW*randf()-FIRE_SKEW/2), 
				transform.basis_xform(Vector2(0, FIRE_IMPULSE*randf())))
		loading = true		
		

func hit(damage, source):
	virgin = false
	if life < 0:
		return
	life -= damage * DAMAGE_RATIO
	showLife()
	if life < 0:
		source.addPoints(DESTROY_REWARD)
		die()	

func showLife():
	var color
	color = FULL_LIFE if life == MAX_LIFE else OFF
	$Life/Full.modulate = color
	if color == OFF:
		color = HIGH_LIFE if life > MAX_LIFE*0.75 else OFF
	$Life/High.modulate = color
	if color == OFF:
		color = MEDIUM_LIFE if life > MAX_LIFE*0.5 else OFF
	$Life/Medium.modulate = color
	if color == OFF:
		color = LOW_LIFE
	$Life/Low.modulate = color
	$Life.show()
	$Life/Fade.start()

func addLife(ratio):
	life = min(MAX_LIFE, life + ratio*MAX_LIFE)
	showLife()

func addPoints(delta):
	var newPoints = max(0, points+delta)
	lastDelta = points - newPoints	
	points = newPoints	
	if abs(lastDelta) > 1:
		showPoints()
	if points == 0:
		emit_signal("zero")

func addBigShell():
	bigShell += 2
	
func addSmallShells():
	smallShells += 9

func showPoints(hide=true):
	if(lastDelta == 0):
		$Label.modulate = Color(1, 1, 1)
	if(lastDelta < 0):
		$Label.modulate = Color(0.7, 1, 0.7)
	if(lastDelta > 0):
		$Label.modulate = Color(1, 0.7, 0.7)
	$Label.text = str(points)
	$Label.show()
	if hide:
		$Label/Hide.start()

func focus():
	focused = true
	showPoints(false)
	$Button.action = "reset"
	$Camera2D/FocusTimer.start()

func _on_LoadTimer_timeout():
	loading = false

func _on_Fade_timeout():
	$Life.hide()	

func addSpring():
	springed = true

func setOthers(tanks):
	others = tanks

func die(emit=true):
	emit_signal("dead")
	$Life.hide()
	$Sprite.modulate = Color(0.2,0.2,0.2)
	$Explosion.restart()
	if points > 0 and emit:
		var box = Box.instance()
		box.shells = points / 3		
		box.global_position = global_position
		get_parent().add_child(box)
		box.collision_layer = 128
		box.collision_mask = 128
		box.apply_central_impulse(-transform.y * 300)
	if virgin:
		queue_free()

func _on_Hide_timeout():
	if not focused:
		$Label.hide()

func _on_FocusTimer_timeout():	
	$Camera2D.make_current()

func _on_InitTimer_timeout():
	showLife()
	showPoints()
	ready = true

func _on_TankButton_pressed():
	switchType()

func _on_MouseButton_pressed():
	switchType()

func setType(newType):
	robot = false
	if newType == 1:
		type = Type.ROBOT
		robot = true
		$Robot/Sprite.show()
		$Sprite.modulate = Color(0.2, 0.7, 0.3)
	elif newType == 2:
		$Sprite.modulate = color
		type = Type.REMOVE
		$Robot/Sprite.hide()
		$Remove.show()
	elif newType == 0:
		type = Type.HUMAN
		$Remove.hide()

func switchType():
	if virgin:
		if type == Type.HUMAN:
			setType(Type.ROBOT)
		elif type == Type.ROBOT:
			setType(Type.REMOVE)
		elif type == Type.REMOVE:
			setType(Type.HUMAN)		

func updatePaths(paths):
	$Robot.updatePaths(paths)
