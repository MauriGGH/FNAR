extends Control

## El teléfono de la oficina: la ventanita de la llamada, abajo del todo.
## Vive en la capa del HUD, así que se sigue viendo con las cámaras arriba.
## Sirve para dos cosas: la llamada con la que empieza la noche (subtítulos
## que salen poco a poco, con voz, y se pueden silenciar) y la llamada de
## Ureña, que es una conversación: saluda, suelta tres insinuaciones con tres
## respuestas contrarreloj cada una, reacciona a lo que conteste el jugador y
## se despide.

signal ringing_started(seconds: float)
signal ring_tick()
signal call_missed()
signal call_answered()
signal call_ended()
## Lo que contestó el jugador a una insinuación de Ureña. El valor es un
## UrenaQuestions.Answer; sin contestar a tiempo cuenta como seguirle el juego.
signal answer_given(kind: int)

enum Mode { NONE, MESSAGE, URENA }
## Por dónde va la llamada de Ureña.
enum Step { GREETING, LINE, REACTION, FAREWELL }

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

# Llamada de inicio de noche.
var _lines: PackedStringArray = PackedStringArray()
## La última línea que se mandó a la voz, para no repetirla cada cuadro.
var _spoken_line: int = -1
var _line_index: int = 0
var _typed: float = 0.0
var _pause_left: float = 0.0

# Llamada de Ureña.
var _lines_urena: Array[Dictionary] = []
var _line_urena: int = -1
var _answer_left: float = 0.0
var _step: Step = Step.GREETING
## Lo que Ureña está diciendo fuera de las insinuaciones (saludo, reacción,
## despedida): se escribe poco a poco y después se queda un momento.
var _speech: String = ""
var _speech_typed: float = 0.0
var _speech_hold: float = 0.0
## Si le siguió el juego aunque sea una vez, se despide dejando su foto.
var _played_along: bool = false

@onready var subtitle_label: Label = $Panel/SubtitleLabel
@onready var caller_label: Label = $Panel/CallerLabel
@onready var timer_label: Label = $Panel/TimerLabel
@onready var hang_up_button: Button = $Panel/HangUpButton
@onready var mute_button: Button = $Panel/MuteButton
@onready var options: VBoxContainer = $Panel/Options


func _ready() -> void:
	visible = false
	hang_up_button.pressed.connect(hang_up)
	mute_button.pressed.connect(_on_mute_pressed)
	mute_button.visible = false
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
	if mode == Mode.URENA:
		_start_urena()
	else:
		_line_index = 0
		_typed = 0.0
		_pause_left = 0.0
		_spoken_line = -1
		options.visible = false
		timer_label.visible = false
		mute_button.visible = true


func hang_up() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	mode = Mode.NONE
	mute_button.visible = false
	_stop_voice()
	_lines_urena.clear()
	_line_urena = -1
	options.visible = false
	timer_label.visible = false
	call_ended.emit()


# --- Las dos clases de llamada -----------------------------------------------

## El mensaje de la noche: suena, y si contestas salen los subtítulos.
func queue_message(lines: PackedStringArray, seconds: float) -> void:
	if lines.is_empty():
		return  # Esa noche no hay guion: el teléfono no suena.
	mode = Mode.MESSAGE
	_lines = lines
	caller_label.text = "LLAMADA ENTRANTE"
	start_ringing(seconds, false)


## La llamada de Ureña: si no contestas, te mata.
func queue_urena_call(lines: Array[Dictionary], seconds: float) -> void:
	mode = Mode.URENA
	_lines_urena = lines
	caller_label.text = "UREÑA"
	start_ringing(seconds, true)


func _process(delta: float) -> void:
	if is_ringing:
		_process_ringing(delta)
		return
	if not is_open:
		return
	if mode == Mode.URENA:
		_process_urena(delta)
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
	# La voz arranca con la línea, no letra por letra.
	if _spoken_line != _line_index:
		_spoken_line = _line_index
		_speak(line)
	_typed = minf(_typed + TYPE_SPEED * delta, float(line.length()))
	subtitle_label.text = line.substr(0, int(_typed))
	if int(_typed) >= line.length():
		_pause_left = LINE_PAUSE


