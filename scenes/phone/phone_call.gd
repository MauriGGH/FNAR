extends Control

## El teléfono de la oficina: la ventanita de la llamada, abajo del todo.
## Vive en la capa del HUD, así que se sigue viendo con las cámaras arriba.
## Sirve para dos cosas: la llamada con la que empieza la noche, que es audio
## grabado (aquí solo vive el timbre; el audio y los subtítulos los lleva
## `call_subtitles.gd`), y la llamada de Ureña, que es una conversación:
## saluda, suelta tres insinuaciones con tres respuestas contrarreloj cada una,
## reacciona a lo que conteste el jugador y se despide.

signal ringing_started(seconds: float)
signal ring_tick()
signal call_missed()
## Le colgaron o no le contestaron: Ureña se ofende.
signal urena_snubbed()
## Lo que dice por el altavoz tras el tono de ocupado, para el aviso en pantalla.
signal snub_line(text: String)
signal call_answered()
signal call_ended()
## Lo que contestó el jugador a una insinuación de Ureña. El valor es un
## UrenaQuestions.Answer; sin contestar a tiempo cuenta como seguirle el juego.
signal answer_given(kind: int)
## Contestaron la llamada grabada de la noche: que empiecen el audio y los
## subtítulos. De eso se encarga la barra de subtítulos, no esta ventanita.
signal recording_started(night: int)
## Lo mismo, pero con la llamada rara de la noche (el Mencho o el juguete),
## que no es de ninguna noche en concreto.
signal mencho_started()

enum Mode { NONE, RECORDING, URENA, MENCHO }
## Por dónde va la llamada de Ureña.
enum Step { GREETING, LINE, REACTION, FAREWELL }

## Cada cuánto se repite el aviso de "[ring]".
const RING_TICK_TIME: float = 1.0
## Velocidad de los subtítulos, en letras por segundo.
const TYPE_SPEED: float = 26.0

var is_ringing: bool = false
var is_open: bool = false
var mode: Mode = Mode.NONE

var _ring_left: float = 0.0
var _ring_tick_left: float = 0.0
var _fatal_if_missed: bool = false

# Llamada de inicio de noche.
## Qué noche es la llamada grabada que está en marcha.
var _recording_night: int = 0
## La última línea que se mandó a la voz, para no repetirla cada cuadro.

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
## Cómo le fue en la llamada: la despedida depende de las dos.
var _played_along: bool = false
var _was_rude: bool = false
## Los índices de las insinuaciones que ya salieron esta noche.
var _used_lines: Array[int] = []
## El temporizador del altavoz, uno solo para toda la noche.
var _snub_timer: Timer = null

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

## Empieza a sonar. Ya no hay castigo mortal por no contestar: si era Ureña,
## se ofende y se cobra en el night.gd.
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
	call_answered.emit()
	if mode == Mode.RECORDING or mode == Mode.MENCHO:
		# Las grabadas no abren la ventanita: sus subtítulos van abajo al
		# centro y el juego sigue.
		is_open = false
		visible = false
		if mode == Mode.MENCHO:
			mencho_started.emit()
		else:
			recording_started.emit(_recording_night)
		return
	is_open = true
	visible = true
	if mode == Mode.URENA:
		_start_urena()


func hang_up() -> void:
	if not is_open:
		return
	# Colgarle a Ureña antes de que se despida cuenta como desaire: suena el
	# tono de ocupado y, al soltarlo, habla por el altavoz.
	if mode == Mode.URENA and _step != Step.FAREWELL:
		urena_snubbed.emit()
		AudioManager.play(Sounds.BUSY_TONE)
		_speak_after_busy()
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

## La llamada grabada de la noche: el teléfono suena y, al contestar, arranca
## el audio con sus subtítulos. La ventanita del teléfono no se abre: los
## subtítulos van abajo al centro y el juego sigue.
func queue_recording(night: int, seconds: float) -> void:
	_recording_night = night
	mode = Mode.RECORDING
	start_ringing(seconds, false)


## La llamada rara de la noche: igual que la grabada, pero sin noche. El
## teléfono suena y, al contestar, se oye y ya.
func queue_mencho(seconds: float) -> void:
	mode = Mode.MENCHO
	start_ringing(seconds, false)


## La barra de subtítulos avisó de que la llamada acabó o se silenció.
func end_recording() -> void:
	if mode != Mode.RECORDING and mode != Mode.MENCHO:
		return
	mode = Mode.NONE
	_recording_night = 0
	call_ended.emit()


## Los índices usados esta noche, para que el night.gd no repita ninguna.
func used_urena_lines() -> Array[int]:
	return _used_lines


## Se borran al empezar una noche nueva.
func reset_urena_lines() -> void:
	_used_lines.clear()


## La llamada de Ureña. Si no contesta, Ureña se ofende.
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


func _process_ringing(delta: float) -> void:
	_ring_tick_left -= delta
	if _ring_tick_left <= 0.0:
		_ring_tick_left = RING_TICK_TIME
		ring_tick.emit()
	_ring_left -= delta
	if _ring_left > 0.0:
		return
	is_ringing = false
	if mode == Mode.URENA:
		urena_snubbed.emit()
		AudioManager.play(Sounds.BUSY_TONE)
		_speak_after_busy()
	call_missed.emit()


