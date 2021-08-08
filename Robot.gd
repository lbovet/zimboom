extends Node2D

var paths
var currentDestination = null
const DIR_DISTANCE=300
const DISPERSE_DISTANCE=75
var dispersing = 0
var currentPaths = []
var shooting = false

func updatePaths(paths):
	self.paths = paths

func _ready():
	$RayCast2D.collide_with_areas = true
	$RayCast2D.enabled = true
	$RayCast2D.add_exception(get_parent())

func _physics_process(delta):
	if get_parent().robot and paths != null:
		computeDestination()
		var disperse = false
		var disperseTarget = Vector2(0,-DISPERSE_DISTANCE).rotated(global_rotation)
		for other in get_parent().others:
			$RayCast2D.cast_to = to_local(other.global_position)
			if $RayCast2D.get_collider() == other:
				currentDestination = other.global_position
				shooting = true
			else:
				shooting = false
			if other != null and other.robot and \
				(other.global_position + Vector2(0,-DISPERSE_DISTANCE).rotated(other.global_rotation)) \
				.distance_to(global_position + disperseTarget) < DISPERSE_DISTANCE * 1.5:	
					disperse = true			
		if disperse or dispersing > 0:
			dispersing += delta
		if dispersing > 2:
			dispersing = 0
		var dir = Vector2(0,-DIR_DISTANCE).rotated(global_rotation)	
		var angle = (currentDestination - global_position).angle_to(dir)
		if shooting:
			$RayCast2D.cast_to = Vector2(-1000,0)								
			if $RayCast2D.is_colliding() and $RayCast2D.get_collider().is_in_group("tank"):
				get_parent().fire()
			
		if abs(angle) > PI / 60 or disperse:
			get_parent().rotation_impulse(delta, (angle < 0) or (dispersing > 0 and not shooting))
		else:
			get_parent().throttle(delta)
	
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
				if point.distance_to(direction) < closest.distance_to(direction):
					closest = point			
		destination = closest
		
	currentDestination = destination
	$Destination.global_position = currentDestination
	

