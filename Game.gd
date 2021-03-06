extends Node2D

var gameOver = false
var currentLevel
var clean = true

func _ready():
	var level = randi() % $Levels.get_children().size()
	currentLevel = $Levels.get_children()[level]
	for c in $Levels.get_children():
		if not c == currentLevel:
			c.queue_free()
	currentLevel.show()
	$GameOver.hide()
	if not OS.has_touchscreen_ui_hint():
		$Controls.queue_free()
	var save_game = File.new()
	if save_game.file_exists("user://savegame.save"):
		save_game.open("user://savegame.save", File.READ)	
		var data = parse_json(save_game.get_line())
		$Field.setState(data.players)
		save_game.close()
		
func _process(delta):
	if Input.is_action_just_pressed("reset"):
		if gameOver:
			$Camera2D.make_current()
			$GameOver.hide()
		save($Field.getState())	
		get_tree().reload_current_scene()

func _on_Field_game_over():
	save($Field.getState())
	$GameOver/Timer.start()
	if $Field.winner != null:
		$Field.winner.focus()	

func save(state):
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	save_game.store_line(to_json({ "players": state}))
	save_game.close()	

func _on_Timer_timeout():
	gameOver = true
	if $Field.winner == null:
		$GameOver.show()

func _on_Field_tank_removed(tank):
	clean = false
	if $Controls == null:
		return
	if(tank == 1):
		$Controls/Controls1.queue_free()
	if(tank == 2):
		$Controls/Controls2.queue_free()
	if(tank == 3):
		$Controls/Controls3.queue_free()
