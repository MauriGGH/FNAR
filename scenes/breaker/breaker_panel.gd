extends Control

## El tablero del breaker, de cerca. Sistema híbrido: si existen las imágenes
## breaker_arriba.png y breaker_abajo.png, se usan de fondo y encima solo se
## dibujan los focos con su resplandor. Si no, se dibuja el tablero completo,
## con el mismo acabado (degradados, sombras suaves, sin contornos negros).
## La palanca se arrastra hacia abajo y pesa: sigue al mouse con retraso y, si
## la sueltas antes de llegar, se regresa sola.

signal closed()
## Para el "[clac]" y el temblor, que los dispara la escena de la noche.
signal lever_pulled()

const IMAGE_UP_PATH: String = "res://assets/art/office/breaker_arriba.png"
const IMAGE_DOWN_PATH: String = "res://assets/art/office/breaker_abajo.png"

const PLATE: Rect2 = Rect2(380.0, 56.0, 460.0, 520.0)

# Con imágenes de fondo, estas tres cosas hay que ajustarlas a la foto:
# dónde se agarra la palanca y dónde quedan los dos focos.
const IMAGE_LEVER_AREA: Rect2 = Rect2(470.0, 180.0, 220.0, 300.0)
const IMAGE_GREEN_LIGHT: Vector2 = Vector2(468.0, 520.0)
const IMAGE_RED_LIGHT: Vector2 = Vector2(690.0, 520.0)
## A partir de este punto del recorrido se cambia a la imagen de abajo.
const IMAGE_SWITCH_AT: float = 0.5

# Qué tanto sigue la palanca al mouse (bajo = pesada) y qué tan rápido vuelve.
const LEVER_FOLLOW: float = 7.0
const LEVER_RETURN: float = 2.6
## A partir de aquí se considera que llegó abajo.
const TRIGGER_AT: float = 0.96

const SHAKE_TIME: float = 0.32
const SHAKE_STRENGTH: float = 9.0

# Geometría del carril y del mango, en coordenadas de la lámina.
const TRACK: Rect2 = Rect2(170.0, 150.0, 120.0, 256.0)
const HANDLE_SIZE: Vector2 = Vector2(104.0, 76.0)
const HANDLE_TOP: float = 158.0
const HANDLE_TRAVEL: float = 164.0

const LIGHT_RADIUS: float = 15.0
const GREEN_LIGHT: Vector2 = Vector2(130.0, 448.0)
const RED_LIGHT: Vector2 = Vector2(330.0, 448.0)

# Colores de la lámina y las piezas.
const BACKDROP: Color = Color(0.02, 0.02, 0.03, 0.78)
const PLATE_COLOR: Color = Color(0.46, 0.47, 0.48)
const PLATE_EDGE_LIGHT: Color = Color(0.62, 0.63, 0.64)
const PLATE_EDGE_DARK: Color = Color(0.24, 0.25, 0.26)
const RECESS_COLOR: Color = Color(0.17, 0.18, 0.19)
const SCREW_COLOR: Color = Color(0.33, 0.34, 0.35)
const SCREW_SLOT: Color = Color(0.14, 0.15, 0.16)
const HANDLE_COLOR: Color = Color(0.58, 0.16, 0.13)
const HANDLE_TOP_COLOR: Color = Color(0.72, 0.24, 0.2)
const HANDLE_GRIP: Color = Color(0.3, 0.08, 0.07)
const WARNING_YELLOW: Color = Color(0.93, 0.78, 0.12)
const INK: Color = Color(0.09, 0.08, 0.05)
const ENGRAVED: Color = Color(0.2, 0.21, 0.22)
const LAMP_OFF: Color = Color(0.13, 0.14, 0.15)
const LAMP_GREEN: Color = Color(0.3, 0.95, 0.42)
const LAMP_RED: Color = Color(0.98, 0.26, 0.2)

var is_open: bool = false

var _lever: float = 0.0  # 0 arriba, 1 abajo
var _dragging: bool = false
var _drag_target: float = 0.0
var _shake_left: float = 0.0
var _shake_offset: Vector2 = Vector2.ZERO
var _blink_elapsed: float = 0.0
var _use_images: bool = false
var _texture_up: Texture2D = null
var _texture_down: Texture2D = null
## Con qué imagen se está viendo ahora, para saber cuándo cambiar y sacudir.
var _showing_down: bool = false

