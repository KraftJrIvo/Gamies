class_name NameInput
extends HBoxContainer

signal done

const LETTER = preload("res://letter_input.tscn")

@export var length = 5
@export var alphabet = " ABCDEFGHIJKLMNOPQRSTUVWXYZ"

var keyboard = true
var controller_idx = 0

var is_done = false
var focused = false
var focus_idx = 0

func _input(event):
	if focused:
		var off = -1 if event.is_action_pressed("left_" + _get_action_suffix()) else 1 if event.is_action_pressed("right_" + _get_action_suffix()) else 0
		if off != 0:
			focus_idx = ((length + 1) + focus_idx + off) % (length + 1)
			focus()
		else:
			if focus_idx == length:
				if event.is_action_pressed("accept_" + _get_action_suffix()):
					var ok = false
					for i in range(length):
						if get_children()[i].get_node("letter").text != " ":
							ok = true
							break
					if ok:
						is_done = true
						done.emit()
						unfocus()
			else:
				off = -1 if event.is_action_pressed("up_" + _get_action_suffix()) else 1 if event.is_action_pressed("down_" + _get_action_suffix()) else 0
				get_children()[focus_idx].go(off)

func _ready():
	for i in range(length):
		var ch = LETTER.instantiate()
		ch.alphabet = alphabet
		ch.go(0)
		add_child(ch)
	var b = Button.new()
	b.text = "ok"
	add_child(b)
		
func _get_action_suffix():
	if keyboard:
		return "kb"
	return str(controller_idx)

func focus():
	focused = true
	var chs = get_children()
	for ch in chs:
		if ch is LetterInput:
			ch.unfocus()
		else:
			ch["theme_override_styles/normal"] = null
	if chs.size() > focus_idx:
		if chs[focus_idx] is LetterInput:
			chs[focus_idx].focus()
		else:
			chs[focus_idx]["theme_override_styles/normal"] = ThemeDB.fallback_stylebox.duplicate()

func unfocus():
	focused = false
	for ch in get_children():
		if ch is LetterInput:
			ch.unfocus()
		else:
			ch["theme_override_styles/normal"] = null
			
func get_name_():
	var nom = ""
	for i in range(length):
		nom += get_children()[i].get_letter()
	while nom.length() > 0 && nom[0] == ' ':
		nom = nom.trim_prefix(' ')
	while nom.length() > 0 && nom[nom.length() - 1] == ' ':
		nom = nom.trim_suffix(' ')
	return nom
