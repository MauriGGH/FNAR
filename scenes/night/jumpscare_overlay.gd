extends Control

## El salto de cada muerte. Siempre igual: la variante _a un instante, corte
## a la imagen final con zoom, temblor fuerte, un destello blanco de un cuadro
## y un grito provisional; después estática y, al acabar, la pantalla de game
## over con su causa.
##
## Mamador es la excepción: no salta. Su pantalla enseña a los militares con un
## zoom lento, luces rojo y azul parpadeando y "DELITO FEDERAL" al centro.
##
## También hace el susto del cortaso, que no mata: negro, la cara un momento
## con un chispazo, y de vuelta al juego.

## Terminó la animación: quien escuche puede cambiar de pantalla.
signal finished()

const IMAGE_PATH: String = "res://assets/art/jumpscares/jumpscare_%s"

# La animación de muerte.
const FIRST_FRAME_TIME: float = 0.12
const ZOOM_TIME: float = 0.5
const ZOOM_FROM: float = 1.0
const ZOOM_TO: float = 1.15
const SHAKE_PIXELS: float = 26.0
const SHAKE_SPEED: float = 47.0
const FLASH_FRAMES: int = 1
## Lo que se queda la estática antes de pasar al game over.
const STATIC_TIME: float = 0.9
const STATIC_STRENGTH: float = 0.95

# El susto del cortaso: igual de corto, pero sin muerte.
const SCARE_BLACK_TIME: float = 0.18
const SCARE_TIME: float = 0.5
const SCARE_ID: String = "audel_susto"

# La pantalla de Mamador.
const MAMADOR_ID: String = "mamador_militares"
const MAMADOR_TIME: float = 3.2
const MAMADOR_ZOOM_TO: float = 1.06
const MAMADOR_TEXT: String = "DELITO FEDERAL"
const MAMADOR_TEXT_SIZE: int = 74
const MAMADOR_LIGHT_TIME: float = 0.28
const RED_LIGHT: Color = Color(1.0, 0.1, 0.15, 0.26)
const BLUE_LIGHT: Color = Color(0.2, 0.35, 1.0, 0.26)

const TEXT_COLOR: Color = Color(1.0, 0.96, 0.92)
const OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.95)
const OUTLINE_SIZE: int = 14

enum Phase { NONE, FIRST, MAIN, STATIC, SCARE_BLACK, SCARE, MAMADOR }

var is_playing: bool = false

var _phase: Phase = Phase.NONE
var _left: float = 0.0
var _elapsed: float = 0.0
var _zoom: float = ZOOM_FROM
var _flash_left: int = 0
var _first: Texture2D = null
var _main: Texture2D = null
var _cache: Dictionary = {}

@onready var scream: AudioStreamPlayer = $Scream
@onready var static_overlay: ColorRect = $StaticOverlay


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP  # Nada de clicar por debajo.
	static_overlay.visible = false


## La muerte de un profe, por el id de su imagen (barcosa, urena, audel...).
func play(jumpscare_id: String) -> void:
	if is_playing:
		return
	_first = _texture("%s_a" % jumpscare_id)
	_main = _texture(jumpscare_id)
	if _main == null and _first == null:
		# Sin imágenes no hay salto: se pasa de largo al game over.
		finished.emit()
		return
	is_playing = true
	visible = true
	_elapsed = 0.0
	_zoom = ZOOM_FROM
	_flash_left = FLASH_FRAMES
	_set_phase(Phase.FIRST, FIRST_FRAME_TIME)
	scream.play()


## La pantalla de Mamador: no salta, pero igual es el final.
func play_mamador() -> void:
	if is_playing:
		return
	_first = null
	_main = _texture(MAMADOR_ID)
	is_playing = true
	visible = true
	_elapsed = 0.0
	_zoom = ZOOM_FROM
	_flash_left = 0
	_set_phase(Phase.MAMADOR, MAMADOR_TIME)


## El susto del cortaso: no mata, así que al acabar no avisa a nadie.
func play_scare() -> void:
	if is_playing:
		return
	_first = _texture("%s_a" % SCARE_ID)
	_main = _texture(SCARE_ID)
	if _main == null and _first == null:
		return
	is_playing = true
	visible = true
	_elapsed = 0.0
	_zoom = ZOOM_FROM
	_flash_left = 0
	_set_phase(Phase.SCARE_BLACK, SCARE_BLACK_TIME)
	scream.play()


