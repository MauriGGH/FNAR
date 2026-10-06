extends Control

## El patch panel de la sala de servidores, dibujado por código: el rack, el
## panel de metal cepillado con sus 12 puertos RJ45, el switch con sus LEDs,
## los patch cords colgando con peso y la hoja de etiquetado pegada al lado.
## Los cables sueltos se arrastran a los puertos del switch; solo entra el que
## dice la hoja, y la relación cambia cada noche.

signal notice_requested(text: String, duration: float)

const PORT_COUNT: int = 12

# --- Geometría ---------------------------------------------------------------
const RACK: Rect2 = Rect2(120.0, 90.0, 640.0, 430.0)
const PANEL: Rect2 = Rect2(140.0, 120.0, 600.0, 80.0)
const SWITCH: Rect2 = Rect2(140.0, 380.0, 600.0, 90.0)
const PORT_SIZE: Vector2 = Vector2(34.0, 40.0)
const GI_PORT_SIZE: Vector2 = Vector2(34.0, 36.0)
const PORT_STEP: float = 46.0
const PORT_INSET: float = 30.0
const PANEL_PORT_TOP: float = 20.0
const SWITCH_PORT_TOP: float = 20.0
const LED_OFFSET: float = 64.0

const SHEET: Rect2 = Rect2(800.0, 150.0, 300.0, 320.0)
const SHEET_TILT: float = -0.045
const SHEET_HOVER_SCALE: float = 1.08

## Lo que cuelga un cable suelto, y cuánto se mece.
const LOOSE_LENGTH: float = 128.0
const SWAY_AMPLITUDE: float = 11.0
const SWAY_SPEED: float = 1.3
const CORD_WIDTH: float = 5.0
const CORD_SEGMENTS: int = 18
const PLUG_SIZE: Vector2 = Vector2(26.0, 20.0)

const CLICK_TIME: float = 0.3
const SPARK_TIME: float = 0.45
const SPARK_ARMS: int = 7

# --- Colores -----------------------------------------------------------------
const AMBIENT: Color = Color(0.035, 0.04, 0.045)
const RACK_COLOR: Color = Color(0.1, 0.11, 0.12)
const RACK_EDGE: Color = Color(0.2, 0.21, 0.23)
const RAIL_COLOR: Color = Color(0.15, 0.16, 0.18)
const SCREW_COLOR: Color = Color(0.3, 0.31, 0.33)
const PANEL_METAL: Color = Color(0.46, 0.47, 0.49)
const PANEL_BRUSH: Color = Color(0.52, 0.53, 0.55, 0.5)
const SWITCH_BODY: Color = Color(0.08, 0.085, 0.09)
const PORT_BODY: Color = Color(0.22, 0.23, 0.25)
const PORT_CAVITY: Color = Color(0.04, 0.045, 0.05)
const PORT_GOLD: Color = Color(0.78, 0.66, 0.3)
const PORT_EDGE: Color = Color(0.12, 0.13, 0.14)
const SILK: Color = Color(0.9, 0.91, 0.92)
const LED_ON: Color = Color(0.3, 0.95, 0.4)
const LED_OFF: Color = Color(0.1, 0.12, 0.11)
const GLOW_FREE: Color = Color(0.4, 0.9, 1.0)
const PAPER: Color = Color(0.88, 0.86, 0.78)
const PAPER_INK: Color = Color(0.12, 0.11, 0.1)
const TAPE: Color = Color(0.85, 0.84, 0.7, 0.45)
const SPARK_COLOR: Color = Color(0.95, 0.98, 1.0)
const HIGHLIGHT: Color = Color(1.0, 1.0, 1.0, 0.5)

var _model: PatchPanelModel = null
var _elapsed: float = 0.0
var _drag_camera: int = 0
var _drag_point: Vector2 = Vector2.ZERO
var _hover_camera: int = 0
var _hover_gi: int = -1
var _sheet_hovered: bool = false
var _click_anim: Dictionary = {}  # cámara -> tiempo restante
var _spark_anim: Dictionary = {}  # puerto gi -> tiempo restante