@onready var background: TextureRect = $Background


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_load_images()


## Si están las dos imágenes, el tablero pasa a modo foto.
func _load_images() -> void:
	if not ResourceLoader.exists(IMAGE_UP_PATH) or not ResourceLoader.exists(IMAGE_DOWN_PATH):
		background.visible = false
		return
	_texture_up = load(IMAGE_UP_PATH) as Texture2D
	_texture_down = load(IMAGE_DOWN_PATH) as Texture2D
	_use_images = _texture_up != null and _texture_down != null
	background.visible = _use_images
	if _use_images:
		background.texture = _texture_up


func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	_lever = 1.0 if PowerManager.is_blackout else 0.0
	_dragging = false
	_refresh_image(true)
	queue_redraw()


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	_dragging = false
	closed.emit()


## Temblor de un instante, cuando la palanca llega abajo.
func shake() -> void:
	_shake_left = SHAKE_TIME


# --- Entrada ------------------------------------------------------------------

## Escape y clic derecho regresan a la vista normal. Va en _input porque este
## Control está en STOP y se quedaría con los botones del mouse.
func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		close()
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT:
		if click.pressed:
			var grab: Rect2 = IMAGE_LEVER_AREA if _use_images else _handle_rect()
			_dragging = grab.has_point(click.position)
			if _dragging:
				_drag_target = _lever
		else:
			_dragging = false
		accept_event()
		return

	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null or not _dragging:
		return
	# La palanca apunta a donde está el mouse, pero llega con retraso.
	if _use_images:
		_drag_target = clampf((motion.position.y - IMAGE_LEVER_AREA.position.y) / IMAGE_LEVER_AREA.size.y, 0.0, 1.0)
		return
	var local_y: float = motion.position.y - PLATE.position.y
	_drag_target = clampf((local_y - HANDLE_TOP - HANDLE_SIZE.y * 0.5) / HANDLE_TRAVEL, 0.0, 1.0)


func _process(delta: float) -> void:
	_blink_elapsed += delta
	_update_shake(delta)

	var target: float = 0.0
	if PowerManager.is_blackout:
		target = 1.0  # Se queda abajo mientras no hay corriente.
	elif _dragging:
		target = _drag_target
	var speed: float = LEVER_FOLLOW if _dragging else LEVER_RETURN
	_lever = lerpf(_lever, target, 1.0 - exp(-delta * speed))

	_refresh_image(false)
	if _dragging and not PowerManager.is_blackout and _lever >= TRIGGER_AT:
		_pull_down()
	queue_redraw()


## Al pasar la mitad del recorrido se cambia de imagen, con su sacudón.
func _refresh_image(silent: bool) -> void:
	if not _use_images:
		return
	var should_show_down: bool = _lever >= IMAGE_SWITCH_AT
	if should_show_down == _showing_down:
		return
	_showing_down = should_show_down
	background.texture = _texture_down if _showing_down else _texture_up
	if not silent:
		shake()


func _update_shake(delta: float) -> void:
	if _shake_left <= 0.0:
		_shake_offset = Vector2.ZERO
		return
	_shake_left = maxf(_shake_left - delta, 0.0)
	var strength: float = SHAKE_STRENGTH * (_shake_left / SHAKE_TIME)
	_shake_offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))


func _pull_down() -> void:
	_dragging = false
	if not PowerManager.cut_power():
		return  # Todavía en espera: la palanca se regresa sola.
	shake()
	lever_pulled.emit()


func _handle_rect() -> Rect2:
	var y: float = PLATE.position.y + HANDLE_TOP + HANDLE_TRAVEL * _lever
	return Rect2(Vector2(PLATE.position.x + TRACK.position.x + (TRACK.size.x - HANDLE_SIZE.x) * 0.5, y), HANDLE_SIZE)


# --- Dibujo -------------------------------------------------------------------

func _draw() -> void:
	# Con imagen de fondo solo van encima los focos y el estado.
	if _use_images:
		_draw_lights_at(IMAGE_GREEN_LIGHT, IMAGE_RED_LIGHT)
		_draw_status(Rect2(PLATE.position + _shake_offset, PLATE.size))
		return

	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP)
	var plate: Rect2 = Rect2(PLATE.position + _shake_offset, PLATE.size)
	DrawKit.rect_shadow(self, plate, Vector2(6.0, 10.0))
	_draw_plate(plate)
	_draw_warning_label(plate)
	_draw_track(plate)
	_draw_handle()
	_draw_lights_at(plate.position + GREEN_LIGHT, plate.position + RED_LIGHT)
	_draw_status(plate)


