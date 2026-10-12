class_name ExitHint
extends Label

## La pista de cómo salir de una pantalla acercada (la PC, el tablero del
## breaker, la sala de servidores). Antes cada una tenía su botón; ahora se sale
## con un clic fuera o con Escape, y lo único que queda es este renglón
## chiquito y gris abajo al centro.
##
## **Sale una sola vez por noche y por pantalla.** La primera vez que abres la
## PC esa noche la lees; de ahí en adelante ya sabes. Se desvanece sola.

const TEXT: String = "clic fuera o Esc para salir"
const SIZE_AT_1080: float = 18.0
const REFERENCE_HEIGHT: float = 1080.0
const COLOR: Color = Color(0.62, 0.63, 0.65)
## Lo que se queda quieta y lo que tarda en irse.
const HOLD: float = 1.4
const FADE: float = 1.6
## A qué altura va, en fracción del alto.
const BOTTOM: float = 0.93

## Las pantallas que ya la enseñaron esta noche. Se limpia al empezar una.
static var _shown: Dictionary = {}

## Dónde se coloca: dentro de este recuadro, abajo y al centro. La PC le pasa
## el hueco de su escritorio, para que la pista no caiga en el marco del
## monitor ni encima de la barra de cámaras de la oficina. Vacío = toda la
## pantalla.
var region: Rect2 = Rect2()


## Nueva noche: todas vuelven a enseñarla una vez.
static func reset() -> void:
	_shown.clear()


## La mete en una pantalla y la deja lista, sin enseñarla todavía.
static func build(parent: Control) -> ExitHint:
	var hint: ExitHint = ExitHint.new()
	hint.name = "ExitHint"
	parent.add_child(hint)
	return hint


func _ready() -> void:
	text = TEXT
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_override("font", Fonts.terminal())
	add_theme_color_override("font_color", COLOR)
	modulate.a = 0.0
	set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	resized.connect(_layout)
	_layout()


func _layout() -> void:
	var parent: Control = get_parent() as Control
	var full: Vector2 = parent.size if parent != null \
		else Vector2(REFERENCE_HEIGHT * 1.78, REFERENCE_HEIGHT)
	var box: Rect2 = region if region.size.y > 0.0 else Rect2(Vector2.ZERO, full)
	add_theme_font_size_override("font_size",
		maxi(10, roundi(SIZE_AT_1080 * full.y / REFERENCE_HEIGHT)))
	# Anclada arriba a la izquierda y colocada a mano: así cae donde diga el
	# recuadro y no donde acabe el nodo padre.
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	var line: float = full.y * 0.045
	position = Vector2(box.position.x, box.position.y + box.size.y * BOTTOM - line * 0.5)
	size = Vector2(box.size.x, line)


## Le dice en qué recuadro colocarse (el hueco del escritorio, por ejemplo).
func set_region(rect: Rect2) -> void:
	region = rect
	_layout()


## La enseña si a esta pantalla todavía no le ha salido esta noche.
func show_once(screen_id: String) -> void:
	if _shown.has(screen_id):
		return
	_shown[screen_id] = true
	_layout()
	modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(HOLD)
	tween.tween_property(self, "modulate:a", 0.0, FADE)