func _texture(name: String) -> Texture2D:
	if not _cache.has(name):
		_cache[name] = GameAssets.load_texture(IMAGE_PATH % name)
	return _cache[name]


func _set_phase(phase: Phase, seconds: float) -> void:
	_phase = phase
	_left = seconds
	static_overlay.visible = phase == Phase.STATIC
	if static_overlay.visible:
		var material: ShaderMaterial = static_overlay.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("strength", STATIC_STRENGTH)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_playing:
		return
	_elapsed += delta
	_left -= delta
	if _flash_left > 0:
		_flash_left -= 1
	if _phase == Phase.MAIN:
		_zoom = lerpf(ZOOM_FROM, ZOOM_TO, clampf(1.0 - _left / ZOOM_TIME, 0.0, 1.0))
	elif _phase == Phase.MAMADOR:
		_zoom = lerpf(ZOOM_FROM, MAMADOR_ZOOM_TO, clampf(1.0 - _left / MAMADOR_TIME, 0.0, 1.0))
	queue_redraw()
	if _left > 0.0:
		return
	match _phase:
		Phase.FIRST:
			_set_phase(Phase.MAIN, ZOOM_TIME)
		Phase.MAIN:
			_set_phase(Phase.STATIC, STATIC_TIME)
		Phase.SCARE_BLACK:
			_set_phase(Phase.SCARE, SCARE_TIME)
		_:
			_stop(_phase != Phase.SCARE)


func _stop(notify: bool) -> void:
	is_playing = false
	visible = false
	static_overlay.visible = false
	_phase = Phase.NONE
	if notify:
		finished.emit()


# --- Dibujo -------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0))
	match _phase:
		Phase.FIRST:
			_draw_image(_first if _first != null else _main, 1.0, _shake())
		Phase.MAIN:
			_draw_image(_main if _main != null else _first, _zoom, _shake())
		Phase.SCARE_BLACK:
			pass  # Negro a secas, para que el corte pegue.
		Phase.SCARE:
			_draw_image(_main if _main != null else _first, 1.0, _shake() * 0.5)
			_draw_spark()
		Phase.MAMADOR:
			_draw_image(_main, _zoom, Vector2.ZERO)
			_draw_police_lights()
			_draw_centered(MAMADOR_TEXT, MAMADOR_TEXT_SIZE, size * 0.5)
		Phase.STATIC:
			pass  # La estática la pinta su propio nodo.
	if _flash_left > 0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, 0.92))


## La imagen llena la pantalla, con su zoom alrededor del centro.
func _draw_image(texture: Texture2D, zoom: float, offset: Vector2) -> void:
	if texture == null:
		return
	var scaled: Vector2 = size * zoom
	draw_texture_rect(texture, Rect2((size - scaled) * 0.5 + offset, scaled), false)


func _shake() -> Vector2:
	return Vector2(sin(_elapsed * SHAKE_SPEED), sin(_elapsed * SHAKE_SPEED * 0.7)) * SHAKE_PIXELS


## El chispazo del cortaso: unas líneas blancas saliendo de un punto.
func _draw_spark() -> void:
	var center: Vector2 = size * Vector2(0.5, 0.42)
	for i: int in 9:
		var angle: float = TAU * float(i) / 9.0 + _elapsed * 7.0
		var length: float = size.y * randf_range(0.08, 0.2)
		draw_line(center, center + Vector2.from_angle(angle) * length,
			Color(0.75, 0.9, 1.0, 0.8), 3.0)


## Las luces de la patrulla: medio rojo y medio azul, alternando.
func _draw_police_lights() -> void:
	var red_first: bool = fmod(_elapsed, MAMADOR_LIGHT_TIME * 2.0) < MAMADOR_LIGHT_TIME
	var half: Rect2 = Rect2(Vector2.ZERO, Vector2(size.x * 0.5, size.y))
	draw_rect(half, RED_LIGHT if red_first else BLUE_LIGHT)
	draw_rect(Rect2(Vector2(size.x * 0.5, 0.0), half.size), BLUE_LIGHT if red_first else RED_LIGHT)


func _draw_centered(text: String, font_size: int, center: Vector2) -> void:
	var font: Font = get_theme_default_font()
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var at: Vector2 = Vector2(center.x - width * 0.5, center.y + float(font_size) * 0.35)
	draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size,
		OUTLINE_SIZE, OUTLINE_COLOR)
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, TEXT_COLOR)
