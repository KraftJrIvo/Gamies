class_name TetrisGame
extends PanelContainer

var player_color: Color
var max_size: Vector2i
var keyboard = true
var controller_idx = 0
var score = 0

signal game_finished
signal score_changed

var COLORS = [Color.hex(0xFF522AFF), Color.hex(0x23B373FF), Color.hex(0x868CF8FF), Color.hex(0xFECE42FF), Color.hex(0xFE6CA2FF), Color.hex(0xFFB2C9FF), Color.hex(0xFAF5DBFF)]
const TETROMINOS = [
	[0,0,0,0,1,1,0,0,0,0,0,0,0,0,1,1,0,0,0,0], 
	[0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,1,1,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0],
	[0,0,0,1,1,0,0,0,0,0,0,0,0,0,1,1,0,0,0,0],
	[0,0,0,0,0,1,1,0,0,0,0,0,0,0,1,1,0,0,0,0],
	[0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0],
	[0,0,0,1,1,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0], 
]
const FACES = [preload("res://games/tetris/a1.png"), preload("res://games/tetris/a2.png"), preload("res://games/tetris/a3.png"), preload("res://games/tetris/a4.png"), preload("res://games/tetris/a5.png")]
const SCORING = [0, 40, 100, 300, 1200]

var field_height_real
var field_size = Vector2i(10, 20)
var mov_per_sec = 2
var level = 1
var cur_mov_per_sec = mov_per_sec
var since_last_mov = 0
var since_last_mov_side = 0
var parts_static = []
var parts_dynamic = []
var sprites = []
var need_to_spawn = true
var fallfast = false
var mov_left = false
var mov_right = false
var drop_reloaded = true
var just_dropped = false
var flip_reloaded = true
var since_last_flip = 0
var fleep_cd = 0.1
var jumping_sprites = []
var lines_cleared_now = 0
var lines_cleared_level = 0

func input(event: String, strength: float):
	if event == "down":
		fallfast = strength > 0
	if event == "right":
		mov_right = strength > 0.5
	if event == "left":
		mov_left = strength > 0.5
	if event == "accept":
		if drop_reloaded:
			drop()
			just_dropped = true
			drop_reloaded = false
		elif strength == 0:
			drop_reloaded = true
	if event == "up" or event == "action":
		if flip_reloaded and since_last_flip > fleep_cd and strength > 0.5:
			flip()
			since_last_flip = 0
			flip_reloaded = false
		elif strength == 0:
			flip_reloaded = true

func _ready():
	score = 0
	score_changed.emit()
	field_height_real = max_size.y
	$bg.scale = Vector2.ONE * field_height_real
	$bg.position.x += (max_size.x - field_height_real / 2) / 2
	#$bg.color = player_color
	$sprites.position = $bg.position
	for i in range(field_size.x):
		for j in range(field_size.y):
			parts_static.push_back(0)
			parts_dynamic.push_back(0)
			sprites.push_back(null)

func process(_game_time: float, delta: float):
	if lines_cleared_level > level * 10:
		level += 1
		lines_cleared_level = 0
	mov_per_sec = 1 + level
	since_last_mov += delta
	since_last_mov_side += delta
	since_last_flip += delta
	cur_mov_per_sec = mov_per_sec + ((mov_per_sec * 3) if fallfast else 0)
	if since_last_mov > (1.0 / float(cur_mov_per_sec)) or just_dropped:
		fall()
		check_lines()
		scoring()
		lines_cleared_now = 0
		since_last_mov = 0
		just_dropped = false
	var side_off = (-1 if mov_left else 0) + (1 if mov_right else 0)
	if side_off != 0 and since_last_mov_side > (1.0 / float(cur_mov_per_sec * 4)):
		move_dir(Vector2i(side_off, 0))
		since_last_mov_side = 0
	if need_to_spawn:
		spawn()
	jump_sync()

func scoring():
	score += level * SCORING[clamp(lines_cleared_now + (1 if (just_dropped and lines_cleared_now > 0) else 0), 0, SCORING.size())]
	score_changed.emit()

