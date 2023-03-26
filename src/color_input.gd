class_name ColorInput
extends VBoxContainer

var cur_idx = 0

func _ready():
	$color.modulate = Global.colors[0]

func focus():
	$color["theme_override_styles/normal"] = ThemeDB.fallback_stylebox.duplicate()

func unfocus():
	$color["theme_override_styles/normal"] = null

func go(off: int):
	cur_idx = (Global.colors.size() + cur_idx + off) % Global.colors.size()
	$color.modulate = Global.colors[cur_idx]

func get_color_idx():
	return cur_idx

func set_color_idx(idx: int):
	cur_idx = idx % Global.colors.size()
