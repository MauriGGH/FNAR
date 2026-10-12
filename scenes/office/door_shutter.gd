extends Control

## La cortina metálica de la puerta de entrada. Es su propia capa,
## `assets/art/office/cortina_capa.png`, del tamaño de la vista y ya colocada
## en su sitio (ocupa x 407, y 250, 150 x 271 sobre la imagen de 1375x768).
##
## Al cerrar la chapa, la lámina se va revelando de arriba hacia abajo en
## CLOSE_TIME; al abrir, a la inversa. Cuando termina de bajar, la oficina
## cambia a las fotos con la puerta ya cerrada, así que a partir de ahí la
## cortina la trae pintada el fondo y esta capa deja de dibujarse.
##
## La caja del rodillo ya viene pintada en las fotos, con la puerta abierta y
## con la puerta cerrada, así que aquí no se dibuja nada de eso.
##
## Mientras baja, la capa respeta el cono de la linterna igual que el fondo:
## fuera del cono se ve apagada, dentro a todo brillo. De eso se encarga el
## mismo shader que usa la foto iluminada; como la capa está alineada con la
## vista, sus UV son las de la vista y el haz le cae donde toca.

## La capa de la cortina, del tamaño de la vista.
const LAYER_PATH: String = "res://assets/art/office/cortina_capa"
const REVEAL_SHADER: String = "res://scenes/office/flashlight_reveal.gdshader"

## Dónde está la lámina dentro de la capa, en normalizadas de la vista. Medido
## sobre el PNG: x 407, y 250, 150 x 271 de 1375x768.
const CURTAIN_RECT: Rect2 = Rect2(0.296, 0.32552, 0.10909, 0.35286)

## Lo que tarda en bajar y en subir.
const CLOSE_TIME: float = 0.6
const OPEN_TIME: float = 0.6

## Cortina provisional, por si falta la capa: láminas dibujadas a mano.
const SLAT_HEIGHT: float = 13.0
const BAR_HEIGHT: float = 9.0
const METAL_TOP: Color = Color(0.3, 0.31, 0.33)
const METAL_BOTTOM: Color = Color(0.17, 0.175, 0.19)
const GROOVE: Color = Color(0.06, 0.065, 0.075, 0.85)
const SLAT_EDGE: Color = Color(1.0, 1.0, 1.0, 0.1)
const BAR: Color = Color(0.24, 0.245, 0.26)

## Terminó de bajar: la oficina ya puede cambiar a las fotos con la puerta
## cerrada. Al empezar a subir avisa con false, para que vuelva a las normales.
signal closed_changed(is_closed: bool)

var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()

## true mientras el fondo ya trae la cortina pintada: entonces esta capa sobra.
var is_baked: bool = false

## El temblor de cada golpe de Barcosa: no se ve a él, pero sí la lámina.
const SHAKE_PIXELS: float = 2.5
const SHAKE_TIME: float = 0.15

var _texture: Texture2D = null
var _tween: Tween = null
var _shake_left: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	set_process(false)
	_texture = GameAssets.load_texture(LAYER_PATH)
	if _texture != null and ResourceLoader.exists(REVEAL_SHADER):
		var material: ShaderMaterial = ShaderMaterial.new()
		material.shader = load(REVEAL_SHADER)
		# Fuera del cono no desaparece: se queda apagada, como el fondo.
		material.set_shader_parameter("base_alpha", 1.0)
		material.set_shader_parameter("base_brightness", OfficeLayers.DIM_BRIGHTNESS)
		self.material = material


## El cono de la linterna, en normalizadas de la vista. Se lo pasa la oficina.
func set_beam(center: Vector2, half: Vector2, softness: float, strength: float) -> void:
	var shader: ShaderMaterial = material as ShaderMaterial
	if shader == null:
		return
	shader.set_shader_parameter("beam_center", center)
	shader.set_shader_parameter("beam_half", half)
	shader.set_shader_parameter("beam_softness", softness)
	shader.set_shader_parameter("beam_strength", strength)
	shader.set_shader_parameter("aspect", size.x / size.y if size.y > 0.0 else 1.78)