func _ready() -> void:
	_model = GameManager.patch_panel
	mouse_filter = Control.MOUSE_FILTER_STOP


# --- Geometría ----------------------------------------------------------------

func _pp_rect(port: int) -> Rect2:
	return Rect2(Vector2(PANEL.position.x + PORT_INSET + (port - 1) * PORT_STEP,
		PANEL.position.y + PANEL_PORT_TOP), PORT_SIZE)


func _gi_rect(port: int) -> Rect2:
	return Rect2(Vector2(SWITCH.position.x + PORT_INSET + (port - 1) * PORT_STEP,
		SWITCH.position.y + SWITCH_PORT_TOP), GI_PORT_SIZE)


func _led_center(port: int) -> Vector2:
	var rect: Rect2 = _gi_rect(port)
	return Vector2(rect.get_center().x, SWITCH.position.y + LED_OFFSET + 8.0)


## De donde sale el cable en el panel de arriba.
func _pp_tip(port: int) -> Vector2:
	var rect: Rect2 = _pp_rect(port)
	return Vector2(rect.get_center().x, rect.end.y + 4.0)


## Donde entra el cable en el switch.
func _gi_tip(port: int) -> Vector2:
	var rect: Rect2 = _gi_rect(port)
	return Vector2(rect.get_center().x, rect.position.y - 4.0)


## Punta de un cable suelto: cuelga y se mece.
func _loose_end(camera: int) -> Vector2:
	var tip: Vector2 = _pp_tip(_model.pp_of(camera))
	var phase: float = float(camera) * 0.9
	return tip + Vector2(sin(_elapsed * SWAY_SPEED + phase) * SWAY_AMPLITUDE, LOOSE_LENGTH)


func _plug_rect(center: Vector2) -> Rect2:
	return Rect2(center - PLUG_SIZE * 0.5, PLUG_SIZE)


func _gi_port_at(point: Vector2) -> int:
	for port: int in PORT_COUNT:
		if _gi_rect(port + 1).grow(6.0).has_point(point):
			return port + 1
	return -1


func _loose_camera_at(point: Vector2) -> int:
	for camera: int in _model.disconnected:
		if _plug_rect(_loose_end(camera)).grow(6.0).has_point(point):
			return camera
	return 0


# --- Interacción --------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		if _drag_camera != 0:
			_drag_point = motion.position
			_hover_gi = _gi_port_at(motion.position)
		else:
			_hover_camera = _loose_camera_at(motion.position)
			_hover_gi = -1
		_sheet_hovered = _sheet_bounds().has_point(motion.position)
		queue_redraw()
		return

	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if click.pressed:
		_drag_camera = _loose_camera_at(click.position)
		_drag_point = click.position
		if _drag_camera != 0:
			accept_event()
		return

	if _drag_camera == 0:
		return
	var camera: int = _drag_camera
	var target: int = _gi_port_at(click.position)
	_drag_camera = 0
	_hover_gi = -1
	_try_plug(camera, target)
	accept_event()


## Mete el cable: si es el puerto de la hoja entra; si no, chispa y se cae.
func _try_plug(camera: int, gi_port: int) -> void:
	if gi_port <= 0:
		queue_redraw()
		return
	if _model.try_connect(camera, gi_port):
		_click_anim[camera] = CLICK_TIME
		notice_requested.emit("[clic]", 1.0)
		notice_requested.emit("CAM %02d restablecida" % camera, 2.2)
	else:
		_spark_anim[gi_port] = SPARK_TIME
		notice_requested.emit("puerto incorrecto", 1.6)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	for camera: int in _click_anim.keys():
		_click_anim[camera] = _click_anim[camera] - delta
		if _click_anim[camera] <= 0.0:
			_click_anim.erase(camera)
	for port: int in _spark_anim.keys():
		_spark_anim[port] = _spark_anim[port] - delta
		if _spark_anim[port] <= 0.0:
			_spark_anim.erase(port)
	queue_redraw()