func move_dir(dir: Vector2i):
	var ok = true
	for i in range(field_size.x - 1 * abs(dir.x)):
		for j in range(field_size.y - 1 * abs(dir.y)):
			var pos = (j if (dir.y < 0) else (field_size.y - 1 - j)) * field_size.x + (i if (dir.x < 0) else (field_size.x - 1 - i))
			if dir.y > 0:
				if (parts_dynamic[pos] > 0 and j == 0) or (parts_static[pos] > 0 and parts_dynamic[pos - field_size.x] > 0):
					ok = false
					break
			if dir.x > 0:
				if (parts_dynamic[pos] > 0 and i == 0) or (parts_static[pos] > 0 and parts_dynamic[pos - 1] > 0):
					ok = false
					break
			if dir.x < 0:
				if (parts_dynamic[pos] > 0 and i == 0) or (parts_static[pos] > 0 and parts_dynamic[pos + 1] > 0):
					ok = false
					break
		if not ok:
			break
	if ok:
		var cell_sz = float(field_height_real) / float(field_size.y)
		for i in range(field_size.x - 1 * abs(dir.x)):
			for j in range(field_size.y - 1 * abs(dir.y)):
				var pos = (j if (dir.y < 0) else (field_size.y - 1 - j)) * field_size.x + (i if (dir.x < 0) else (field_size.x - 1 - i))
				var pos2 = pos - (field_size.x if dir.y > 0 else (1 if dir.x > 0 else -1))
				if parts_dynamic[pos] == 0 and parts_dynamic[pos2] > 0:
					parts_dynamic[pos] = parts_dynamic[pos2]
					parts_dynamic[pos2] = 0
					sprites[pos] = sprites[pos2]
					sprites[pos2] = null
					if sprites[pos]:
						sprites[pos].position += dir * cell_sz
	return ok

func deposit_blocks():
	for i in range(field_size.x):
		for j in range(field_size.y):
			var pos = j * field_size.x + i
			if parts_dynamic[pos] > 0:
				parts_static[pos] = parts_dynamic[pos]
				parts_dynamic[pos] = 0
	
func fall():
	if not move_dir(Vector2i(0, 1)):
		deposit_blocks()
		need_to_spawn = true

func spawn():
	var cell_sz = float(field_height_real) / float(field_size.y)
	var idx = randi_range(0, TETROMINOS.size() - 1)
	var tetromino = TETROMINOS[idx]
	for i in range(10):
		for j in range(2):
			var pos = j * 10 + i
			if tetromino[pos] != 0 and parts_static[pos] != 0:
				game_over()
				return
			parts_dynamic[pos] = tetromino[pos] * (idx + 1)
			if tetromino[pos] > 0:
				var s = Sprite2D.new()
				s.scale = Vector2.ONE * cell_sz / 512
				s.texture = FACES.pick_random()
				s.modulate = COLORS[idx]
				s.position = (Vector2(i, j) + Vector2.ONE * 0.5) * cell_sz
				$sprites.add_child(s)
				sprites[pos] = s
	need_to_spawn = false

func drop():
	while move_dir(Vector2i(0, 1)):
		pass

func check_lines():
	var again = false
	for j in range(field_size.y):
		var y = field_size.y - j - 1
		var ok = true
		for i in range(field_size.x):
			var pos = y * field_size.x + i
			if parts_static[pos] == 0:
				ok = false
				break
		if ok:
			line_jump(y)
			lines_cleared_now += 1
			lines_cleared_level += 1
			again = true
	if again:
		check_lines()

