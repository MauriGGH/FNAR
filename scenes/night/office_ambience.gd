class_name OfficeAmbience
extends Node

## El ambiente de la oficina, en tres capas que suenan toda la noche por el bus
## Ambiente: el ventilador (`ambiente_oficina`), el zumbido de las lámparas
## (`ambiente_lampara`) y el tono del cuarto (`ambiente_pasillo`). El zumbido
## solo va en la lámpara: al archivo del ventilador se le quitó el que traía.
##
## **Es igual todas las noches.** Lo único que cambia de una noche a otra son
## los sonidos de los profes, y esos van aparte (scenes/night/distant_sounds.gd).
##
## **No es plano.** Cada capa sube y baja ±3 dB muy despacio, con un ciclo de
## 15 a 40 s que se vuelve a sortear en cada vuelta, y las tres arrancan
## desfasadas, así que nunca suben juntas. Y de vez en cuando pasa algo chico:
## el ventilador baja de tono un momento, como si se forzara, o la lámpara
## parpadea con su zumbido. No hacen nada en el juego: son ambiente.
##
## Sin corriente (el breaker o la energía en 0) se callan el ventilador y la
## lámpara; el cuarto se sigue oyendo.

const FAN: String = Sounds.OFFICE_AMBIENCE
const LAMP: String = Sounds.LAMP_HUM
const ROOM: String = Sounds.HALLWAY_AMBIENCE
const LAYERS: Array[String] = [FAN, LAMP, ROOM]
## Las que necesitan corriente.
const POWERED: Array[String] = [FAN, LAMP]

## Cuánto sube y baja cada capa, y lo que tarda un ciclo completo.
const SWING_DB: float = 3.0
const MIN_PERIOD: float = 15.0
const MAX_PERIOD: float = 40.0

## Cada cuánto pasa algo chico, en segundos.
const MIN_EVENT_GAP: float = 20.0
const MAX_EVENT_GAP: float = 60.0

## El ventilador que se fuerza: baja de tono y vuelve, en una sola curva.
const FAN_DIP_PITCH: float = 0.93
const FAN_DIP_MIN_TIME: float = 1.8
const FAN_DIP_MAX_TIME: float = 3.2

## La lámpara que parpadea: saltos de volumen cortos, como una reactancia que
## falla, y al final vuelve a su sitio.
const FLICKER_MIN_TIME: float = 0.5
const FLICKER_MAX_TIME: float = 1.1
const FLICKER_STEP_MIN: float = 0.04
const FLICKER_STEP_MAX: float = 0.11
const FLICKER_LOW_DB: float = -16.0
const FLICKER_HIGH_DB: float = 2.0

enum Event { NONE, FAN_DIP, LAMP_FLICKER }

var is_running: bool = false
var is_powered: bool = true

## Por capa: en qué punto del ciclo va (0 a TAU) y cuánto dura su ciclo.
var _phase: Dictionary = {}
var _period: Dictionary = {}
var _event_left: float = 0.0
var _event: Event = Event.NONE
var _event_time: float = 0.0
var _event_elapsed: float = 0.0
var _flicker_step_left: float = 0.0
var _flicker_db: float = 0.0


## Arranca las tres capas, cada una en un punto distinto de su ciclo.
func start() -> void:
	is_running = true
	is_powered = true
	for i: int in LAYERS.size():
		var id: String = LAYERS[i]
		# Repartidas en el círculo y movidas un poco: así no suben juntas.
		_phase[id] = fmod(TAU * float(i) / float(LAYERS.size()) + randf_range(-0.5, 0.5), TAU)
		_period[id] = randf_range(MIN_PERIOD, MAX_PERIOD)
		AudioManager.play_loop(id)
	_end_event()
	_event_left = randf_range(MIN_EVENT_GAP, MAX_EVENT_GAP)
	_apply_volumes()


## Calla las tres. Lo usa el fin de noche.
func stop() -> void:
	is_running = false
	_end_event()
	for id: String in LAYERS:
		AudioManager.stop(id)


## Sin corriente se van el ventilador y la lámpara; con corriente vuelven.
func set_powered(powered: bool) -> void:
	if powered == is_powered:
		return
	is_powered = powered
	if not is_running:
		return
	for id: String in POWERED:
		if powered:
			AudioManager.play_loop(id)
		else:
			AudioManager.stop(id)
	if not powered:
		_end_event()
	_apply_volumes()


func _process(delta: float) -> void:
	if not is_running:
		return
	for id: String in LAYERS:
		var period: float = float(_period[id])
		var phase: float = float(_phase[id]) + TAU * delta / period
		# Cada vuelta completa sortea otra duración: el vaivén nunca se repite
		# igual. Cambiar de duración en el cruce no da salto, porque el seno
		# sigue desde la misma fase.
		if phase >= TAU:
			phase -= TAU
			_period[id] = randf_range(MIN_PERIOD, MAX_PERIOD)
		_phase[id] = phase
	_process_event(delta)
	_apply_volumes()


func _process_event(delta: float) -> void:
	if _event == Event.NONE:
		_event_left -= delta
		if _event_left <= 0.0 and is_powered:
			_start_event(Event.FAN_DIP if randf() < 0.5 else Event.LAMP_FLICKER)
		return
	_event_elapsed += delta
	if _event_elapsed >= _event_time:
		_end_event()
		return
	if _event == Event.FAN_DIP:
		# Una sola curva: baja y vuelve, sin escalón.
		var t: float = _event_elapsed / _event_time
		AudioManager.set_pitch(FAN, lerpf(1.0, FAN_DIP_PITCH, sin(PI * t)))
	elif _event == Event.LAMP_FLICKER:
		_flicker_step_left -= delta
		if _flicker_step_left <= 0.0:
			_flicker_step_left = randf_range(FLICKER_STEP_MIN, FLICKER_STEP_MAX)
			_flicker_db = randf_range(FLICKER_LOW_DB, FLICKER_HIGH_DB)


## Para el panel de pruebas: suelta uno de los dos sucesos ya.
func debug_event(fan: bool) -> void:
	if not is_running:
		return
	_end_event()
	_start_event(Event.FAN_DIP if fan else Event.LAMP_FLICKER)


func _start_event(event: Event) -> void:
	_event = event
	_event_elapsed = 0.0
	if event == Event.FAN_DIP:
		_event_time = randf_range(FAN_DIP_MIN_TIME, FAN_DIP_MAX_TIME)
	else:
		_event_time = randf_range(FLICKER_MIN_TIME, FLICKER_MAX_TIME)
		_flicker_step_left = 0.0


func _end_event() -> void:
	_event = Event.NONE
	_event_left = randf_range(MIN_EVENT_GAP, MAX_EVENT_GAP)
	_flicker_db = 0.0
	AudioManager.set_pitch(FAN, 1.0)


## El vaivén de cada capa más el parpadeo de la lámpara, si lo hay.
func _apply_volumes() -> void:
	for id: String in LAYERS:
		var offset: float = SWING_DB * sin(float(_phase.get(id, 0.0)))
		if id == LAMP and _event == Event.LAMP_FLICKER:
			offset += _flicker_db
		AudioManager.set_volume_offset(id, offset)


## Lo que el panel de pruebas enseña: cuánto lleva arriba o abajo cada capa.
func debug_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for id: String in LAYERS:
		parts.append("%s %+.1f dB (%.0f s)" % [id.trim_prefix("ambiente_"),
			SWING_DB * sin(float(_phase.get(id, 0.0))), float(_period.get(id, 0.0))])
	return " · ".join(parts)