# --- Dibujo -------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), AMBIENT)
	_draw_rack()
	_draw_panel()
	_draw_switch()
	_draw_cords()
	_draw_sparks()
	_draw_sheet()


## El rack: cuerpo oscuro, rieles a los lados y tornillos por pares.
func _draw_rack() -> void:
	draw_rect(RACK.grow(4.0), RACK_EDGE)
	draw_rect(RACK, RACK_COLOR)
	for side: float in [RACK.position.x + 8.0, RACK.end.x - 20.0]:
		draw_rect(Rect2(Vector2(side, RACK.position.y + 8.0), Vector2(12.0, RACK.size.y - 16.0)), RAIL_COLOR)
		var holes: int = 14
		for i: int in holes:
			var y: float = RACK.position.y + 20.0 + i * (RACK.size.y - 40.0) / float(holes - 1)
			draw_circle(Vector2(side + 6.0, y), 2.0, PORT_CAVITY)


## El patch panel: lámina cepillada, serigrafía y los 12 RJ45.
func _draw_panel() -> void:
	draw_rect(PANEL, PANEL_METAL)
	draw_rect(PANEL, PORT_EDGE, false, 2.0)
	# Rayas finas horizontales: el metal cepillado.
	var y: float = PANEL.position.y + 4.0
	while y < PANEL.end.y - 2.0:
		draw_line(Vector2(PANEL.position.x + 3.0, y), Vector2(PANEL.end.x - 3.0, y), PANEL_BRUSH, 1.0)
		y += 3.0
	for corner: Vector2 in [Vector2(12.0, 12.0), Vector2(PANEL.size.x - 12.0, 12.0),
			Vector2(12.0, PANEL.size.y - 12.0), Vector2(PANEL.size.x - 12.0, PANEL.size.y - 12.0)]:
		draw_circle(PANEL.position + corner, 5.0, SCREW_COLOR)
		draw_circle(PANEL.position + corner, 2.0, PORT_CAVITY)

	var font: Font = get_theme_default_font()
	for port: int in PORT_COUNT:
		var rect: Rect2 = _pp_rect(port + 1)
		_draw_rj45(rect, false)
		_draw_centered(font, Vector2(rect.get_center().x, rect.end.y + 16.0),
			"PP-%02d" % (port + 1), 13, SILK)


## El switch: caja negra, sus 12 puertos y un LED por puerto.
func _draw_switch() -> void:
	draw_rect(SWITCH, SWITCH_BODY)
	draw_rect(SWITCH, PORT_EDGE, false, 2.0)
	draw_rect(Rect2(SWITCH.position + Vector2(3.0, 3.0), Vector2(SWITCH.size.x - 6.0, 2.0)), RACK_EDGE)

	var font: Font = get_theme_default_font()
	for port: int in PORT_COUNT:
		var number: int = port + 1
		var rect: Rect2 = _gi_rect(number)
		var free_glow: bool = _drag_camera != 0 and not _model.is_gi_connected(number)
		if free_glow:
			# Los puertos libres brillan apenas mientras arrastras.
			draw_rect(rect.grow(5.0), Color(GLOW_FREE.r, GLOW_FREE.g, GLOW_FREE.b, 0.16))
		_draw_rj45(rect, number == _hover_gi)
		_draw_centered(font, Vector2(rect.get_center().x, rect.end.y + 14.0),
			"Gi0/%d" % number, 12, SILK)
		_draw_led(number)