func line_jump(j: int):
	for i in range(field_size.x):
		var pos = j * field_size.x + i
		parts_static[pos] = -1
		if sprites[pos]:
			jump(pos)
	var cell_sz = float(field_height_real) / float(field_size.y)
	for jj in range(field_size.y - 1):
		var y = field_size.y - 1 - jj
		for i in range(field_size.x):
			var pos = y * field_size.x + i
			var posT = (y - 1) * field_size.x + i
			if parts_static[pos] == -1:
				parts_static[pos] = parts_static[posT]
				parts_static[posT] = -1
				sprites[pos] = sprites[posT]
				sprites[posT] = null
	for jj in range(field_size.y):
		for i in range(field_size.x):
			var pos = jj * field_size.x + i
			if parts_static[pos] == -1:
				parts_static[pos] = 0
			if sprites[pos]:
				if parts_static[pos] == 0:
					sprites[pos] = null
				else:
					sprites[pos].position = (Vector2(i, jj) + Vector2.ONE * 0.5) * cell_sz

func flip():
	var minP = Vector2i.ONE * 1e9
	var maxP = Vector2i.ZERO
	for i in range(field_size.x):
		for j in range(field_size.y):
			var pos = j * 10 + i
			if parts_dynamic[pos] != 0:
				minP = Vector2i(min(i, minP.x), min(j, minP.y))
				maxP = Vector2i(max(i + 1, maxP.x), max(j + 1, maxP.y))
	var center = minP + (maxP - minP) / 2
	var w = maxP.y - minP.y
	var h = maxP.x - minP.x
	if w > 0:
		var c_off = Vector2i(-1 if w > h + 1 else 1 if h > w + 1 else 0, 1 if w > h + 1 else -1 if h > w + 1 else 0)
		var off = Vector2i(clamp(minP.x + c_off.x, 0, field_size.x - w), clamp(minP.y + c_off.y, 0, field_size.y - h))
		var cell_sz = float(field_height_real) / float(field_size.y)

		var ok = false
		var sub_off = Vector2i.ZERO
		var sub_offs = [0, -1, 1]
		for si in range(3):
			for sj in range(3):
				var this_ok = true
				for i in range(w):
					for j in range(h):
						var x = off.x + i + sub_offs[si]
						var y = off.y + j + sub_offs[sj]
						if x < 0 or y < 0 or x >= field_size.x or y >= field_size.y or parts_static[y * field_size.x + x] > 0:
							this_ok = false
							break
					if not this_ok:
						break
				if this_ok:
					ok = true
					sub_off = Vector2i(sub_offs[si], sub_offs[sj])
					break
			if ok:
				break
		off += sub_off
		if ok:
			var parts_dynamic_copy = parts_dynamic.duplicate()
			var sprites_copy = sprites.duplicate()
			parts_dynamic_copy.fill(0)
			for i in range(w):
				for j in range(h):
					var pos = (off.y + j) * field_size.x + off.x + i
					var posPrev = (minP.y + (w - i - 1)) * field_size.x + minP.x + j
					parts_dynamic_copy[pos] = parts_dynamic[posPrev]
					if parts_dynamic[posPrev] > 0:
						sprites_copy[pos] = sprites[posPrev]
						if sprites_copy[pos]:
							sprites_copy[pos].position = (Vector2(off.x + i, off.y + j) + Vector2.ONE * 0.5) * cell_sz
			parts_dynamic = parts_dynamic_copy
			sprites = sprites_copy

func jump(pos: int):
	jumping_sprites.push_back([sprites[pos], randf() * 10 - 5, -randf() * 10])
	sprites[pos] = null

func jump_sync():
	var to_remove = []
	for i in range(jumping_sprites.size()):
		var s = jumping_sprites[i][0]
		var vx = jumping_sprites[i][1]
		var vy = jumping_sprites[i][2]
		s.position += Vector2(vx, vy)
		jumping_sprites[i][2] += 0.1
		if s.position.length() > 10000:
			to_remove.push_back(i)
	if to_remove.size() > 0:
		var new_js = []
		for i in range(jumping_sprites.size()):
			if to_remove.find(i) == -1:
				new_js.push_back(jumping_sprites[i])
			else:
				jumping_sprites[i][0].queue_free()
		jumping_sprites = new_js

func game_over():
	game_finished.emit()
