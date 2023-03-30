class_name Game
extends PanelContainer

signal player_ready

var finished = false

var keyboard = true
var controller_idx = 0
var player_ready_ = false
var game = null

func _ready():
	$vbox/name_input.keyboard = keyboard
	$vbox/name_input.controller_idx = controller_idx
	$vbox/name_input.focus()
	$vbox/top_status.text = "Choose your name & color"
	player_ready.connect(get_parent()._player_ready)
	
func get_action_suffix():
	if keyboard:
		return "_kb"
	return "_" + str(controller_idx)

func resize():
	var w = get_viewport_rect().size.x / (get_parent().get_children().size() - 1)
	var h = get_viewport_rect().size.y
	$vbox.custom_minimum_size.x = w
	$vbox.custom_minimum_size.y = h

func _on_name_input_done():
	$vbox/top_status.text = $vbox/name_input.get_name_() + " ready!"
	$vbox/top_status.modulate = $vbox/name_input.get_color()
	$vbox/top_status.visible = true
	$vbox/name_input.visible = false
	$vbox.alignment = 0
	player_ready_ = true
	player_ready.emit()

func start():
	var g = load("res://games/" + Global.get_cur_game_name() + "/game.tscn").instantiate()
	g.controller_idx = controller_idx
	g.keyboard = keyboard
	g.score_changed.connect(_score_changed)
	g.game_finished.connect(_game_finished)
	g.max_size = Vector2i(int(size.x), int(size.y - $vbox/top_status.size.y))	
	g.player_color = $vbox/top_status.modulate
	game = g
	$vbox.add_child(g)

func input(event: String, strength: float):
	if game and not finished:
		game.input(event, strength)

func process(game_time: float, delta: float):
	if game and not finished:
		game.process(game_time, delta)

func _score_changed():
	if not finished:
		$vbox/top_status.text = $vbox/name_input.get_name_() + "'s score:" + str(game.score)

func _game_finished():
	if game:
		finished = true
		var score = game.score
		var nom = $vbox/name_input.get_name_()
		get_parent().game_finished(nom, score)
		#$vbox.remove_child(game)
		$vbox/top_status.text = nom + " FINISHED with score: " + str(score)