## Baja o sube la cortina, con su sonido.
func set_closed(closed: bool) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	AudioManager.play(Sounds.DOOR_SHUTTER)
	if not closed:
		# Al empezar a subir, el fondo vuelve a ser el de la puerta abierta y
		# esta capa se encarga otra vez de la lámina.
		is_baked = false
		closed_changed.emit(false)
		queue_redraw()
		_tween = create_tween()
		_tween.tween_property(self, "progress", 0.0, OPEN_TIME) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		return
	_tween = create_tween()
	_tween.tween_property(self, "progress", 1.0, CLOSE_TIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_on_closed)


## Ya tocó el piso: el fondo pasa a las fotos con la cortina pintada.
func _on_closed() -> void:
	is_baked = true
	closed_changed.emit(true)
	queue_redraw()


## Un golpe desde el otro lado: la lámina tiembla un momento. Es lo único que
## se ve de Barcosa aporreando, porque él queda detrás.
func shake() -> void:
	_shake_left = SHAKE_TIME
	set_process(true)


func _process(delta: float) -> void:
	if _shake_left <= 0.0:
		set_process(false)
		_shake_offset = Vector2.ZERO
		queue_redraw()
		return
	_shake_left = maxf(_shake_left - delta, 0.0)
	var amount: float = _shake_left / SHAKE_TIME * SHAKE_PIXELS
	_shake_offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
	queue_redraw()


## true cuando la lámina está recogida del todo.
func is_hidden_away() -> bool:
	return progress <= 0.001


func _draw() -> void:
	if size.x <= 0.0:
		return
	# Con la cortina ya pintada en el fondo esta capa estorba, salvo mientras
	# tiembla: ahí vuelve a dibujarse encima, corrida unos píxeles.
	if is_baked and _shake_left <= 0.0:
		return
	if not is_baked and is_hidden_away():
		return
	var area: Rect2 = Rect2(CURTAIN_RECT.position * size + _shake_offset,
		CURTAIN_RECT.size * size)
	# Ya bajada del todo mientras tiembla, o lo que lleve revelado si está bajando.
	var revealed: float = 1.0 if is_baked else clampf(progress, 0.0, 1.0)
	var shown: Rect2 = Rect2(area.position, Vector2(area.size.x, area.size.y * revealed))
	if shown.size.y <= 0.0:
		return
	if _texture == null:
		_draw_slats(shown)
		return
	# La capa está alineada con la vista, así que el recorte en pantalla y el
	# recorte en la textura son el mismo rectángulo a distinta escala.
	var factor: Vector2 = _texture.get_size() / size
	draw_texture_rect_region(_texture, shown,
		Rect2(shown.position * factor, shown.size * factor))


## Cortina provisional, por si algún día falta la capa.
func _draw_slats(shown: Rect2) -> void:
	var y: float = shown.position.y
	while y < shown.end.y:
		var height: float = minf(SLAT_HEIGHT, shown.end.y - y)
		var slat: Rect2 = Rect2(Vector2(shown.position.x, y), Vector2(shown.size.x, height))
		DrawKit.gradient_rect(self, slat, METAL_TOP, METAL_BOTTOM)
		draw_line(Vector2(slat.position.x, y + 0.5), Vector2(slat.end.x, y + 0.5), SLAT_EDGE, 1.0)
		draw_line(Vector2(slat.position.x, slat.end.y - 0.5),
			Vector2(slat.end.x, slat.end.y - 0.5), GROOVE, 1.0)
		y += SLAT_HEIGHT
	var bar_height: float = minf(BAR_HEIGHT, shown.size.y)
	DrawKit.gradient_rect(self, Rect2(Vector2(shown.position.x, shown.end.y - bar_height),
		Vector2(shown.size.x, bar_height)), BAR, BAR.darkened(0.5))
