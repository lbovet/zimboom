extends Area2D

export (PackedScene) var Aircraft

signal tank_removed(tank)
signal game_over

var candidates
var state = [0,0,0]

func _ready():
	candidates = [ $Tank1, $Tank2, $Tank3 ]
	$Tank1.setOthers([$Tank2, $Tank3])
	$Tank2.setOthers([$Tank1, $Tank3])
	$Tank3.setOthers([$Tank2, $Tank1])

var winner = null

func update():
	if len(candidates) < 2:
		if len(candidates) == 1 and not candidates[0].robot:
			winner = candidates[0]
		$Airfcrafts.stop()
		emit_signal("game_over")
	else:
		var zeroes=0
		var maybeWinner = null
		var humans=0
		for c in candidates:
			if c == null or c.robot:
				continue
			if c.points <= 0:
				zeroes += 1
			else:
				maybeWinner = c
			humans += 1
		if zeroes > humans-1:
			winner = maybeWinner
			$Airfcrafts.stop()
			emit_signal("game_over")
	
func _on_Tank1_dead():
	candidates.erase($Tank1)
	state[0] = $Tank1.type			
	emit_signal("tank_removed", 1)
	update()

func _on_Tank1_zero():
	update()

func _on_Tank2_dead():
	candidates.erase($Tank2)
	state[1] = $Tank2.type
	emit_signal("tank_removed", 2)
	update()

func _on_Tank2_zero():
	update()
	
func _on_Tank3_dead():
	candidates.erase($Tank3)
	state[2] = $Tank3.type
	emit_signal("tank_removed", 3)
	update()

func _on_Tank3_zero():
	update()
	
func spawnAircraft():
	var spawn_location
	if randf() > 0.5:		
		spawn_location = $Airfcrafts/UpperAircraftSpawner/PathFollow2D
	else:
		spawn_location = $Airfcrafts/LowerAircraftSpawner/PathFollow2D
		
	spawn_location.offset = randi()

	var aircraft = Aircraft.instance()
	add_child(aircraft)

	# Set the direction perpendicular to the path direction.
	var direction = spawn_location.rotation + PI

	# Set the position to a random location.
	aircraft.position = spawn_location.position

	# Add some randomness to the direction.
	direction += rand_range(-PI / 8, PI / 8)
	aircraft.rotation = direction

func _on_Airfcrafts_timeout():
	spawnAircraft()

func _on_PathCalculation_paths_updated(paths):
	if $Tank1 != null:
		$Tank1.updatePaths(paths)
	if $Tank2 != null:
		$Tank2.updatePaths(paths)
	if $Tank3 != null:
		$Tank3.updatePaths(paths)

func getState():
	return [ 
		$Tank1.type if $Tank1 != null else state[0],
		$Tank2.type if $Tank2 != null else state[1],
		$Tank3.type if $Tank3 != null else state[2]
	]

func setState(state):
	$Tank1.setType(state[0])
	$Tank2.setType(state[1])
	$Tank3.setType(state[2])

func _on_Tank1_robot():
	state[0] = $Tank1.type	
	emit_signal("tank_removed", 1)

func _on_Tank2_robot():
	state[1] = $Tank2.type	
	emit_signal("tank_removed", 2)

func _on_Tank3_robot():
	state[2] = $Tank3.type	
	emit_signal("tank_removed", 3)