## La lámina: degradado de arriba abajo, borde suave y los cuatro tornillos.
func _draw_plate(plate: Rect2) -> void:
	draw_style_box(_box(PLATE_EDGE_DARK, 8, PLATE_EDGE_DARK, 0), plate.grow(3.0))
	DrawKit.gradient_rect(self, plate, PLATE_EDGE_LIGHT, PLATE_COLOR.darkened(0.18))
	DrawKit.soft_outline(self, plate, PLATE_EDGE_LIGHT)
	# Un brillo largo arriba y una sombra abajo: así se lee como lámina.
	DrawKit.gradient_rect(self, Rect2(plate.position + Vector2(8.0, 8.0), Vector2(plate.size.x - 16.0, 26.0)),
		Color(1.0, 1.0, 1.0, 0.07), Color(1.0, 1.0, 1.0, 0.0))
	DrawKit.gradient_rect(self, Rect2(plate.position + Vector2(8.0, plate.size.y - 34.0), Vector2(plate.size.x - 16.0, 26.0)),
		Color(0.0, 0.0, 0.0, 0.0), Color(0.0, 0.0, 0.0, 0.14))
	for corner: Vector2 in [Vector2(24.0, 24.0), Vector2(plate.size.x - 24.0, 24.0),
			Vector2(24.0, plate.size.y - 24.0), Vector2(plate.size.x - 24.0, plate.size.y - 24.0)]:
		_draw_screw(plate.position + corner)


func _draw_screw(center: Vector2) -> void:
	draw_circle(center, 10.0, PLATE_EDGE_DARK)
	draw_circle(center, 8.0, SCREW_COLOR)
	# La ranura, girada distinto en cada tornillo para que no se vean clonados.
	var angle: float = float(int(center.x + center.y)) * 0.7
	var arm: Vector2 = Vector2(cos(angle), sin(angle)) * 5.5
	draw_line(center - arm, center + arm, SCREW_SLOT, 2.0)


## Etiqueta amarilla de peligro, con su rayo.
func _draw_warning_label(plate: Rect2) -> void:
	var label: Rect2 = Rect2(plate.position + Vector2(120.0, 44.0), Vector2(220.0, 80.0))
	draw_style_box(_box(WARNING_YELLOW, 4, INK, 2), label)

	# Triángulo con el rayo dentro, a la izquierda.
	var triangle_center: Vector2 = label.position + Vector2(40.0, 40.0)
	draw_polyline(PackedVector2Array([
		triangle_center + Vector2(0.0, -24.0),
		triangle_center + Vector2(22.0, 16.0),
		triangle_center + Vector2(-22.0, 16.0),
		triangle_center + Vector2(0.0, -24.0),
	]), INK, 3.0, true)
	draw_colored_polygon(PackedVector2Array([
		triangle_center + Vector2(3.0, -15.0),
		triangle_center + Vector2(-7.0, 1.0),
		triangle_center + Vector2(-1.0, 1.0),
		triangle_center + Vector2(-5.0, 12.0),
		triangle_center + Vector2(8.0, -4.0),
		triangle_center + Vector2(1.0, -4.0),
	]), INK)

	var font: Font = get_theme_default_font()
	draw_string(font, label.position + Vector2(74.0, 34.0), "PELIGRO", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, INK)
	draw_string(font, label.position + Vector2(74.0, 60.0), "ALTA TENSION", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, INK)


