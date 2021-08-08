extends Area2D

export (PackedScene) var Aircraft

signal tank_removed(tank)
signal game_over

var candidates

func _ready():
	candidates = [ $Tank1, $Tank2, $Tank3 ]
	$Tank1.setOthers([$Tank2, $Tank3])
	$Tank2.setOthers([$Tank1, $Tank3])
	$Tank3.setOthers([$Tank2, $Tank1])

var winner = null

func update():
	if len(candidates) < 2:
		if len(candidates) == 1:
			winner = candidates[0]
		$Airfcrafts.stop()
		emit_signal("game_over")
	else:
		var zeroes=0
		var maybeWinner = null
		for c in candidates:
			if c == null:
				continue
			if c.points == 0:
				zeroes += 1
			else:
				maybeWinner = c
		if zeroes > len(candidates) -1:
			winner = maybeWinner
			$Airfcrafts.stop()
			emit_signal("game_over")
	
func _on_Tank1_dead():
	candidates.erase($Tank1)
	emit_signal("tank_removed", 1)
	update()

func _on_Tank1_zero():
	update()

func _on_Tank2_dead():
	candidates.erase($Tank2)
	emit_signal("tank_removed", 2)
	update()

func _on_Tank2_zero():
	update()
	
func _on_Tank3_dead():
	candidates.erase($Tank3)
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
	$Tank1.updatePaths(paths)
	$Tank2.updatePaths(paths)
	$Tank3.updatePaths(paths)
