class_name Rochis
extends Animatronic

## Rochis (rol Bonnie). Se levanta de la silla del cubículo 2 (CAM 3) en tres
## etapas: sentado, medio levantado y de pie. Mientras se está levantando hay
## que reproducirle el audio "es impresionante" desde la CAM 3 para bajarlo una
## etapa; reproducirlo cuando ya está sentado lo molesta y hace que su
## siguiente oportunidad de avanzar no falle. Si llega a estar de pie y se le
## deja pasar otra oportunidad, cruza la recepción, se asoma al marco lateral
## de la oficina, dice el nombre del guardia y es game over.

enum Stage { SITTING, HALF, STANDING }
enum State { CUBICLE, COMING, INSIDE }

const ROOM: String = "cubiculo_2"
const RECEPTION: String = "recepcion"

## Cada cuánto tira el dado para avanzar de etapa.
const MOVE_INTERVAL: float = 7.0

# Estados de la CAM 3. El sistema de cámaras busca cam03_<estado>.png.
const STATE_SITTING: String = "sentado"
const STATE_HALF: String = "medio"
const STATE_STANDING: String = "de_pie"
const STATE_EMPTY: String = "vacia"

## Lo que tarda en cruzar la recepción y asomarse al marco de la oficina.
const COMING_TIME: float = 3.0
## Lo que se queda a la vista diciendo el nombre antes del game over. En 0 el
## game over sería instantáneo y no daría tiempo de verlo.
const APPEAR_TIME: float = 1.2
## Lo que tarda el botón de la CAM 3 en poder volver a usarse.
const AUDIO_COOLDOWN: float = 2.0

const GAME_OVER_CAUSE: String = "Rochis"
const AUDIO_NOTICE: String = "[es impresionante]"
const STEPS_NOTICE: String = "[pasos en la recepción]"
const NAME_NOTICE_FORMAT: String = "Rochis: %s…"
const SIDE_PRESENCE: String = "[Rochis en el marco]"
const NOTICE_TIME: float = 2.0

## Zonas donde se asoma: el lado de los cubículos en la vista central y el
## marco sin puerta en la derecha.
const SIDE_ZONES: Array[String] = ["cubicles_side", "doorway"]

# Voz de la síntesis de Godot: en español y grave (1.0 es el tono normal).
const TTS_LANGUAGE: String = "es"
const TTS_PITCH: float = 0.6
const TTS_RATE: float = 0.85
const TTS_VOLUME: int = 60

var stage: int = Stage.SITTING
## Lo que le falta al botón de la CAM 3 para poder usarse otra vez.
var cooldown_left: float = 0.0

var _state: int = State.CUBICLE
var _state_elapsed: float = 0.0
## El audio lo molestó estando sentado: la próxima oportunidad no falla.
var _annoyed: bool = false


## Nombre corto para los archivos de imagen: cam07_rochis.png y demás.
func image_slug() -> String:
	return "rochis"


func game_over_cause() -> String:
	return GAME_OVER_CAUSE


func ai_key() -> String:
	return Nights.ROCHIS


func start() -> void:
	route = PackedStringArray([ROOM, RECEPTION])
	ai_level = night_ai_level()
	move_interval = MOVE_INTERVAL
	super()
	stage = Stage.SITTING
	_state = State.CUBICLE
	_state_elapsed = 0.0
	_annoyed = false
	cooldown_left = 0.0


func _process(delta: float) -> void:
	if not is_active:
		return
	if cooldown_left > 0.0:
		cooldown_left = maxf(cooldown_left - delta, 0.0)
	if _state == State.CUBICLE:
		super(delta)  # El dado de la clase base.
		return
	_state_elapsed += delta
	if _state == State.COMING and _state_elapsed >= COMING_TIME:
		_appear()
	elif _state == State.INSIDE and _state_elapsed >= APPEAR_TIME:
		_catch_player()


## Una vez que salió del cubículo ya no hay dado que valga.
func can_move() -> bool:
	return _state == State.CUBICLE


## El dado de siempre, salvo que el audio lo haya molestado: en ese caso su
## siguiente oportunidad no falla.
func try_move() -> bool:
	if not can_move():
		return false
	if _annoyed:
		_annoyed = false
		advance()
		return true
	return super()


