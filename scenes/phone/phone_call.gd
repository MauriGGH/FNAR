extends Control

## El teléfono de la oficina: la ventanita de la llamada, abajo del todo.
## Vive en la capa del HUD, así que se sigue viendo con las cámaras arriba.
## Sirve para dos cosas: el mensaje de la noche (subtítulos que salen poco a
## poco) y la llamada de Ureña (tres preguntas de opción múltiple contrarreloj).

signal ringing_started(seconds: float)
signal ring_tick()
signal call_missed()
signal call_answered()
signal call_ended()
## Una respuesta mala o sin contestar en la llamada de Ureña.
signal wrong_answer()

enum Mode { NONE, MESSAGE, QUESTIONS }

## Cada cuánto se repite el aviso de "[ring]".
const RING_TICK_TIME: float = 1.0
## Velocidad de los subtítulos, en letras por segundo.
const TYPE_SPEED: float = 26.0
## Lo que se queda cada línea ya escrita antes de pasar a la siguiente.
const LINE_PAUSE: float = 1.1

var is_ringing: bool = false
var is_open: bool = false
var mode: Mode = Mode.NONE

var _ring_left: float = 0.0
var _ring_tick_left: float = 0.0
var _fatal_if_missed: bool = false

# Mensaje de la noche.
var _lines: PackedStringArray = PackedStringArray()
var _line_index: int = 0
var _typed: float = 0.0
var _pause_left: float = 0.0

# Llamada de Ureña.
var _questions: Array[Dictionary] = []
var _question_index: int = -1
var _question_left: float = 0.0

@onready var subtitle_label: Label = $Panel/SubtitleLabel
@onready var caller_label: Label = $Panel/CallerLabel
@onready var timer_label: Label = $Panel/TimerLabel
@onready var hang_up_button: Button = $Panel/HangUpButton
@onready var options: VBoxContainer = $Panel/Options


func _ready() -> void:
	visible = false
	hang_up_button.pressed.connect(hang_up)
	for i: int in 3:
		var button: Button = Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(_on_option_pressed.bind(i))
		options.add_child(button)
	options.visible = false


# --- Timbre -------------------------------------------------------------------

## Empieza a sonar. fatal_if_missed mata al guardia si no contesta a tiempo.
func start_ringing(seconds: float, fatal_if_missed: bool) -> void:
	if is_ringing or is_open:
		return
	is_ringing = true
	_ring_left = seconds
	_ring_tick_left = 0.0
	_fatal_if_missed = fatal_if_missed
	ringing_started.emit(seconds)


## Lo llama el clic en la zona del teléfono.
func answer() -> void:
	if not is_ringing:
		return
	is_ringing = false
	is_open = true
	visible = true
	call_answered.emit()
	if mode == Mode.QUESTIONS:
		_next_question()
	else:
		_line_index = 0
		_typed = 0.0
		_pause_left = 0.0
		options.visible = false
		timer_label.visible = false


func hang_up() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	mode = Mode.NONE
	_questions.clear()
	_question_index = -1
	call_ended.emit()


# --- Las dos clases de llamada -----------------------------------------------

## El mensaje de la noche: suena, y si contestas salen los subtítulos.
func queue_message(lines: PackedStringArray, seconds: float) -> void:
	mode = Mode.MESSAGE
	_lines = lines
	caller_label.text = "LLAMADA ENTRANTE"
	start_ringing(seconds, false)


## La llamada de Ureña: si no contestas, te mata.
func queue_questions(questions: Array[Dictionary], seconds: float) -> void:
	mode = Mode.QUESTIONS
	_questions = questions
	caller_label.text = "UREÑA"
	start_ringing(seconds, true)


func _process(delta: float) -> void:
	if is_ringing:
		_process_ringing(delta)
		return
	if not is_open:
		return
	if mode == Mode.QUESTIONS:
		_process_question(delta)
	else:
		_process_message(delta)


func _process_ringing(delta: float) -> void:
	_ring_tick_left -= delta
	if _ring_tick_left <= 0.0:
		_ring_tick_left = RING_TICK_TIME
		ring_tick.emit()
	_ring_left -= delta
	if _ring_left > 0.0:
		return
	is_ringing = false
	call_missed.emit()


# --- Mensaje de la noche ------------------------------------------------------

## Los subtítulos salen letra por letra y la llamada se cuelga sola al final.
func _process_message(delta: float) -> void:
	if _line_index >= _lines.size():
		hang_up()
		return
	if _pause_left > 0.0:
		_pause_left -= delta
		if _pause_left <= 0.0:
			_line_index += 1
			_typed = 0.0
		return

	var line: String = _lines[_line_index]
	_typed = minf(_typed + TYPE_SPEED * delta, float(line.length()))
	subtitle_label.text = line.substr(0, int(_typed))
	if int(_typed) >= line.length():
		_pause_left = LINE_PAUSE


# --- Preguntas de Ureña -------------------------------------------------------

func _next_question() -> void:
	_question_index += 1
	if _question_index >= _questions.size():
		hang_up()
		return
	var question: Dictionary = _questions[_question_index]
	subtitle_label.text = str(question.get("text", ""))
	_question_left = UrenaQuestions.SECONDS_PER_QUESTION
	timer_label.visible = true
	options.visible = true
	var texts: Array = question.get("options", [])
	for i: int in options.get_child_count():
		var button: Button = options.get_child(i)
		button.visible = i < texts.size()
		if button.visible:
			button.text = "%d) %s" % [i + 1, texts[i]]


func _process_question(delta: float) -> void:
	_question_left -= delta
	timer_label.text = "%.1f s" % maxf(_question_left, 0.0)
	if _question_left > 0.0:
		return
	# Se acabó el tiempo: cuenta como mala.
	wrong_answer.emit()
	_next_question()


func _on_option_pressed(index: int) -> void:
	if not is_open or mode != Mode.QUESTIONS:
		return
	if _question_index < 0 or _question_index >= _questions.size():
		return
	if index != int(_questions[_question_index].get("correct", -1)):
		wrong_answer.emit()
	_next_question()
