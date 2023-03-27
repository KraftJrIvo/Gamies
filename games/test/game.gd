extends Node

var max_size: Vector2i
var offset: Vector2i

signal game_finished

var score = 0
signal score_changed

var keyboard = true
var controller_idx = 0

var scoff = 0

func input(event: String, strength: float):
	if strength > 0.5:
		if event == "up":
			scoff += 10
			score_changed.emit()
		elif event == "down":
			scoff -= 10
			score_changed.emit()
		elif event == "accept":
			game_finished.emit()

func _ready():
	score = 0
	score_changed.emit()

func process(game_time: float, _delta: float):
	score = scoff + floor(game_time)
	score_changed.emit()
