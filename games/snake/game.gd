class_name SnakeGame
extends PanelContainer

var player_color: Color
var max_size: Vector2i
var keyboard = true
var controller_idx = 0
var score = 0

signal game_finished
signal score_changed

const TEX_H = preload("res://games/snake/H.png")
const TEX_He = preload("res://games/snake/He.png")
const TEX_Hd = preload("res://games/snake/Hd.png")
const TEX_I = preload("res://games/snake/I.png")
const TEX_T = preload("res://games/snake/T.png")
const TEX_L = preload("res://games/snake/L.png")

const FOOD_1 = preload("res://games/snake/a1.png")
const FOOD_2 = preload("res://games/snake/a2.png")
const FOOD_3 = preload("res://games/snake/a3.png")

var field_side
var field_size = 16
var mov_per_sec = 2
var cur_mov_per_sec = mov_per_sec
var cur_dir = Vector2i(1, 0)
var since_last_mov = 0
var parts = [Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8), Vector2i(9, 8), Vector2i(10, 8)]
var sprites = []
var food = [[Vector2i(7, 7), 0]]
var food_sprites = []
var changed_dir = false
var eating = false
var food_eaten = 0
var dead = false
var sprint = false

func input(event: String, strength: float):
	if event == "accept":
		sprint = strength > 0
	var new_dir = Vector2i.ZERO
	if not changed_dir:
		if event == "left" and strength > 0.5 and cur_dir.x != 1:
			new_dir += Vector2i(-1, 0)
		if event == "right" and strength > 0.5 and cur_dir.x != -1:
			new_dir += Vector2i(1, 0)
		if event == "up" and strength > 0.5 and cur_dir.y != 1:
			new_dir += Vector2i(0, -1)
			new_dir.x = 0
		if event == "down" and strength > 0.5 and cur_dir.y != -1:
			new_dir += Vector2i(0, 1)
			new_dir.x = 0
		if new_dir.length() > 0:
			changed_dir = true
			cur_dir = new_dir

func _ready():
	score = 0
	score_changed.emit()
	#$canvas.size = max_size
	field_side = min(max_size.x, max_size.y)
	$bg.scale = Vector2.ONE * field_side
	$bg.position += (Vector2(max_size
	
	
	) - Vector2.ONE * field_side) / 2
	$sprites.position = $bg.position
	sync_snake_sprites()
	sync_food_sprites()

func process(_game_time: float, delta: float):
	since_last_mov += delta
	cur_mov_per_sec = mov_per_sec + (mov_per_sec if sprint else 0)
	if since_last_mov > (1.0 / float(cur_mov_per_sec)):
		move()
		check_dead()
		if not dead:
			check_eat()
			spawn_food()
		sync_snake_sprites()
		since_last_mov = 0
		if eating:
			mov_per_sec = max(mov_per_sec, floor(sqrt(food_eaten)))

func move():
	if not eating:
		parts.pop_front()
	parts.push_back(parts.back() + cur_dir)
	for i in range(parts.size()):
		parts[i].x = (parts[i].x + field_size) % field_size
		parts[i].y = (parts[i].y + field_size) % field_size
	changed_dir = false

func rot_from_dir(dir: Vector2i):
	if dir.x != 0:
		return PI * (1 - dir.x) / 2
	else:
		return PI / 2 * dir.y

func sync_snake_sprites():
	while parts.size() > sprites.size():
		var s = Sprite2D.new()
		s.modulate = player_color
		
		$sprites.add_child(s)
		sprites.push_back(s)
	var cell_sz = float(field_side) / float(field_size)
	for i in range(parts.size()):
		sprites[i].position = (Vector2(parts[i].x, parts[i].y) + Vector2.ONE * 0.5) * cell_sz
		sprites[i].scale = Vector2.ONE * cell_sz / 512
		sprites[i].rotation = 0
		if i == parts.size() - 1:
			sprites[i].texture = TEX_Hd if dead else TEX_He if eating else TEX_H
			sprites[i].rotation = rot_from_dir(cur_dir)
		elif i == 0:
			sprites[i].texture = TEX_T
			sprites[i].rotation = rot_from_dir(parts[1] - parts[0])
		else:
			var prvdir = parts[i - 1] - parts[i]
			prvdir = Vector2i(-prvdir.x/abs(prvdir.x) if abs(prvdir.x) > 1 else prvdir.x, -prvdir.y/abs(prvdir.y) if abs(prvdir.y) > 1 else prvdir.y)
			var nxtdir = parts[i + 1] - parts[i]
			nxtdir = Vector2i(-nxtdir.x/abs(nxtdir.x) if abs(nxtdir.x) > 1 else nxtdir.x, -nxtdir.y/abs(nxtdir.y) if abs(nxtdir.y) > 1 else nxtdir.y)
			if prvdir.y == nxtdir.y:
				sprites[i].texture = TEX_I
			elif prvdir.x == nxtdir.x: 
				sprites[i].texture = TEX_I
				sprites[i].rotation = PI / 2
			else:
				sprites[i].texture = TEX_L
				if prvdir.x > 0 or nxtdir.x > 0 :
					sprites[i].rotation = PI / 2 + (((nxtdir.y if prvdir.x > 0 else prvdir.y) - 1) / 2) * PI / 2
				else:
					sprites[i].rotation = -PI / 2 + (((nxtdir.y if prvdir.x < 0 else prvdir.y) + 1) / 2) * -PI / 2

func sync_food_sprites():
	var cell_sz = float(field_side) / float(field_size)
	while food.size() > food_sprites.size():
		var s = Sprite2D.new()
		s.scale = Vector2.ONE * cell_sz / 512
		$sprites.add_child(s)
		food_sprites.push_back(s)
	for i in range(food.size()):
		food_sprites[i].texture = FOOD_1 if (food[i][1] == 0) else FOOD_2 if (food[i][1] == 1) else FOOD_3
		food_sprites[i].position = (Vector2(food[i][0].x, food[i][0].y) + Vector2.ONE * 0.5) * cell_sz

func check_eat():
	var eaten = []
	eating = false
	for i in range(food.size()):
		if parts.back() == food[i][0]:
			score += 1
			food_eaten += 1
			score_changed.emit()
			eating = true
			eaten.push_back(i)
	if eaten.size() > 0:
		var new_food = []
		for i in range(food.size()):
			if eaten.find(i) == -1:
				new_food.push_back(food[i])
		food = new_food

func check_dead():
	for i in range(parts.size() - 1):
		if parts.back() == parts[i]:
			game_finished.emit()
			dead = true

func spawn_food():
	if food.size() == 0:
		var tilexy = Vector2i(randi_range(0, field_size - 1), randi_range(0, field_size - 1))
		while parts.find(tilexy) != -1:
			tilexy = Vector2i(randi_range(0, field_size - 1), randi_range(0, field_size - 1))
		food.push_back([tilexy, randi_range(0, 2)])
		sync_food_sprites()
