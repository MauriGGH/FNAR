class_name Urena
extends Animatronic

## Ureña (rol Chica). Lento: sube por los baños y el salón E (o el salón sin
## cámara de al lado) hasta el cristal de la oficina. No usa la reserva del
## pasillo, así que puede coincidir con Barcosa o con Mamador.
## En el cristal solo se ve con la linterna encendida, como en FNAF 2, y para
## alejarlo hay que darle destellos cortos.

enum State {
	WALKING,     # Subiendo por su ruta
	AT_GLASS,    # Pegado al cristal, contando destellos
}

## Nivel de IA mientras no exista la configuración por noche (hito 6).
## Para probar: 10. En la noche 1 el nivel real es 0, o sea que no aparece.
const DEBUG_AI_LEVEL: int = 10

const STEP_BANOS: int = 0
const STEP_MIDDLE: int = 1
const STEP_PASILLO_SUR: int = 2
## El segundo paso se sortea: el salón E tiene cámara, el 3 es punto ciego.
const MIDDLE_ROOMS: Array[String] = ["salon_e", "salon_3"]

## Cada cuánto tira el dado. Es el más lento de todos.
const MOVE_INTERVAL: float = 8.0

# Destellos: solo cuentan los encendidos cortos, ni un toque ni un reflector.
const FLASH_MIN_TIME: float = 0.2
const FLASH_MAX_TIME: float = 1.0
const FLASHES_TO_REPEL: int = 4
## Lo que aguanta en el cristal antes de entrar.
const GLASS_TIME: float = 10.0

const GAME_OVER_CAUSE: String = "Ureña"
const GLASS_PRESENCE: String = "Ureña pegado al cristal"
const GLASS_ZONE: String = "front_glass"
const ARRIVE_NOTICE: String = "[respiración en el cristal]"
const REPEL_NOTICE: String = "[Ureña se aleja]"
const NOTICE_TIME: float = 2.2

var flashes: int = 0

var _state: State = State.WALKING
var _glass_elapsed: float = 0.0
## Lo que lleva encendida la linterna, acumulado con el delta del juego.
## Con el reloj de pared no serviría: el tiempo del juego es el que cuenta.
var _flash_elapsed: float = -1.0


func start() -> void:
	ai_level = DEBUG_AI_LEVEL
	move_interval = MOVE_INTERVAL
	# El salón del medio cambia cada noche.
	route = PackedStringArray(["banos", MIDDLE_ROOMS[randi() % MIDDLE_ROOMS.size()], "pasillo_sur"])
	super()
	_state = State.WALKING
	_glass_elapsed = 0.0
	_flash_elapsed = -1.0
	flashes = 0


func _process(delta: float) -> void:
	if not is_active:
		return
	if _flash_elapsed >= 0.0:
		_flash_elapsed += delta
	match _state:
		State.WALKING:
			super(delta)  # El dado de la IA de la clase base
		State.AT_GLASS:
			_glass_elapsed += delta
			if _glass_elapsed >= GLASS_TIME:
				_catch_player()


## Le ganó el dado: sube un paso. Al llegar al pasillo se pega al cristal.
## No pide el pasillo a nadie: puede coincidir con los demás.
func advance() -> void:
	var next_step: int = _route_index + 1
	if next_step > STEP_PASILLO_SUR:
		return
	move_to_step(next_step)
	if next_step == STEP_PASILLO_SUR:
		_state = State.AT_GLASS
		_glass_elapsed = 0.0
		flashes = 0
		made_noise.emit(ARRIVE_NOTICE, NOTICE_TIME)


## Cada encendido corto de la linterna cuenta un destello.
func set_flashlight_on(is_on: bool) -> void:
	if is_on:
		_flash_elapsed = 0.0
		return
	if _flash_elapsed < 0.0:
		return
	var duration: float = _flash_elapsed
	_flash_elapsed = -1.0
	if _state != State.AT_GLASS:
		return
	if duration < FLASH_MIN_TIME or duration > FLASH_MAX_TIME:
		return  # Ni un toque ni dejarla prendida: tiene que ser un destello.
	flashes += 1
	if flashes >= FLASHES_TO_REPEL:
		_repel()


## Solo se ve pegado al cristal si la linterna está encendida.
func zone_presence(zone_id: String) -> String:
	if zone_id != GLASS_ZONE or _state != State.AT_GLASS:
		return ""
	return GLASS_PRESENCE if PowerManager.is_flashlight_on else ""


func debug_text() -> String:
	if _state == State.AT_GLASS:
		return "en el cristal, %d/%d destellos, %.1f s" % [
			flashes, FLASHES_TO_REPEL, maxf(GLASS_TIME - _glass_elapsed, 0.0)]
	return "en %s" % Rooms.display_name(current_room)


## Tecla 1: lo manda directo al cristal, para no esperar al dado.
func debug_force_to_glass() -> void:
	if _state != State.WALKING:
		return
	move_to_step(STEP_MIDDLE)
	advance()


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_1:
		debug_force_to_glass()


func _repel() -> void:
	made_noise.emit(REPEL_NOTICE, NOTICE_TIME)
	_state = State.WALKING
	_glass_elapsed = 0.0
	flashes = 0
	move_to_step(STEP_BANOS)


func _catch_player() -> void:
	stop()
	GameManager.trigger_game_over(GAME_OVER_CAUSE)