## Una etapa más; estando de pie, lo que sigue es entrar.
func advance() -> void:
	if stage < Stage.STANDING:
		_set_stage(stage + 1)
		return
	_start_coming()


# --- El audio de la CAM 3 -----------------------------------------------------

## El botón "REPRODUCIR AUDIO". Devuelve false si todavía está en espera o si
## Rochis ya salió del cubículo (ahí ya no sirve de nada).
func play_audio() -> bool:
	if not is_active or cooldown_left > 0.0 or _state != State.CUBICLE:
		return false
	cooldown_left = AUDIO_COOLDOWN
	made_noise.emit(AUDIO_NOTICE, NOTICE_TIME)
	if stage > Stage.SITTING:
		_set_stage(stage - 1)
	else:
		# Ya estaba sentado: el audio lo molesta y acelera su avance.
		_annoyed = true
	return true


## De 0 a 1: qué tan listo está el botón para volver a usarse.
func audio_ready() -> float:
	if AUDIO_COOLDOWN <= 0.0:
		return 1.0
	return clampf(1.0 - cooldown_left / AUDIO_COOLDOWN, 0.0, 1.0)


## true mientras tenga sentido enseñar el botón en la CAM 3.
func accepts_audio() -> bool:
	return is_active and _state == State.CUBICLE


# --- Lo que ve el jugador -----------------------------------------------------

func camera_state() -> String:
	match stage:
		Stage.HALF:
			return STATE_HALF
		Stage.STANDING:
			return STATE_STANDING
	return STATE_SITTING


## Su cámara lleva sus etapas, no su nombre. Una vez que salió sigue
## diciendo que la silla quedó vacía, aunque él ya esté en otra habitación.
func camera_token(camera: int) -> String:
	if not is_active or camera != Rooms.camera_of(ROOM):
		return ""
	return camera_state() if _state == State.CUBICLE else STATE_EMPTY


## Se ve asomado en el marco lateral, en las dos vistas.
func is_in_zone(zone_id: String) -> bool:
	return _state == State.INSIDE and zone_id in SIDE_ZONES


func zone_presence(zone_id: String) -> String:
	if _state != State.INSIDE or not zone_id in SIDE_ZONES:
		return ""
	return SIDE_PRESENCE


func debug_text() -> String:
	match _state:
		State.COMING:
			return "en la recepción, %.1f s para asomarse" % maxf(COMING_TIME - _state_elapsed, 0.0)
		State.INSIDE:
			return "asomado en el marco"
	return "%s%s" % [camera_state(), ", molesto" if _annoyed else ""]


## Tecla 3: lo deja de pie, para no esperar las etapas.
func debug_stand_up() -> void:
	debug_activate()
	if _state != State.CUBICLE:
		return
	_set_stage(Stage.STANDING)


# --- Entrada ------------------------------------------------------------------

func _set_stage(new_stage: int) -> void:
	stage = clampi(new_stage, Stage.SITTING, Stage.STANDING)


## Se levantó y nadie lo bajó: deja la silla vacía y cruza la recepción.
func _start_coming() -> void:
	_state = State.COMING
	_state_elapsed = 0.0
	move_to_step(1)
	made_noise.emit(STEPS_NOTICE, NOTICE_TIME)


func _appear() -> void:
	_state = State.INSIDE
	_state_elapsed = 0.0
	_say_player_name()


## Dice el nombre del guardia con la síntesis de voz de Godot, en español y
## grave. Si el sistema no tiene voces, queda solo el aviso en pantalla.
func _say_player_name() -> void:
	made_noise.emit(NAME_NOTICE_FORMAT % GameManager.PLAYER_NAME, NOTICE_TIME)
	var voice: String = _spanish_voice()
	if voice.is_empty():
		return
	DisplayServer.tts_speak(GameManager.PLAYER_NAME, voice, TTS_VOLUME, TTS_PITCH, TTS_RATE)


func _spanish_voice() -> String:
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return ""
	var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(TTS_LANGUAGE)
	return voices[0] if not voices.is_empty() else ""


func _catch_player() -> void:
	stop()
	GameManager.trigger_game_over(GAME_OVER_CAUSE)


## El panel de pruebas lo manda a atacar por aquí.
func debug_force_attack() -> void:
	debug_stand_up()
