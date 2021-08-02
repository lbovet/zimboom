extends Node2D

var gameOver = false

func _ready():
	var level = randi() % $Levels.get_children().size()
	var node = $Levels.get_children()[level]
	for c in $Levels.get_children():
		if not c == node:
			c.queue_free()
	node.show()
	$GameOver.hide()
	if not OS.has_touchscreen_ui_hint():
		$Controls.queue_free()

func _process(delta):
	if Input.is_action_just_pressed("reset"):
		if gameOver:
			$Camera2D.make_current()
			$GameOver.hide()
		get_tree().reload_current_scene()

func _on_Field_game_over():
	$GameOver/Timer.start()
	if $Field.winner != null:
		$Field.winner.focus()	

func _on_Timer_timeout():
	gameOver = true
	if $Field.winner == null:
		$GameOver.show()

func _on_Field_tank_removed(tank):
	if $Controls == null:
		return
	if(tank == 1):
		$Controls/Controls1.queue_free()
	if(tank == 2):
		$Controls/Controls2.queue_free()
	if(tank == 3):
		$Controls/Controls3.queue_free()
