extends Node

var games = []
var cur_game = -1

var colors = [Color.hex(0xFF522AFF), Color.hex(0x23B373FF), Color.hex(0x868CF8FF), Color.hex(0xFECE42FF), Color.hex(0xFE6CA2FF), Color.hex(0xFFB2C9FF)]

func _ready():
	games = DirAccess.get_directories_at("res://games")
	cur_game = 0

func get_cur_game_name():
	return games[cur_game]
