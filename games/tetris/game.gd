extends Node

var max_size: Vector2i
var offset: Vector2i

signal game_finished

var score = 0
signal score_changed

var keyboard = true
var controller_idx = 0

func input(_event: String, _strength: float):
	pass

func _ready():
	score = 0
	score_changed.emit()

func process(_game_time: float, _delta: float):
	pass
