extends Control

## La muerte por apagón. Cuando la energía llega a 0 todo se apaga y el
## jugador se queda a oscuras. Entre 3 y 12 s después aparecen dos chispas
## azules a lo lejos durante 2 s, y de ahí viene el salto del Mago Eléctrico.
##
## Pasa en todas las noches, aunque el Mago esté en nivel 0: el apagón es
## suyo. Y si dan las 6 AM antes del salto, el jugador se salva.

## Llegó el momento del salto.
signal strike()
## Ya se ven las chispas: es cuando suena la cajita musical.
signal sparks_started()

const MIN_WAIT: float = 3.0
const MAX_WAIT: float = 12.0
## Lo que se ven las chispas antes del salto.
const SPARKS_TIME: float = 2.0

## Las dos chispas, en posición normalizada de la pantalla.
const SPARK_SPOTS: Array[Vector2] = [Vector2(0.39, 0.46), Vector2(0.58, 0.44)]
const SPARK_COLOR: Color = Color(0.45, 0.72, 1.0)
const SPARK_RADIUS: float = 7.0
## Cada cuánto titilan.
const SPARK_BLINK: float = 0.13

var is_running: bool = false
var is_showing_sparks: bool = false

var _wait_left: float = 0.0
var _sparks_left: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Empieza la cuenta a oscuras. El tiempo es al azar para que no se aprenda.
func start() -> void:
	if is_running:
		return
	is_running = true
	is_showing_sparks = false
	_wait_left = randf_range(MIN_WAIT, MAX_WAIT)
	_sparks_left = SPARKS_TIME
	_elapsed = 0.0
	visible = true
	queue_redraw()


## Se corta: dieron las 6 AM y el jugador se salvó.
func cancel() -> void:
	is_running = false
	is_showing_sparks = false
	visible = false


func _process(delta: float) -> void:
	if not is_running:
		return
	_elapsed += delta
	if not is_showing_sparks:
		_wait_left -= delta
		if _wait_left <= 0.0:
			is_showing_sparks = true
			queue_redraw()
			sparks_started.emit()
		return
	_sparks_left -= delta
	queue_redraw()
	if _sparks_left <= 0.0:
		is_running = false
		is_showing_sparks = false
		visible = false
		strike.emit()


func _draw() -> void:
	if not is_showing_sparks:
		return
	# Titilan, como un corto a lo lejos.
	var on: bool = fmod(_elapsed, SPARK_BLINK * 2.0) < SPARK_BLINK
	if not on:
		return
	for spot: Vector2 in SPARK_SPOTS:
		DrawKit.glow(self, spot * size, SPARK_RADIUS, SPARK_COLOR, 1.0)
		draw_circle(spot * size, SPARK_RADIUS * 0.45, Color(0.85, 0.94, 1.0, 0.9))
