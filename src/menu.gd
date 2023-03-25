class_name Menu
extends CenterContainer

func _ready():
	size = get_viewport().size
	var imgsz = $bg/img.texture.get_image().get_size()
	var scrsz = get_viewport_rect().size
	var ratio = max(scrsz.x, scrsz.y) / max(imgsz.x, imgsz.y)
	$bg/img.scale = Vector2.ONE * ratio
	for g in Global.games:
		$main_menu/game_select.add_item(g)
	$main_menu/game_select.grab_focus()

func _on_play_pressed():
	$main_menu.visible = false
	$game_panels.visible = true

func _on_leaderboard_pressed():
	$main_menu.visible = false
	$leaderboard.open()
	$leaderboard/back.grab_focus()

func _on_exit_pressed():
	get_tree().quit()

func _on_game_select_item_selected(index):
	Global.cur_game = index
