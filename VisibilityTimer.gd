extends Timer

func _ready():
	get_parent().hide()

func start_default():
	get_parent().show()
	.start(wait_time)

func _on_Timer_timeout():
	get_parent().hide()
