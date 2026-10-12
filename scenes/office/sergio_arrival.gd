class_name SergioArrival
extends Control

## La llegada de Sergio, en la vista central: un haz de luz blanca que baja
## sobre la recepción y, dentro de él, su silueta descendiendo flotando hasta
## quedar donde está en `centro_sergio.png`.
##
## Las dos imágenes traen la figura al mismo tamaño (170x291 px), así que la
## silueta baja **a la misma escala** y al llegar se funde con la capa sin que
## nada se mueva ni un píxel. Los sitios y los tiempos salen de `data/sergio.gd`.
##
## Vive dentro del contenido de la vista central, encima de la cortina y debajo
## de los profes pegados al cristal: Sergio está al otro lado, en la recepción.

## Ya acabó de bajar y de fundirse: que empiece el tótem.
signal arrived()
## Ya se fue del todo.
signal finished()

enum Phase { IDLE, DESCENT, BLEND, HOLD, FADE }

var _phase: Phase = Phase.IDLE
var _elapsed: float = 0.0
## 0 arriba, 1 en su sitio.
var _descent: float = 0.0
## Cuánto se ve ya la capa final, de 0 a 1.
var _blend: float = 0.0
## Lo abierto que está el haz, de 0 a 1.
var _beam: float = 0.0

var _layer: Texture2D = null
var _silhouette: Texture2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	visible = false
	_layer = Sergio.texture(Sergio.LAYER)
	_silhouette = Sergio.texture(Sergio.SILHOUETTE)


## Empieza la bajada. Sin las imágenes no hay nada que enseñar, así que avisa
## de inmediato y el rescate sigue con el tótem.
func play() -> void:
	if _layer == null and _silhouette == null:
		arrived.emit()
		return
	_phase = Phase.DESCENT
	_elapsed = 0.0
	_descent = 0.0
	_blend = 0.0
	_beam = 0.0
	visible = true
	set_process(true)
	queue_redraw()


## Que se vaya: el haz se cierra y Sergio se desvanece con él.
func fade_out() -> void:
	if _phase == Phase.IDLE:
		finished.emit()
		return
	_phase = Phase.FADE
	_elapsed = 0.0
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	match _phase:
		Phase.DESCENT:
			_beam = minf(_elapsed / Sergio.BEAM_FADE, 1.0)
			_descent = clampf(_elapsed / Sergio.DESCENT_TIME, 0.0, 1.0)
			if _elapsed >= Sergio.DESCENT_TIME:
				_phase = Phase.BLEND
				_elapsed = 0.0
		Phase.BLEND:
			_blend = clampf(_elapsed / Sergio.BLEND_TIME, 0.0, 1.0)
			if _elapsed >= Sergio.BLEND_TIME:
				_phase = Phase.HOLD
				_elapsed = 0.0
				arrived.emit()
		Phase.HOLD:
			pass
		Phase.FADE:
			var left: float = 1.0 - clampf(_elapsed / Sergio.FADE_OUT_TIME, 0.0, 1.0)
			_beam = left
			_blend = left
			if _elapsed >= Sergio.FADE_OUT_TIME:
				_phase = Phase.IDLE
				visible = false
				set_process(false)
				finished.emit()
		Phase.IDLE:
			set_process(false)
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0:
		return
	var figure: Rect2 = Sergio.figure_rect(size)
	_draw_beam(figure)
	# La capa final, cuando ya se está fundiendo.
	if _layer != null and _blend > 0.0:
		draw_texture_rect(_layer, Rect2(Vector2.ZERO, size), false,
			Color(1.0, 1.0, 1.0, _blend))
	# Y la silueta bajando, que se va apagando conforme entra la capa.
	if _silhouette != null and _blend < 1.0:
		draw_texture_rect(_silhouette, _silhouette_rect(figure), false,
			Color(1.0, 1.0, 1.0, 1.0 - _blend))


## Dónde va la silueta ahora: arranca justo encima del borde de la vista y baja
## hasta su sitio, meciéndose un poco de lado.
func _silhouette_rect(figure: Rect2) -> Rect2:
	var target: Rect2 = Sergio.silhouette_rect(size)
	var from_y: float = -target.size.y
	var eased: float = ease(_descent, 0.6)   # entra rápido y frena al llegar
	var sway: float = sin(_descent * TAU * Sergio.SWAY_CYCLES) * Sergio.SWAY_PIXELS \
		* (1.0 - _descent) * (size.x / OfficeLayers.REFERENCE_WIDTH)
	return Rect2(Vector2(target.position.x + sway,
		lerpf(from_y, target.position.y, eased)), target.size)


## El haz: una columna de luz que baja del techo sobre la recepción. Se dibuja
## con tiras verticales finas, cada una un poco más tenue conforme se alejan
## del centro, y cada tira con su degradado de arriba abajo: así no se ven
## escalones ni un rectángulo plano, sino luz.
## Muchas tiras y sin solaparse: si se solapan, el alfa se suma en la costura
## y se ven rayas más claras.
const BEAM_STRIPS: int = 44


func _draw_beam(figure: Rect2) -> void:
	if _beam <= 0.0:
		return
	var width: float = figure.size.x * Sergio.BEAM_WIDTH
	var center: float = figure.get_center().x
	var bottom: float = figure.end.y
	var strip: float = width / float(BEAM_STRIPS)
	for i: int in BEAM_STRIPS:
		# De 0 en el centro a 1 en el borde; la caída va al cuadrado, que es
		# lo que hace que se vea difuminado y no en bandas.
		var away: float = absf(float(i) - float(BEAM_STRIPS - 1) * 0.5) \
			/ (float(BEAM_STRIPS) * 0.5)
		var falloff: float = pow(1.0 - clampf(away, 0.0, 1.0), 2.2)
		var alpha: float = Sergio.BEAM_ALPHA * _beam * falloff
		if alpha <= 0.004:
			continue
		var rect: Rect2 = Rect2(Vector2(center - width * 0.5 + strip * float(i), 0.0),
			Vector2(strip, bottom))
		# Más fuerte arriba, donde nace, que a los pies.
		DrawKit.gradient_rect(self, rect,
			Color(Sergio.BEAM_COLOR.r, Sergio.BEAM_COLOR.g, Sergio.BEAM_COLOR.b, alpha),
			Color(Sergio.BEAM_COLOR.r, Sergio.BEAM_COLOR.g, Sergio.BEAM_COLOR.b,
				alpha * 0.35))
	# Y un remate más claro justo donde pisa.
	DrawKit.glow(self, Vector2(center, bottom), width * 0.45, Sergio.BEAM_COLOR,
		0.3 * _beam)
