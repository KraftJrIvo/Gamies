class_name LetterInput
extends VBoxContainer

@export var alphabet = " ABCDEFGHIJKLMNOPQRSTUVWXYZ"

var cur_idx = 0

func focus():
	$letter["theme_override_styles/normal"] = ThemeDB.fallback_stylebox.duplicate()

func unfocus():
	$letter["theme_override_styles/normal"] = null

func get_letter():
	return alphabet[cur_idx]

func set_letter(letter: String):
	cur_idx = alphabet.find(letter)

func go(off: int):
	cur_idx = (alphabet.length() + cur_idx + off) % alphabet.length()
	$letter.text = alphabet[cur_idx]
	$up.button_pressed = true