## El LED: verde con parpadeo irregular si hay tráfico, apagado sin cable.
func _draw_led(port: int) -> void:
	var center: Vector2 = _led_center(port)
	var lit: bool = false
	if _model.is_gi_connected(port):
		# Cada puerto con su ritmo, para que no parpadeen todos a la vez.
		var speed: float = 3.0 + float(port % 5) * 1.7
		var phase: float = float(port) * 1.37
		lit = sin(_elapsed * speed + phase) + sin(_elapsed * speed * 0.37 + phase * 2.0) > -0.4
	if lit:
		draw_circle(center, 9.0, Color(LED_ON.r, LED_ON.g, LED_ON.b, 0.18))
		draw_circle(center, 5.5, Color(LED_ON.r, LED_ON.g, LED_ON.b, 0.3))
	draw_circle(center, 3.4, LED_ON if lit else LED_OFF)


## Un RJ45 con su forma: cuerpo, muesca del clip, cavidad y contactos.
func _draw_rj45(rect: Rect2, highlighted: bool) -> void:
	draw_rect(rect, PORT_BODY)
	draw_rect(rect, PORT_EDGE, false, 1.0)
	var cavity: Rect2 = Rect2(rect.position + Vector2(4.0, 4.0), rect.size - Vector2(8.0, 12.0))
	draw_rect(cavity, PORT_CAVITY)
	# La muesca del clip, abajo al centro.
	draw_rect(Rect2(Vector2(rect.position.x + rect.size.x * 0.33, cavity.end.y),
		Vector2(rect.size.x * 0.34, 8.0)), PORT_CAVITY)
	for i: int in 8:
		var x: float = cavity.position.x + 2.0 + i * (cavity.size.x - 4.0) / 8.0
		draw_rect(Rect2(Vector2(x, cavity.position.y + 2.0), Vector2(1.5, cavity.size.y * 0.5)), PORT_GOLD)
	if highlighted:
		draw_rect(rect.grow(2.0), HIGHLIGHT, false, 2.0)


## Los cables: conectados van de panel a switch; los sueltos cuelgan y se mecen.
func _draw_cords() -> void:
	for camera: int in range(1, PORT_COUNT + 1):
		var color: Color = _model.color_of(camera)
		var from_point: Vector2 = _pp_tip(_model.pp_of(camera))
		if not _model.is_camera_down(camera):
			var to_point: Vector2 = _gi_tip(_model.gi_of(camera))
			# Al entrar, el conector baja los últimos píxeles de golpe.
			var click: float = float(_click_anim.get(camera, 0.0))
			to_point.y -= click / CLICK_TIME * 12.0
			var span: float = absf(to_point.x - from_point.x)
			_draw_cord_curve(from_point, to_point, 46.0 + span * 0.22, color)
			if click > 0.0:
				draw_circle(to_point, 14.0 * (click / CLICK_TIME), Color(1.0, 1.0, 1.0, 0.45))
			continue

		var end_point: Vector2 = _drag_point if camera == _drag_camera else _loose_end(camera)
		# Cuanto más corto el tramo, más panza: así se siente que sobra cable.
		var slack: float = maxf(LOOSE_LENGTH - from_point.distance_to(end_point), 0.0)
		_draw_cord_curve(from_point, end_point, 26.0 + slack * 0.55, color)
		_draw_plug(end_point, color, camera == _hover_camera or camera == _drag_camera)
		_draw_cord_label(end_point, camera)


