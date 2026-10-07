extends Control

## El ojo de Armando en la oscuridad. Cuando está pegado al cristal y el cono de
## la linterna no le da, no se ve nada de él salvo esto: un punto naranja tenue
## que parpadea de vez en cuando, justo donde tiene el ojo en su recorte.
##
## La posición sale de data/office_layers.gd, medida sobre `centro_armando` como
## el píxel naranja más brillante de la capa.

## Cada cuánto parpadea y lo que dura el parpadeo.
const MIN_GAP: float = 1.6
const MAX_GAP: float = 4.5
const BLINK_TIME: float = 0.55
## Lo grande y lo fuerte que es el punto. Tenue a propósito: tiene que costar
## verlo, no señalarlo.
const DOT_RADIUS: float = 3.0
const GLOW_RADIUS: float = 9.0
const PEAK_ALPHA: float = 0.55

var _present: bool = false
var _is_lit: bool = false
var _gap_left: float = 0.0
var _blink_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gap_left = randf_range(MIN_GAP, MAX_GAP)


## Si Armando está o no pegado al cristal.
func set_present(present: bool) -> void:
	if _present == present:
		return
	_present = present
	if not _present:
		_blink_left = 0.0
		_gap_left = randf_range(MIN_GAP, MAX_GAP)
	queue_redraw()


## Con el cono encima ya se le ve entero, así que el puntito sobra.
func set_lit(is_lit: bool) -> void:
	if _is_lit == is_lit:
		return
	_is_lit = is_lit
	queue_redraw()


func _process(delta: float) -> void:
	if not _present or _is_lit:
		return
	if _blink_left > 0.0:
		_blink_left -= delta
		if _blink_left <= 0.0:
			_gap_left = randf_range(MIN_GAP, MAX_GAP)
		queue_redraw()
		return
	_gap_left -= delta
	if _gap_left <= 0.0:
		_blink_left = BLINK_TIME
		queue_redraw()


func _draw() -> void:
	if not _present or _is_lit or _blink_left <= 0.0:
		return
	# Entra y sale suave, para que parezca un reflejo y no un foco.
	var fade: float = sin(PI * (1.0 - _blink_left / BLINK_TIME))
	var alpha: float = PEAK_ALPHA * fade
	var at: Vector2 = OfficeLayers.ARMANDO_EYE * size
	var color: Color = OfficeLayers.ARMANDO_EYE_COLOR
	DrawKit.glow(self, at, GLOW_RADIUS, color, alpha * 0.8)
	draw_circle(at, DOT_RADIUS, Color(color.r, color.g, color.b, alpha))
