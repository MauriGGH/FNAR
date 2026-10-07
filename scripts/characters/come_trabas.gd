class_name ComeTrabas
extends Animatronic

## Come Trabas (rol Puppet; antes el profe Santi). La botarga de la mascota con
## el alma de Santi dentro. Mientras tenga cuerda sigue desplomada en la silla
## del cubículo 3 y toca el himno; la cuerda baja sola y se le da manteniendo
## el botón de la CAM 4. En cero levanta la cabeza, deja la silla vacía y va
## por el jugador: el salto es la botarga misma.
## No usa el dado de la IA: su reloj es la cuerda.

enum Speed { SLOW, MEDIUM, FAST, VERY_FAST }

## Segundos que tarda la cuerda en vaciarse desde 100 %, por velocidad de noche.
const DRAIN_TIMES: Dictionary = {
	Speed.SLOW: 90.0,
	Speed.MEDIUM: 70.0,
	Speed.FAST: 55.0,
	Speed.VERY_FAST: 40.0,
}

const ROOM: String = "cubiculo_3"

const MAX_WIND: float = 100.0
## Lo que sube la cuerda por segundo mientras mantienes el botón.
const WIND_PER_SECOND: float = 25.0
## Debajo de este porcentaje despierta y el aviso parpadea en amarillo.
const WARNING_THRESHOLD: float = 25.0
## Y debajo de este, el aviso se pone rojo y parpadea más rápido.
const CRITICAL_THRESHOLD: float = 10.0
## Lo que tarda la botarga en llegar desde que la cuerda llegó a cero.
const ATTACK_TIME: float = 5.0

# Estados de la CAM 4. El sistema de cámaras busca cam04_<estado>.png.
const STATE_SLUMPED: String = "desplomada"
const STATE_WAKING: String = "despertando"
const STATE_EMPTY: String = "vacia"

const GAME_OVER_CAUSE: String = "Come Trabas"
const MUSIC_STOPPED_NOTICE: String = "[la música se detuvo]"
const NOTICE_TIME: float = 3.0

signal wind_changed(percent: float)
signal music_stopped()

var wind: float = MAX_WIND
var is_winding: bool = false
var is_attacking: bool = false
var speed: int = Speed.SLOW

var _attack_elapsed: float = 0.0


func start() -> void:
	route = PackedStringArray([ROOM])
	super()
	is_active = true  # La clase base pide nivel de IA; este no lo usa.
	# Su reloj no es el dado sino la cuerda, así que de la tabla de noches
	# toma la velocidad en vez de un nivel de IA.
	speed = Nights.come_trabas_speed(GameManager.current_night)
	wind = MAX_WIND
	is_winding = false
	is_attacking = false
	_attack_elapsed = 0.0
	wind_changed.emit(wind)


## Lo que baja la cuerda por segundo con la velocidad de esta noche.
func drain_per_second() -> float:
	return MAX_WIND / float(DRAIN_TIMES.get(speed, DRAIN_TIMES[Speed.MEDIUM]))


func _process(delta: float) -> void:
	if not is_active:
		return

	if is_attacking:
		_attack_elapsed += delta
		if _attack_elapsed >= ATTACK_TIME:
			_catch_player()
		return

	var change: float = -drain_per_second()
	if is_winding:
		change += WIND_PER_SECOND
	var new_wind: float = clampf(wind + change * delta, 0.0, MAX_WIND)
	if is_equal_approx(new_wind, wind):
		return
	wind = new_wind
	wind_changed.emit(wind)
	if is_zero_approx(wind):
		_start_attack()


## El botón de la CAM 4 llama a esto mientras se mantiene presionado.
func set_winding(winding: bool) -> void:
	if is_attacking:
		return
	is_winding = winding


## true mientras hay que mostrar el aviso parpadeante junto a la barra de cámaras.
func is_warning() -> bool:
	return warning_level() > 0


## 0 sin aviso, 1 amarillo, 2 rojo y más rápido.
func warning_level() -> int:
	if not is_active or wind > WARNING_THRESHOLD:
		return 0
	return 2 if wind <= CRITICAL_THRESHOLD else 1


## Estado de la CAM 4 según la cuerda.
func camera_state() -> String:
	if is_attacking:
		return STATE_EMPTY
	if wind > WARNING_THRESHOLD:
		return STATE_SLUMPED
	return STATE_WAKING


## Su cámara no usa nombres de profe: lleva sus tres estados de siempre.
func camera_token(camera: int) -> String:
	if camera != Rooms.camera_of(ROOM):
		return ""
	return camera_state()


## Nunca se mueve por su cuenta.
func can_move() -> bool:
	return false


func debug_text() -> String:
	if is_attacking:
		return "levantada, %.1f s para el salto" % maxf(ATTACK_TIME - _attack_elapsed, 0.0)
	return "cuerda %d %% (%s)" % [roundi(wind), camera_state()]


## F7: deja la cuerda casi vacía, para no tener que esperar.
func debug_low_wind() -> void:
	if is_attacking:
		return
	wind = 5.0
	wind_changed.emit(wind)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_F7:
		debug_low_wind()


## La cuerda llegó a cero: de aquí ya no hay vuelta.
func _start_attack() -> void:
	is_attacking = true
	is_winding = false
	_attack_elapsed = 0.0
	made_noise.emit(MUSIC_STOPPED_NOTICE, NOTICE_TIME)
	music_stopped.emit()


func _catch_player() -> void:
	stop()
	GameManager.trigger_game_over(GAME_OVER_CAUSE)