## El carril hundido donde corre la palanca, con sus marcas ON y OFF.
func _draw_track(plate: Rect2) -> void:
	var track: Rect2 = Rect2(plate.position + TRACK.position, TRACK.size)
	draw_style_box(_box(RECESS_COLOR, 5, PLATE_EDGE_DARK, 2), track)
	draw_rect(Rect2(track.position + Vector2(2.0, 2.0), Vector2(track.size.x - 4.0, 3.0)), Color(0.1, 0.1, 0.11))

	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(track.position.x - 52.0, track.position.y + 22.0), "ON", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, ENGRAVED)
	draw_string(font, Vector2(track.position.x - 56.0, track.end.y - 8.0), "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, ENGRAVED)
	# Muescas del recorrido.
	for i: int in 5:
		var y: float = track.position.y + 24.0 + i * (track.size.y - 48.0) / 4.0
		draw_line(Vector2(track.end.x + 6.0, y), Vector2(track.end.x + 18.0, y), ENGRAVED, 2.0)


## El mango: sombra propia, degradado y tres rayas de agarre hundidas.
func _draw_handle() -> void:
	var handle: Rect2 = _handle_rect()
	handle.position += _shake_offset
	DrawKit.rect_shadow(self, handle)
	draw_style_box(_box(HANDLE_COLOR, 6, HANDLE_GRIP, 1), handle)
	DrawKit.gradient_rect(self, handle.grow(-2.0), HANDLE_TOP_COLOR, HANDLE_COLOR.darkened(0.3))
	for i: int in 3:
		var groove: Rect2 = Rect2(handle.position + Vector2(16.0, 28.0 + i * 12.0),
			Vector2(handle.size.x - 32.0, 5.0))
		DrawKit.gradient_rect(self, groove, HANDLE_GRIP, Color(1.0, 1.0, 1.0, 0.06))


## Los dos focos, con resplandor difuso y su reflejo sobre el metal.
## El verde late apenas, para que no se vea como una calcomanía.
func _draw_lights_at(green_center: Vector2, red_center: Vector2) -> void:
	var waiting: bool = PowerManager.cooldown_progress() > 0.0
	var green: float = 0.0 if PowerManager.is_blackout else 0.86 + 0.14 * sin(_blink_elapsed * 2.1)
	var red: float = 0.0
	if PowerManager.is_blackout:
		red = 1.0
	elif waiting:
		# En espera parpadea; cortada, se queda fijo.
		red = 1.0 if fmod(_blink_elapsed, 0.6) < 0.3 else 0.08

	_draw_lamp(green_center, LAMP_GREEN, green)
	_draw_lamp(red_center, LAMP_RED, red)

	if _use_images:
		return
	var font: Font = get_theme_default_font()
	_draw_centered(font, green_center + Vector2(0.0, 40.0) - _shake_offset, "ENERGIA", 18, ENGRAVED)
	_draw_centered(font, red_center + Vector2(0.0, 40.0) - _shake_offset, "CORTE", 18, ENGRAVED)


func _draw_lamp(center: Vector2, color: Color, intensity: float) -> void:
	center += _shake_offset
	DrawKit.led_reflection(self, center + Vector2(0.0, LIGHT_RADIUS + 2.0),
		Vector2(LIGHT_RADIUS * 5.0, LIGHT_RADIUS * 2.6), color, intensity, false)
	DrawKit.led(self, center, LIGHT_RADIUS, color, intensity)


## La línea de estado: deja ver la cuenta de los 3 s y la de los 10 s.
func _draw_status(plate: Rect2) -> void:
	var font: Font = get_theme_default_font()
	var text: String = "LISTO"
	var color: Color = ENGRAVED
	if PowerManager.is_blackout:
		text = "SIN CORRIENTE  %.1f s" % (PowerManager.blackout_progress() * NightConfig.BLACKOUT_TIME)
		color = LAMP_RED
	elif PowerManager.cooldown_progress() > 0.0:
		text = "ESPERA  %.1f s" % (PowerManager.cooldown_progress() * NightConfig.BREAKER_COOLDOWN)
		color = WARNING_YELLOW
	_draw_centered(font, plate.position + Vector2(plate.size.x * 0.5, 498.0), text, 20, color)

	# Barra de la espera, para que los 10 s se vean y no solo se cuenten.
	var bar: Rect2 = Rect2(plate.position + Vector2(90.0, 476.0), Vector2(280.0, 8.0))
	draw_rect(bar, RECESS_COLOR)
	var filled: float = PowerManager.cooldown_progress()
	if filled > 0.0:
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * filled, bar.size.y)), WARNING_YELLOW)
	draw_rect(bar, PLATE_EDGE_DARK, false, 1.0)
	_draw_centered(font, plate.position + Vector2(plate.size.x * 0.5, 148.0),
		"TABLERO PRINCIPAL", 17, ENGRAVED)


func _draw_centered(font: Font, center: Vector2, text: String, font_size: int, color: Color) -> void:
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	draw_string(font, Vector2(center.x - width * 0.5, center.y) + _shake_offset,
		text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)


func _box(color: Color, radius: int, border_color: Color, border_width: int) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.set_border_width_all(border_width)
	box.border_color = border_color
	return box
