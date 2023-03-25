class_name Leaderboard
extends VBoxContainer

const FILE_SUFFIX = "_leaders.txt"
const FILE_SEP = " "
const DEF_NAME = "BOBBY"
const DEF_SCOR = 0
const SCOR_DIG = 9

const THEME = preload("res://res/theme_smaller.tres")

@onready var names = $panel/hor/list_names
@onready var seps = $panel/hor/list_seps
@onready var scores = $panel/hor/list_scores

@export var length = 10

var results = []

func open():
	results = []
	visible = true
	_try_to_load()

func get_filename():
	return "user://" + Global.get_cur_game_name() + FILE_SUFFIX

func _try_to_load():
	if FileAccess.file_exists(get_filename()):
		_load()
	else:
		_init_()
	_update_lines()

func _init_():
	for i in range(length):
		add_result(DEF_NAME, DEF_SCOR)
	_save()

func _load():
	results = []
	var leaders = FileAccess.open(get_filename(), FileAccess.READ)
	while leaders.get_position() < leaders.get_length() and results.size() < length:
		var line = leaders.get_line()
		var splt = line.split(FILE_SEP)
		var nom = splt[0]
		var score = int(splt[1])
		add_result(nom, score)

func _update_lines():
	for child in names.get_children():
		child.queue_free()
	for child in seps.get_children():
		child.queue_free()
	for child in scores.get_children():
		child.queue_free()
	for res in results:
		var l = Label.new()
		l.text = " ".repeat(DEF_NAME.length() - res[0].length()) + res[0]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l.theme = THEME
		names.add_child(l)
		l = Label.new()
		l.text = ":"
		l.theme = THEME
		seps.add_child(l)
		l = Label.new()
		l.theme = THEME
		var s = str(res[1])
		l.text = "0".repeat(SCOR_DIG - s.length()) + str(res[1])
		scores.add_child(l)

func _save():
	var leaders = FileAccess.open(get_filename(), FileAccess.WRITE)
	for res in results:
		leaders.store_line(res[0] + FILE_SEP + str(res[1]))

func _sort_descending(a, b):
	if a[1] > b[1]:
		return true
	return false

func _sort():
	results.sort_custom(_sort_descending)

func _trim():
	while results.size() > length:
		results.pop_back()

func add_result(nom: String, score: int):
	for r in results:
		if r[0] == nom and r[1] == score and r[0] != DEF_NAME and r[1] != DEF_SCOR:
			return
	results.push_back([nom, score])
	_sort()
	_trim()

func add_result_and_save(nom: String, score: int):
	add_result(nom, score)
	_save()

func _on_back_pressed():
	visible = false
	get_parent().get_node("main_menu").visible = true
	get_parent().get_node("main_menu/leaderboard").grab_focus()
