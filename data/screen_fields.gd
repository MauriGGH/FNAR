class_name ScreenFields
extends RefCounted

## Dónde va cada texto encima de las pantallas que son una imagen (la solicitud
## de empleo y el recibo de pago). Las posiciones están medidas sobre las
## propias imágenes y viven en data/pantallas_campos.json, normalizadas sobre
## 1920x1080: aquí no se adivina ninguna.
##
## Cada campo puede traer:
##   x, y              esquina superior izquierda del texto (0 a 1)
##   ancho             ancho de la caja de texto (0 a 1); 0 si no lo trae
##   alineado          "derecha" si la x es el borde derecho
##   alto_texto_px_1080  tamaño de letra medido a 1080p (se escala con el alto)
##   color             la tinta, en #rrggbb
##   fuente            el nombre de la fuente, como lo entiende Fonts.by_name
##   rotacion          lo chueco que va, en grados

const PATH: String = "res://data/pantallas_campos.json"
## La pantalla sobre la que se midió todo.
const REFERENCE: Vector2 = Vector2(1920.0, 1080.0)

## Los campos de la solicitud de empleo y del recibo de pago.
const APPLICATION_NAME: String = "solicitud_nombre"
const APPLICATION_SIGNATURE: String = "solicitud_firma"
const PAYMENT_NAME: String = "pago_nombre"
const PAYMENT_NIGHT: String = "pago_noche"
const PAYMENT_TASKS: String = "pago_tareas"
const PAYMENT_AMOUNT: String = "pago_importe"
const PAYMENT_NOTE: String = "pago_nota_a_mano"

## La tinta azul de la firma: el JSON no la trae, porque la firma no es un
## campo impreso de la hoja sino lo que escribe el jugador.
const SIGNATURE_INK: Color = Color("#283a8c")
const SIGNATURE_SIZE_AT_1080: float = 64.0

static var _fields: Dictionary = {}
static var _loaded: bool = false


## El campo completo, o un diccionario vacío si no existe.
static func field(id: String) -> Dictionary:
	_load()
	return _fields.get(id, {}) as Dictionary


static func has_field(id: String) -> bool:
	_load()
	return _fields.has(id)


## La esquina superior izquierda del texto, en píxeles de esta pantalla. En los
## campos alineados a la derecha, la x es el borde derecho.
static func position(id: String, screen_size: Vector2) -> Vector2:
	var data: Dictionary = field(id)
	return Vector2(float(data.get("x", 0.0)) * screen_size.x,
		float(data.get("y", 0.0)) * screen_size.y)


## El ancho de la caja de texto, o 0 si el campo no lo trae.
static func width(id: String, screen_size: Vector2) -> float:
	return float(field(id).get("ancho", 0.0)) * screen_size.x


## El tamaño de letra, escalado desde el alto de referencia.
static func font_size(id: String, screen_height: float,
		fallback: float = 32.0) -> int:
	var measured: float = float(field(id).get("alto_texto_px_1080", fallback))
	return maxi(1, roundi(measured * screen_height / REFERENCE.y))


static func color(id: String, fallback: Color = Color.BLACK) -> Color:
	var value: String = str(field(id).get("color", ""))
	return Color(value) if not value.is_empty() else fallback


static func font(id: String) -> Font:
	return Fonts.by_name(str(field(id).get("fuente", "")))


## Lo chueco que va el texto, ya en radianes.
static func rotation(id: String) -> float:
	return deg_to_rad(float(field(id).get("rotacion", 0.0)))


static func alignment(id: String) -> HorizontalAlignment:
	if str(field(id).get("alineado", "")) == "derecha":
		return HORIZONTAL_ALIGNMENT_RIGHT
	return HORIZONTAL_ALIGNMENT_LEFT


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(PATH):
		push_warning("[pantallas] falta %s: los textos van a caer en 0,0" % PATH)
		return
	var text: String = FileAccess.get_file_as_string(PATH)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		_fields = parsed as Dictionary
