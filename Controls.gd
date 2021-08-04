extends Node2D


export (int) var player

func _ready():
	$Left/TouchScreenButton.action = "p"+str(player)+"_left"
	$Button/TouchScreenButton.action = "p"+str(player)+"_button"
	$Right/TouchScreenButton.action = "p"+str(player)+"_right"
