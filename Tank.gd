extends RigidBody2D
export (PackedScene) var Shell
export (int) var player

signal dead
signal zero

const ROTATE_IMPULSE = 6000
const THROTTLE_IMPULSE = 600
const FIRE_IMPULSE = 50
const FIRE_SKEW = 30
const LOAD_TIME = 0.260
const SHOTS_PER_SEQUENCE = 3
const DAMAGE_RATIO = 1.4
const DESTROY_REWARD = 20
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
var points = 50
var lastDelta = 0
var focused = false
var ready = false
var virgin = true

func _ready():	
	if player == 1:
		$Sprite.modulate = Color(0.8, 0.6, 0)
	if player == 2:
		$Sprite.modulate = Color(0, 0.6, 0.9)		
	if player == 3:
		$Sprite.modulate = Color(0.7, 0.4, 0.7)		
	$InitTimer.start()
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

	var n = 0
	n += 1 if buttonPressed else 0
	n += 1 if leftPressed else 0
	n += 1 if rightPressed else 0
	if n > 1:
		return
	if n == 1:
		virgin = false

	if rightPressed:		
		apply_torque_impulse(ROTATE_IMPULSE*delta)		
		return
	
	if leftPressed:
		apply_torque_impulse(-ROTATE_IMPULSE*delta)
		return
			
	if buttonPressed:
		buttonDuration += delta
		if buttonDuration > 0.15:
			apply_impulse(Vector2(0,0), transform.basis_xform(Vector2(0,-THROTTLE_IMPULSE*delta)))	
	else:
		if buttonDuration > 0 && buttonDuration < 0.15:
			fire()
		buttonDuration = 0				

func fire():
	if not loading and points > 0:
		shot += 1
		var s = Shell.instance()
		s.transform = transform * $Muzzle.transform
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
		apply_impulse(Vector2(FIRE_SKEW*randf()-FIRE_SKEW/2,FIRE_SKEW*randf()-FIRE_SKEW/2), 
			transform.basis_xform(Vector2(0, FIRE_IMPULSE*randf())))
		loading = true		
		addPoints(-1)

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

func addPoints(delta):
	var newPoints = max(0, points+delta)
	lastDelta = points - newPoints	
	points = newPoints	
	if abs(lastDelta) > 1:
		showPoints()
	if points == 0:
		emit_signal("zero")

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

func die():
	emit_signal("dead")
	$Life.hide()
	$Sprite.modulate = Color(0.2,0.2,0.2)
	$Explosion.restart()
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
	if virgin:
		die()

func _on_MouseButton_pressed():
	if virgin:
		die()
