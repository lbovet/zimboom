extends Node2D

const DEBUG_PATHS = false

var rocks
var triangles
var ready = false
var paths

signal paths_updated(paths)

func _on_Game_ready():
	rocks = []
	for terrain in get_parent().get_parent().currentLevel.get_children():
		for child in terrain.get_children():
			if child.is_in_group("rock"):
				rocks.append(child)				
	triangulate()
	$PathUpdate.start()

func _draw():
	if not ready:
		return
	if DEBUG_PATHS:
		for rock in rocks:
			draw_circle(to_local(rock.global_position), 4, Color(1,1,1,0.5))
		for c in getCorners():
			draw_circle(to_local(c), 6, Color(1,0,0,0.5))
	var threshold = 80
	paths = []
	var blacklist = []
	for t in triangles:
		var path = []
		for i in range(0,3):
			if DEBUG_PATHS:
				draw_polyline([t[i], t[(i+1) % 3]], Color(0,1,0,0.1))
			var weight = (t[i] - t[(i+1) % 3]).length()			
			var center = t[i] + (t[(i+1) % 3] - t[i])/2
			if (center - t[(i+2)%3]).length() < threshold / 2:
				blacklist.append(center)
			else:
				if weight > threshold and insideMargin(center, threshold / 2):
					path.append(center)
		if len(path) > 2:
			path.append(path[0])
		paths.append(path)			
	for path in paths:
		var toRemove=[]
		for point in blacklist:
			for i in range(len(path)-1,-1, -1):
				if (point - path[i]).length() < 10:
					path.remove(i)	
		if len(path) == 1:
			path.remove(0)			
	for path in paths:			
		for i in range(len(path)-1, -1, -1):
			var n = 0
			for otherPath in paths:
				for otherPoint in otherPath:
					if (path[i] - otherPoint).length() < 1:
						n += 1
			if n < 2:
				path.remove(i)
	for path in paths:
		if len(path) == 1:
			path.remove(0)
		if DEBUG_PATHS:
			draw_polyline(path, Color(0,0,1))		
	emit_signal("paths_updated", paths)
		
func insideMargin(point: Vector2, margin):
	var corners = getCorners()
	var d = margin
	d = min(d, (point - corners[0]).x)
	d = min(d, (point - corners[0]).y)
	d = min(d, (corners[2] - point).x)
	d = min(d, (corners[2] - point).y)
	return d >= margin
		
func triangulate():
	var allPoints = PoolVector2Array()
	for rock in rocks:
		allPoints.append(rock.global_position)
	allPoints.append_array(getCorners())
	var allDelaunay = Geometry.triangulate_delaunay_2d(allPoints)
	var triangleArray = [];
	for triple in range(0, allDelaunay.size()/3):
		triangleArray.append([allDelaunay[triple*3], allDelaunay[triple*3+1], allDelaunay[triple*3+2]]);
	triangles = []
	for triple in triangleArray:
		triangles.append([allPoints[triple[0]], allPoints[triple[1]], allPoints[triple[2]]])
	ready = true
	update()
	
func getCorners():
	var node = get_parent().get_parent().get_node("Field/CollisionShape2D")
	var shape = node.shape
	var corners = []
	corners.append(node.to_global(shape.get_extents()*Vector2(-1,-1)))
	corners.append(node.to_global(shape.get_extents()*Vector2(-1, 1)))
	corners.append(node.to_global(shape.get_extents()*Vector2(1, 1)))
	corners.append(node.to_global(shape.get_extents()*Vector2(1, -1)))
	return corners

func _on_PathUpdate_timeout():
	triangulate()
