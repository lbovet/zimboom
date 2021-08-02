extends Area2D

signal tank_removed(tank)
signal game_over

var candidates

func _ready():
	candidates = [ $Tank1, $Tank2, $Tank3 ]

var winner = null

func update():
	print("updating ", len(candidates))
	if len(candidates) < 2:
		if len(candidates) == 1:
			winner = candidates[0]
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