# --- La voz de la llamada -----------------------------------------------------

## "Silenciar llamada": corta la voz y cuelga, como taparle la bocina.
func _on_mute_pressed() -> void:
	hang_up()


## Lee una línea con la síntesis de voz de Godot, si el sistema la tiene.
func _speak(line: String) -> void:
	var voice: String = _spanish_voice()
	if voice.is_empty():
		return
	DisplayServer.tts_speak(line, voice, NightCalls.TTS_VOLUME,
		NightCalls.TTS_PITCH, NightCalls.TTS_RATE)


func _stop_voice() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()


func _spanish_voice() -> String:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return ""
	var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(NightCalls.TTS_LANGUAGE)
	return voices[0] if not voices.is_empty() else ""


# --- Llamada de Ureña ---------------------------------------------------------

## Arranca saludando con el nombre del guardia y las tareas que lleva.
func _start_urena() -> void:
	_line_urena = -1
	_played_along = false
	_say(UrenaQuestions.greeting(GameManager.player_name, GameManager.completed_task_count()),
		UrenaQuestions.GREETING_HOLD)
	_step = Step.GREETING


## Pone a Ureña a decir algo: se escribe poco a poco y después se queda hold
## segundos en pantalla. Mientras habla no hay opciones ni reloj.
func _say(text: String, hold: float) -> void:
	_speech = text
	_speech_typed = 0.0
	_speech_hold = hold
	subtitle_label.text = ""
	options.visible = false
	timer_label.visible = false


## La siguiente insinuación, con sus tres respuestas ya barajadas.
func _next_line() -> void:
	_line_urena += 1
	if _line_urena >= _lines_urena.size():
		_say(UrenaQuestions.farewell(_played_along), UrenaQuestions.FAREWELL_HOLD)
		_step = Step.FAREWELL
		return
	var line: Dictionary = _lines_urena[_line_urena]
	subtitle_label.text = str(line.get("text", ""))
	_answer_left = UrenaQuestions.SECONDS_PER_LINE
	timer_label.visible = true
	options.visible = true
	var answers: Array = line.get("answers", [])
	for i: int in options.get_child_count():
		var button: Button = options.get_child(i)
		button.visible = i < answers.size()
		if button.visible:
			button.text = "%d) %s" % [i + 1, answers[i].get("text", "")]
	_step = Step.LINE


func _process_urena(delta: float) -> void:
	if _step == Step.LINE:
		_process_answer_time(delta)
		return
	# Saludo, reacción y despedida: se escriben y se quedan un momento.
	_speech_typed = minf(_speech_typed + TYPE_SPEED * delta, float(_speech.length()))
	subtitle_label.text = _speech.substr(0, int(_speech_typed))
	if int(_speech_typed) < _speech.length():
		return
	_speech_hold -= delta
	if _speech_hold > 0.0:
		return
	if _step == Step.FAREWELL:
		hang_up()
	else:
		_next_line()


func _process_answer_time(delta: float) -> void:
	_answer_left -= delta
	timer_label.text = "%.1f s" % maxf(_answer_left, 0.0)
	if _answer_left > 0.0:
		return
	# Quedarse callado cuenta como seguirle el juego.
	_resolve_answer(UrenaQuestions.Answer.PLAYS_ALONG)


func _on_option_pressed(index: int) -> void:
	if not is_open or mode != Mode.URENA or _step != Step.LINE:
		return
	if _line_urena < 0 or _line_urena >= _lines_urena.size():
		return
	var answers: Array = _lines_urena[_line_urena].get("answers", [])
	if index >= answers.size():
		return
	_resolve_answer(int(answers[index].get("kind", UrenaQuestions.Answer.DODGE)))


## Avisa qué clase de respuesta fue y pasa a la reacción de Ureña.
func _resolve_answer(kind: int) -> void:
	if kind == UrenaQuestions.Answer.PLAYS_ALONG:
		_played_along = true
	answer_given.emit(kind)
	_say(UrenaQuestions.reaction(kind), UrenaQuestions.REACTION_HOLD)
	_step = Step.REACTION
