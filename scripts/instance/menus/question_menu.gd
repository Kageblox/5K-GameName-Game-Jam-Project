class_name QuestionMenu
extends MenuInstance

@export var question_label : Label
@export var answer_button: CustomLabelButton

func open(_params: Array[Variant] = []) -> void:
	question_label.text = _params[0]
	var answers = _params[1] as Dictionary[String, Callable]
	var answers_container = answer_button.get_parent()
	var answer_buttons : Array[CustomLabelButton] = [answer_button]
	
	for i in range(answers.size() - 1):
		var new_answer_button = answer_button.duplicate()
		answers_container.add_child(new_answer_button)
		answer_buttons.append(new_answer_button)
	
	for i in range(answer_buttons.size()):
		answer_buttons[i].text = answers.keys()[i]
		answer_buttons[i].pressed.connect(answers.values()[i])
		answer_buttons[i].pressed.connect(close)

	super()
