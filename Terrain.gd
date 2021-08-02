extends Polygon2D

export (float) var bushes
export (float) var rocks

var Bush = preload("res://Bush.tscn")
var Rock1 = preload("res://Rock1.tscn")
var Rock2 = preload("res://Rock2.tscn")
var Rock3 = preload("res://Rock3.tscn")

const MIN_DISTANCE = 40
const TRIES_RATIO = 2 / 5000.0

func _ready():
	color = Color(0,0,0,0)
	for pos in randomPositions(polygon, bushes + rocks):
		var elt
		if weightedRandom([bushes, rocks]) == 0:
			elt = Bush.instance()			
		else:
			elt = [ Rock1, Rock2, Rock3 ][randi() % 3].instance()			
		elt.position = pos
		add_child(elt)

func tx(p):
	return get_parent().transform.basis_xform(p)
		
func randomPositions(polygon, density):
	var p = Geometry.triangulate_polygon(polygon)
	var areas = []
	var triangles = []
	var totalArea = 0
	for i in range(0, len(p), 3):
		var triangle = [ tx(polygon[p[i]]), tx(polygon[p[i+1]]), tx(polygon[p[i+2]]) ]
		triangles.push_back(triangle)
		var area = triangleArea(triangle[0], triangle[1], triangle[2])
		areas.push_back(area)
		totalArea += area
	var tries = int(TRIES_RATIO * density * totalArea)
	var positions = []
	for i in range(tries):
		var t = triangles[weightedRandom(areas)]
		var current = randomPoint(t[0], t[1], t[2])
		var skip = false
		for pos in positions:
			if (current - pos).length() < MIN_DISTANCE:
				skip = true
				break
		if not skip:
			positions.push_back(current)
	return positions
		
func weightedRandom(weights: Array):
	var sum_of_weight = 0;
	for weight in weights:
	   sum_of_weight += weight
	var rnd = randf() * sum_of_weight
	for i in range(len(weights)):
		if rnd < weights[i]:
			return i
		rnd -= weights[i];

func triangleArea(A, B, C):
	var BA = A - B
	var BC = C - B
	var P = BA.cross(BC)
	return abs(P)/2

func randomPoint(A, B, C):
	var p = randf()
	var q = randf()
	if (p + q > 1):
		p = 1 - p
		q = 1 - q
	var x = A.x + (B.x - A.x) * p + (C.x - A.x) * q
	var y = A.y + (B.y - A.y) * p + (C.y - A.y) * q
	return Vector2( x, y )
