extends Node

var games = []
var cur_game = -1

func _ready():
	games = DirAccess.get_directories_at("res://games")
	cur_game = 0

func get_cur_game_name():
	return games[cur_game]