# --- Mensaje de la noche ------------------------------------------------------

## Los subtítulos salen letra por letra y la llamada se cuelga sola al final.
## El tono de ocupado primero y, en cuanto termina, Ureña hablando por el
## altavoz. No hace falta contestar: se oye en la oficina.
## El temporizador es uno solo y se reusa: si le cuelgas dos veces en la
## misma noche, la segunda reinicia la cuenta en vez de acumularse.
func _speak_after_busy() -> void:
	if _snub_timer == null:
		_snub_timer = Timer.new()
		_snub_timer.one_shot = true
		add_child(_snub_timer)
		_snub_timer.timeout.connect(_on_snub_timeout)
	_snub_timer.start(AudioManager.length(Sounds.BUSY_TONE))


func _on_snub_timeout() -> void:
	_play_voice(Sounds.URENA_FAREWELL_SNUBBED)
	snub_line.emit(UrenaQuestions.FAREWELL_SNUBBED)


# --- La voz de la llamada -----------------------------------------------------

## "Silenciar llamada": corta la voz y cuelga, como taparle la bocina.
func _on_mute_pressed() -> void:
	hang_up()


## Suelta la grabación de una línea de Ureña. **Nada de síntesis de voz**: si
## esa grabación no está, se queda el subtítulo y ya.
##
## Las voces de la llamada van como secuencia, así que una línea nueva **calla
## la anterior** en vez de encimarse con ella. En una conversación interrumpir
## se entiende; esperar turno dejaría la voz corriendo detrás del texto.
func _play_voice(voice_id: String) -> void:
	if voice_id.is_empty():
		return
	AudioManager.begin_sequence(Sounds.SEQ_VOICE)
	AudioManager.play_in_sequence(Sounds.SEQ_VOICE, voice_id)


func _stop_voice() -> void:
	AudioManager.begin_sequence(Sounds.SEQ_VOICE)


# --- Llamada de Ureña ---------------------------------------------------------

## Arranca saludando con el nombre del guardia y las tareas que lleva.
func _start_urena() -> void:
	_line_urena = -1
	_played_along = false
	_was_rude = false
	# Lo que se lee lleva el nombre; lo que se oye, no.
	var done: int = GameManager.completed_task_count()
	_say(UrenaQuestions.greeting(GameManager.player_name, done),
		UrenaQuestions.GREETING_HOLD, Sounds.URENA_GREETING)
	_step = Step.GREETING


## Pone a Ureña a decir algo: se escribe poco a poco y después se queda hold
## segundos en pantalla. Mientras habla no hay opciones ni reloj.
## `voice_id` es la grabación que acompaña al texto. Van por separado a
## propósito: el saludo se **escribe** con el nombre del jugador y se **oye**
## sin él, porque una grabación no puede decir cómo te llamas.
func _say(text: String, hold: float, voice_id: String = "") -> void:
	_speech = text
	_speech_typed = 0.0
	_speech_hold = hold
	subtitle_label.text = ""
	_play_voice(voice_id)
	options.visible = false
	timer_label.visible = false


## La siguiente insinuación, con sus tres respuestas ya barajadas.
func _next_line() -> void:
	_line_urena += 1
	if _line_urena >= _lines_urena.size():
		_say(UrenaQuestions.farewell(_played_along, _was_rude),
			UrenaQuestions.FAREWELL_HOLD,
			UrenaQuestions.farewell_voice(_played_along, _was_rude))
		_step = Step.FAREWELL
		return
	var line: Dictionary = _lines_urena[_line_urena]
	subtitle_label.text = str(line.get("text", ""))
	# Las insinuaciones también se oyen, no solo se leen.
	_play_voice(str(line.get("voz", "")))
	if line.has("index"):
		var index: int = int(line["index"])
		if not index in _used_lines:
			_used_lines.append(index)
	_answer_left = UrenaQuestions.SECONDS_PER_LINE
	timer_label.visible = true
	options.visible = true
	var answers: Array = line.get("answers", [])
	for i: int in options.get_child_count():
		var button: Button = options.get_child(i)
		button.visible = i < answers.size()
		if button.visible:
			button.text = "[%d] %s" % [i + 1, answers[i].get("text", "")]
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


## Las respuestas se pueden elegir con las teclas 1, 2 y 3, además del clic,
## para no tener que soltar el mouse de las cámaras.
func _input(event: InputEvent) -> void:
	if not is_open or mode != Mode.URENA or _step != Step.LINE:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index: int = [KEY_1, KEY_2, KEY_3].find(key.keycode)
	if index < 0:
		return
	_on_option_pressed(index)
	get_viewport().set_input_as_handled()


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
	elif kind == UrenaQuestions.Answer.RUDE:
		_was_rude = true
	answer_given.emit(kind)
	_say(UrenaQuestions.reaction(kind), UrenaQuestions.REACTION_HOLD,
		UrenaQuestions.reaction_voice(kind))
	_step = Step.REACTION
