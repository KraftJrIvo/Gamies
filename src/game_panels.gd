extends HBoxContainer

const GAME_PANEL = preload("res://game_panel.tscn")

const START_DELAY = 0.25

signal all_players_ready

var kb_added = false
var panels = [null, null, null, null, null]
var all_ready = false
var all_finished = false

var time = 0

func _ready():
	$center.size = get_viewport_rect().size

func _reset():
	for ch in get_children():
		if ch != $center:
			remove_child(ch)
	kb_added = false
	panels = [null, null, null, null, null]
	all_ready = false
	all_finished = false
	time = 0
	$center.visible = true

func _input(event):
	if visible:
		if event.is_action("ui_home"):
			_reset()
			visible = false
			get_parent().get_node("main_menu").visible = true
			get_parent().get_node("main_menu").get_node("game_select").grab_focus()
		if get_children().size() == 1 or (not all_ready):
			var start = false
			var idx = -1
			for i in range(4):
				if not panels[i]:
					var this_one = event.is_action_pressed("start_" + str(i))
					start = start or this_one
					if this_one:
						idx = i
			if not kb_added:
				start = start or event.is_action_pressed("start_kb")
			if start:
				var game_panel = GAME_PANEL.instantiate()
				game_panel.keyboard = (idx == -1)
				kb_added = kb_added or game_panel.keyboard
				game_panel.controller_idx = idx
				all_players_ready.connect(game_panel.start)
				add_child(game_panel)
				$center.visible = false
				panels[4 if idx == -1 else idx] = game_panel
				for g in get_children():
					if g != $center:
						g.resize()
		else:
			if time > START_DELAY:
				var strength = 0
				for action in InputMap.get_actions():
					if InputMap.event_is_action(event, action):
						var ok = false
						for p in panels:
							if p and action.ends_with(p.get_action_suffix()):
								ok = true
								break
						if ok:
							strength = event.get_action_strength(action)
							var kb = action.contains("_kb")
							var strg: String = action
							var idx = -1 if kb else int(strg[strg.length() - 1])
							var p = panels[4 if idx == -1 else idx]
							if not p.finished:
								p.input(strg.substr(0, strg.length() - p.get_action_suffix().length()), strength)

func _player_ready():
	var chs = get_children()
	if chs.size() == 1:
		return false
	var all = true
	for ch in chs:
		if ch != $center:
			if not ch.player_ready_:
				all = false
				break
	if all:
		all_ready = true
		all_players_ready.emit()

func _process(delta):
	if all_ready:
		time += delta
	for ch in get_children():
		if ch != $center:
			ch.process(time, delta)

func game_finished(nom: String, score: int):
	get_parent().get_node("leaderboard").add_result_and_save(nom, score)
	var all = true
	for ch in get_children():
		if ch != $center:
			
				break
	all_finished = all	