func _draw_cord_curve(from_point: Vector2, to_point: Vector2, sag: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var control: Vector2 = (from_point + to_point) * 0.5 + Vector2(0.0, sag)
	for i: int in CORD_SEGMENTS + 1:
		var t: float = float(i) / float(CORD_SEGMENTS)
		var inverse: float = 1.0 - t
		points.append(from_point * inverse * inverse + control * 2.0 * inverse * t + to_point * t * t)
	draw_polyline(points, PORT_CAVITY, CORD_WIDTH + 2.0, true)
	draw_polyline(points, color, CORD_WIDTH, true)


## El conector del extremo suelto.
func _draw_plug(center: Vector2, color: Color, highlighted: bool) -> void:
	var rect: Rect2 = _plug_rect(center)
	draw_rect(rect, color.darkened(0.35))
	draw_rect(rect, PORT_CAVITY, false, 1.0)
	draw_rect(Rect2(rect.position + Vector2(5.0, -4.0), Vector2(rect.size.x - 10.0, 5.0)), color.lightened(0.2))
	if highlighted:
		draw_rect(rect.grow(3.0), HIGHLIGHT, false, 2.0)


## La etiquetita de papel que cuelga del cable suelto.
func _draw_cord_label(center: Vector2, camera: int) -> void:
	var rect: Rect2 = Rect2(center + Vector2(14.0, 2.0), Vector2(56.0, 20.0))
	draw_rect(rect, PAPER)
	draw_rect(rect, PAPER_INK, false, 1.0)
	_draw_centered(get_theme_default_font(), rect.get_center() + Vector2(0.0, 5.0),
		"CAM %02d" % camera, 13, PAPER_INK)


## La chispa del puerto equivocado.
func _draw_sparks() -> void:
	for port: int in _spark_anim:
		var left: float = float(_spark_anim[port])
		var center: Vector2 = _gi_tip(port)
		var fade: float = left / SPARK_TIME
		for i: int in SPARK_ARMS:
			var angle: float = TAU * float(i) / float(SPARK_ARMS) + left * 9.0
			var length: float = 10.0 + (1.0 - fade) * 22.0
			draw_line(center, center + Vector2.from_angle(angle) * length,
				Color(SPARK_COLOR.r, SPARK_COLOR.g, SPARK_COLOR.b, fade), 2.0)
		draw_circle(center, 5.0 * fade, Color(SPARK_COLOR.r, SPARK_COLOR.g, SPARK_COLOR.b, fade))


func _sheet_bounds() -> Rect2:
	return SHEET.grow(10.0)


## La hoja de etiquetado: papel inclinado, pegado con cinta, con su tabla.
## Al pasar el mouse se agranda un poco para poder leerla.
func _draw_sheet() -> void:
	var scale: float = SHEET_HOVER_SCALE if _sheet_hovered else 1.0
	var center: Vector2 = SHEET.get_center()
	draw_set_transform(center, SHEET_TILT, Vector2(scale, scale))
	var sheet: Rect2 = Rect2(-SHEET.size * 0.5, SHEET.size)

	draw_rect(sheet.grow(2.0), Color(0.0, 0.0, 0.0, 0.35))
	draw_rect(sheet, PAPER)
	# Arrugas: unas rayas diagonales apenas visibles.
	for i: int in 5:
		var y: float = sheet.position.y + 30.0 + i * 58.0
		draw_line(Vector2(sheet.position.x + 6.0, y),
			Vector2(sheet.end.x - 6.0, y + 7.0), Color(0.0, 0.0, 0.0, 0.05), 3.0)
	for corner: Vector2 in [sheet.position, Vector2(sheet.end.x, sheet.position.y),
			Vector2(sheet.position.x, sheet.end.y), sheet.end]:
		draw_rect(Rect2(corner - Vector2(16.0, 7.0), Vector2(32.0, 14.0)), TAPE)

	var font: Font = get_theme_default_font()
	_draw_centered(font, Vector2(0.0, sheet.position.y + 26.0), "ETIQUETADO DE CAMARAS", 16, PAPER_INK)
	draw_line(Vector2(sheet.position.x + 14.0, sheet.position.y + 34.0),
		Vector2(sheet.end.x - 14.0, sheet.position.y + 34.0), PAPER_INK, 1.0)
	for i: int in PORT_COUNT:
		var camera: int = i + 1
		var y: float = sheet.position.y + 54.0 + i * 21.0
		# La fuente no trae flecha, así que la tabla usa ->.
		draw_string(font, Vector2(sheet.position.x + 20.0, y),
			"CAM %02d  ->  PP-%02d  ->  Gi0/%d" % [camera, _model.pp_of(camera), _model.gi_of(camera)],
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, PAPER_INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_centered(font: Font, center: Vector2, text: String, font_size: int, color: Color) -> void:
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	draw_string(font, Vector2(center.x - width * 0.5, center.y), text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
