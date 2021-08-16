extends Node2D

var paths
var currentDestination = null
const DIR_DISTANCE=300
const DISPERSE_DISTANCE=75
var disperse = false
var dispersing = 0
var currentPaths = []
var shooting = false
var updating = 0
var started = false
var original

func updatePaths(paths):
	self.paths = paths

func _ready():
	$RayCast2D.add_exception(get_parent())
	$RayCast2D.collide_with_areas = true
	$FireLine.add_exception(get_parent())
	$FireLine.collide_with_areas = true
	$RayCast2D.enabled = true

func _physics_process(delta):
	var start = true
	if not started:
		for other in get_parent().others:
			if weakref(other).get_ref() and not other.robot:
				start = start and not other.virgin
		started = start
		if started and get_parent().robot:
			get_parent().emit_signal("robot")
	if get_parent().type == get_parent().Type.REMOVE and started:
		get_parent().die(false)
		return
	if get_parent().robot and started and get_parent().life > 0 and paths != null:		
		$Sprite.hide()
		if updating == 0:
			computeDestination()
			disperse = false
			var disperseTarget = Vector2(0,-DISPERSE_DISTANCE).rotated(global_rotation)
			for other in get_parent().others:
				if !weakref(other).get_ref():
					continue
				if not other.robot:
					$RayCast2D.cast_to = to_local(other.global_position)
					$RayCast2D.force_raycast_update()
					if $RayCast2D.get_collider() == other and other.life > 0:
						currentDestination = other.global_position
						shooting = true
					else:
						shooting = false
				if other.robot and other.life > 0 and \
					(other.global_position + Vector2(0,-DISPERSE_DISTANCE).rotated(other.global_rotation)) \
					.distance_to(global_position + disperseTarget) < DISPERSE_DISTANCE * 1.5:	
						disperse = true			
			if disperse or dispersing > 0:
				dispersing += delta
			if dispersing > 2:
				dispersing = 0
		var dir = Vector2(0,-DIR_DISTANCE).rotated(global_rotation)	
		var angle = (currentDestination - global_position).angle_to(dir)
		if $FireLine.is_colliding() and updating == 0:
			var other = $FireLine.get_collider()
			if other.is_in_group("tank") and not other.robot and other.life > 0:
				get_parent().fire()
				shooting = true
			
		if abs(angle) > PI / 32 or disperse or shooting:
			get_parent().rotation_impulse(delta, (angle < 0) or (dispersing > 0))
		else:
			get_parent().throttle(delta)
		updating += delta
		if updating > 0.5:
			updating = 0
	
func computeDestination():
	var threshold = 20
	var destination 
	var pos = global_position
	var closest = Vector2(100000,100000)
	var newPaths = []
	for path in paths:
		for point in path:
			if point.distance_to(pos) < closest.distance_to(pos):
				closest = point
			if point.distance_to(pos) < threshold:
				newPaths.append(path)
	if len(newPaths) > 0:
		currentPaths = newPaths
	if currentDestination == null:
		destination = closest
	else:
		destination = currentDestination
	var direction = pos + Vector2(0,-DIR_DISTANCE).rotated(global_rotation)		
	for path in currentPaths:
		for point in path:
			if point.distance_to(destination) > 10 and point.distance_to(direction) < destination.distance_to(direction):
				destination = point			
	
	if len(currentPaths) == 0 and pos.distance_to(destination) < threshold / 2:
		closest = Vector2(100000,100000)
		for path in paths:
			for point in path:
				if point.distance_to(pos) < closest.distance_to(pos):
					closest = point			
		destination = closest
		
	currentDestination = destination
	$Destination.global_position = currentDestination
	

