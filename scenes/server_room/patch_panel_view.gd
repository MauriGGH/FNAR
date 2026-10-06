extends Control

## El patch panel de la sala de servidores. Sistema híbrido:
##  - Si existe sala_servidores.png, es el fondo y encima van solo los cables,
##    los conectores, los LEDs y la hoja. Las posiciones de los puertos salen
##    de data/sala_servidores_zonas.json.
##  - Si no existe, se dibuja también el rack, el panel y el switch.
## En los dos casos el acabado es el mismo: degradados, sombras suaves, cables
## con volumen y LEDs con resplandor difuso. Nada de contornos negros.
##
## Formato esperado del JSON (coordenadas normalizadas de 0 a 1):
##   {"pp_ports": [{"x":..,"y":..,"w":..,"h":..}, ... 12],
##    "gi_ports": [... 12],
##    "sheet": {"x":..,"y":..,"w":..,"h":..}}

signal notice_requested(text: String, duration: float)

const PORT_COUNT: int = 12

# Sin extensión: valen png, jpg o jpeg.
const BACKGROUND_PATH: String = "res://assets/art/office/sala_servidores"
const PLUG_TEXTURE_PATH: String = "res://assets/art/office/rj45"
const ZONES_PATH: String = "res://data/sala_servidores_zonas.json"

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
## Grosor real de un patch cord, como pediste.
const CORD_WIDTH: float = 11.0
const CORD_SEGMENTS: int = 20
const PLUG_SIZE: Vector2 = Vector2(30.0, 23.0)

const CLICK_TIME: float = 0.3
const SPARK_TIME: float = 0.45
const SPARK_ARMS: int = 7

# --- Colores -----------------------------------------------------------------
# --- Colores -----------------------------------------------------------------
# Todos desaturados, para que peguen con las fotos de la oficina.
const AMBIENT: Color = Color(0.045, 0.048, 0.055)
const RACK_TOP: Color = Color(0.13, 0.135, 0.145)
const RACK_BOTTOM: Color = Color(0.08, 0.085, 0.092)
const RACK_EDGE: Color = Color(0.19, 0.2, 0.21)
const RAIL_TOP: Color = Color(0.17, 0.175, 0.185)
const RAIL_BOTTOM: Color = Color(0.11, 0.115, 0.125)
const SCREW_COLOR: Color = Color(0.28, 0.285, 0.3)
const PANEL_TOP: Color = Color(0.42, 0.43, 0.45)
const PANEL_BOTTOM: Color = Color(0.3, 0.31, 0.33)
const PANEL_BRUSH: Color = Color(1.0, 1.0, 1.0, 0.045)
const SWITCH_TOP: Color = Color(0.1, 0.103, 0.11)
const SWITCH_BOTTOM: Color = Color(0.065, 0.068, 0.073)
const PORT_BODY: Color = Color(0.2, 0.21, 0.22)
const PORT_CAVITY: Color = Color(0.05, 0.055, 0.06)
const PORT_GOLD: Color = Color(0.58, 0.5, 0.3)
const PORT_EDGE: Color = Color(0.26, 0.27, 0.28)
const SILK: Color = Color(0.76, 0.77, 0.78)
const LED_ON: Color = Color(0.42, 0.82, 0.46)
const GLOW_FREE: Color = Color(0.45, 0.72, 0.78)
const PAPER: Color = Color(0.82, 0.8, 0.74)
const PAPER_SHADE: Color = Color(0.72, 0.7, 0.64)
const PAPER_INK: Color = Color(0.21, 0.2, 0.19)
const TAPE: Color = Color(0.8, 0.79, 0.7, 0.3)
const SPARK_COLOR: Color = Color(0.88, 0.92, 0.95)
const HIGHLIGHT: Color = Color(1.0, 1.0, 1.0, 0.32)

var _model: PatchPanelModel = null
var _has_background: bool = false
var _plug_texture: Texture2D = null
var _pp_rects: Array[Rect2] = []
var _gi_rects: Array[Rect2] = []
var _sheet_rect: Rect2 = SHEET
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
	_has_background = GameAssets.has_texture(BACKGROUND_PATH)
	_plug_texture = GameAssets.load_texture(PLUG_TEXTURE_PATH)
	_load_zones()
	resized.connect(_load_zones)


## Toma las posiciones de los puertos del JSON si existe; si no, las calcula
## con la geometría del tablero dibujado.
func _load_zones() -> void:
	_pp_rects.clear()
	_gi_rects.clear()
	_sheet_rect = SHEET

	var zones: Dictionary = _read_zones()
	if zones.is_empty():
		for port: int in PORT_COUNT:
			_pp_rects.append(Rect2(Vector2(PANEL.position.x + PORT_INSET + port * PORT_STEP,
				PANEL.position.y + PANEL_PORT_TOP), PORT_SIZE))
			_gi_rects.append(Rect2(Vector2(SWITCH.position.x + PORT_INSET + port * PORT_STEP,
				SWITCH.position.y + SWITCH_PORT_TOP), GI_PORT_SIZE))
		return

	_pp_rects = _rects_from(zones.get("pp_ports", []), PORT_SIZE)
	_gi_rects = _rects_from(zones.get("gi_ports", []), GI_PORT_SIZE)
	var sheet: Dictionary = zones.get("sheet", {})
	if not sheet.is_empty():
		_sheet_rect = Rect2(
			Vector2(float(sheet.get("x", 0.0)) * size.x, float(sheet.get("y", 0.0)) * size.y),
			Vector2(float(sheet.get("w", 0.0)) * size.x, float(sheet.get("h", 0.0)) * size.y))


func _read_zones() -> Dictionary:
	if not ResourceLoader.exists(ZONES_PATH):
		return {}
	var file: FileAccess = FileAccess.open(ZONES_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Las zonas de la sala no tienen un JSON válido: " + ZONES_PATH)
		return {}
	return parsed


## Rectángulos normalizados a píxeles, completando lo que falte.
func _rects_from(list: Array, fallback_size: Vector2) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for i: int in PORT_COUNT:
		if i >= list.size():
			rects.append(Rect2(Vector2.ZERO, fallback_size))
			continue
		var entry: Dictionary = list[i]
		var width: float = float(entry.get("w", 0.0)) * size.x
		var height: float = float(entry.get("h", 0.0)) * size.y
		rects.append(Rect2(
			Vector2(float(entry.get("x", 0.0)) * size.x, float(entry.get("y", 0.0)) * size.y),
			Vector2(width if width > 0.0 else fallback_size.x, height if height > 0.0 else fallback_size.y)))
	return rects


# --- Geometría ----------------------------------------------------------------

func _pp_rect(port: int) -> Rect2:
	return _pp_rects[clampi(port - 1, 0, _pp_rects.size() - 1)]


func _gi_rect(port: int) -> Rect2:
	return _gi_rects[clampi(port - 1, 0, _gi_rects.size() - 1)]


## El LED va justo debajo de su puerto del switch.
func _led_center(port: int) -> Vector2:
	var rect: Rect2 = _gi_rect(port)
	return Vector2(rect.get_center().x, rect.end.y + 16.0)


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
	# Con foto de fondo solo van encima los cables, los conectores, los LEDs
	# y la hoja; el rack y el switch ya están en la imagen.
	if not _has_background:
		draw_rect(Rect2(Vector2.ZERO, size), AMBIENT)
		_draw_rack()
		_draw_panel()
		_draw_switch_body()
	_draw_ports()
	_draw_cords()
	_draw_sparks()
	_draw_sheet()


## El rack: degradado de arriba abajo, rieles con volumen y sus perforaciones.
func _draw_rack() -> void:
	DrawKit.rect_shadow(self, RACK, Vector2(6.0, 10.0))
	DrawKit.gradient_rect(self, RACK.grow(4.0), RACK_EDGE, RACK_EDGE.darkened(0.4))
	DrawKit.gradient_rect(self, RACK, RACK_TOP, RACK_BOTTOM)
	for side: float in [RACK.position.x + 8.0, RACK.end.x - 20.0]:
		var rail: Rect2 = Rect2(Vector2(side, RACK.position.y + 8.0), Vector2(12.0, RACK.size.y - 16.0))
		DrawKit.gradient_rect(self, rail, RAIL_TOP, RAIL_BOTTOM)
		var holes: int = 14
		for i: int in holes:
			var y: float = RACK.position.y + 20.0 + i * (RACK.size.y - 40.0) / float(holes - 1)
			draw_circle(Vector2(side + 6.0, y), 2.0, PORT_CAVITY)


## El patch panel: lámina con degradado, cepillado fino y sus tornillos.
func _draw_panel() -> void:
	DrawKit.rect_shadow(self, PANEL)
	DrawKit.gradient_rect(self, PANEL, PANEL_TOP, PANEL_BOTTOM)
	var y: float = PANEL.position.y + 4.0
	while y < PANEL.end.y - 2.0:
		draw_line(Vector2(PANEL.position.x + 3.0, y), Vector2(PANEL.end.x - 3.0, y), PANEL_BRUSH, 1.0)
		y += 3.0
	DrawKit.soft_outline(self, PANEL, PANEL_TOP.lightened(0.3))
	for corner: Vector2 in [Vector2(12.0, 12.0), Vector2(PANEL.size.x - 12.0, 12.0),
			Vector2(12.0, PANEL.size.y - 12.0), Vector2(PANEL.size.x - 12.0, PANEL.size.y - 12.0)]:
		_draw_screw(PANEL.position + corner)


func _draw_screw(center: Vector2) -> void:
	draw_circle(center + Vector2(1.0, 2.0), 5.5, Color(0.0, 0.0, 0.02, 0.25))
	draw_circle(center, 5.0, SCREW_COLOR)
	draw_circle(center, 4.0, SCREW_COLOR.darkened(0.25))
	draw_circle(center - Vector2(1.2, 1.4), 1.6, Color(1.0, 1.0, 1.0, 0.18))


## El switch: caja oscura con degradado y una ceja clara arriba.
func _draw_switch_body() -> void:
	DrawKit.rect_shadow(self, SWITCH)
	DrawKit.gradient_rect(self, SWITCH, SWITCH_TOP, SWITCH_BOTTOM)
	DrawKit.gradient_rect(self, Rect2(SWITCH.position + Vector2(3.0, 3.0), Vector2(SWITCH.size.x - 6.0, 8.0)),
		Color(1.0, 1.0, 1.0, 0.05), Color(1.0, 1.0, 1.0, 0.0))
	DrawKit.soft_outline(self, SWITCH, RACK_EDGE)


## Los 24 puertos con su serigrafía, más los LEDs del switch.
func _draw_ports() -> void:
	var font: Font = get_theme_default_font()
	for port: int in PORT_COUNT:
		var number: int = port + 1
		var pp: Rect2 = _pp_rect(number)
		if not _has_background:
			_draw_rj45(pp, false)
			_draw_centered(font, Vector2(pp.get_center().x, pp.end.y + 16.0), "PP-%02d" % number, 13, SILK)

		var gi: Rect2 = _gi_rect(number)
		var free_glow: bool = _drag_camera != 0 and not _model.is_gi_connected(number)
		if free_glow:
			# Los puertos libres brillan apenas mientras arrastras.
			DrawKit.gradient_rect(self, gi.grow(7.0),
				Color(GLOW_FREE.r, GLOW_FREE.g, GLOW_FREE.b, 0.16),
				Color(GLOW_FREE.r, GLOW_FREE.g, GLOW_FREE.b, 0.04))
		if not _has_background:
			_draw_rj45(gi, number == _hover_gi)
			_draw_centered(font, Vector2(gi.get_center().x, gi.end.y + 14.0), "Gi0/%d" % number, 12, SILK)
		elif number == _hover_gi:
			DrawKit.soft_outline(self, gi.grow(2.0), HIGHLIGHT)
		_draw_led(number)


## El LED: parpadeo irregular, resplandor difuso y su reflejo en el metal.
func _draw_led(port: int) -> void:
	var center: Vector2 = _led_center(port)
	var intensity: float = 0.0
	if _model.is_gi_connected(port):
		# Dos senos de frecuencias distintas: el ritmo sale irregular, como
		# tráfico de verdad, y nunca parpadean todos a la vez.
		var speed: float = 3.0 + float(port % 5) * 1.7
		var phase: float = float(port) * 1.37
		var wave: float = sin(_elapsed * speed + phase) + sin(_elapsed * speed * 0.37 + phase * 2.0)
		intensity = clampf(0.35 + wave * 0.45, 0.0, 1.0)
	DrawKit.led_reflection(self, center - Vector2(0.0, 7.0), Vector2(30.0, 16.0), LED_ON, intensity, true)
	DrawKit.led(self, center, 3.4, LED_ON, intensity)


## Un RJ45 con su forma: cuerpo con degradado, muesca del clip, cavidad y los
## ocho contactos. El borde es claro y fino, no un contorno negro.
func _draw_rj45(rect: Rect2, highlighted: bool) -> void:
	DrawKit.gradient_rect(self, rect, PORT_BODY.lightened(0.12), PORT_BODY.darkened(0.25))
	DrawKit.soft_outline(self, rect, PORT_EDGE)
	var cavity: Rect2 = Rect2(rect.position + Vector2(4.0, 4.0), rect.size - Vector2(8.0, 12.0))
	DrawKit.gradient_rect(self, cavity, PORT_CAVITY.darkened(0.3), PORT_CAVITY.lightened(0.25))
	draw_rect(Rect2(Vector2(rect.position.x + rect.size.x * 0.33, cavity.end.y),
		Vector2(rect.size.x * 0.34, 8.0)), PORT_CAVITY)
	for i: int in 8:
		var x: float = cavity.position.x + 2.0 + i * (cavity.size.x - 4.0) / 8.0
		DrawKit.gradient_rect(self, Rect2(Vector2(x, cavity.position.y + 2.0), Vector2(1.5, cavity.size.y * 0.5)),
			PORT_GOLD.lightened(0.2), PORT_GOLD.darkened(0.3))
	if highlighted:
		DrawKit.soft_outline(self, rect.grow(2.0), HIGHLIGHT)


## Los cables: con volumen, sombra propia y la panza del peso del cable.
func _draw_cords() -> void:
	for camera: int in range(1, PORT_COUNT + 1):
		var color: Color = _model.color_of(camera)
		var from_point: Vector2 = _pp_tip(_model.pp_of(camera))
		if not _model.is_camera_down(camera):
			var to_point: Vector2 = _gi_tip(_model.gi_of(camera))
			var click: float = float(_click_anim.get(camera, 0.0))
			to_point.y -= click / CLICK_TIME * 12.0
			# El cable conectado todavía cuelga: su largo natural es más que
			# la línea recta entre los dos puertos.
			var natural: float = from_point.distance_to(to_point) + 64.0
			DrawKit.cable(self, DrawKit.hanging_points(from_point, to_point, natural, CORD_SEGMENTS),
				CORD_WIDTH, color)
			if click > 0.0:
				var flash: float = click / CLICK_TIME
				draw_circle(to_point, 16.0 * flash, Color(0.9, 0.93, 0.95, 0.3 * flash))
			continue

		var end_point: Vector2 = _drag_point if camera == _drag_camera else _loose_end(camera)
		DrawKit.cable(self, DrawKit.hanging_points(from_point, end_point, LOOSE_LENGTH, CORD_SEGMENTS),
			CORD_WIDTH, color)
		_draw_plug(end_point, color, camera == _hover_camera or camera == _drag_camera)
		_draw_cord_label(end_point, camera)


## El conector del extremo suelto. Si existe rj45.png, se usa la imagen.
func _draw_plug(center: Vector2, color: Color, highlighted: bool) -> void:
	var rect: Rect2 = _plug_rect(center)
	DrawKit.rect_shadow(self, rect, Vector2(2.0, 4.0))
	if _plug_texture != null:
		draw_texture_rect(_plug_texture, rect, false)
	else:
		DrawKit.gradient_rect(self, rect, color.lightened(0.18), color.darkened(0.4))
		DrawKit.soft_outline(self, rect, color.lightened(0.3))
		# La lengüeta del clip, arriba.
		DrawKit.gradient_rect(self, Rect2(rect.position + Vector2(5.0, -5.0), Vector2(rect.size.x - 10.0, 6.0)),
			color.lightened(0.25), color)
	if highlighted:
		DrawKit.soft_outline(self, rect.grow(3.0), HIGHLIGHT)


## La etiquetita de papel que cuelga del cable suelto.
func _draw_cord_label(center: Vector2, camera: int) -> void:
	var rect: Rect2 = Rect2(center + Vector2(16.0, 2.0), Vector2(58.0, 21.0))
	DrawKit.rect_shadow(self, rect, Vector2(2.0, 3.0))
	DrawKit.gradient_rect(self, rect, PAPER, PAPER_SHADE)
	DrawKit.soft_outline(self, rect, PAPER_SHADE.darkened(0.3))
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
				Color(SPARK_COLOR.r, SPARK_COLOR.g, SPARK_COLOR.b, fade * 0.85), 2.0)
		DrawKit.led(self, center, 4.0 * fade, SPARK_COLOR, fade)


func _sheet_bounds() -> Rect2:
	return _sheet_rect.grow(10.0)


## La hoja de etiquetado: papel con textura y arruga, sombra, cinta en las
## esquinas y letra de impresora de matriz (la VT323 ya es de ese tipo).
func _draw_sheet() -> void:
	var scale: float = SHEET_HOVER_SCALE if _sheet_hovered else 1.0
	var center: Vector2 = _sheet_rect.get_center()
	draw_set_transform(center, SHEET_TILT, Vector2(scale, scale))
	var sheet: Rect2 = Rect2(-_sheet_rect.size * 0.5, _sheet_rect.size)

	DrawKit.rect_shadow(self, sheet, Vector2(5.0, 8.0))
	DrawKit.gradient_rect(self, sheet, PAPER, PAPER_SHADE)
	# Textura: fibras finas y unas motas, siempre las mismas.
	for i: int in 26:
		var fiber_y: float = sheet.position.y + 8.0 + fmod(float(i) * 37.0, sheet.size.y - 16.0)
		var fiber_x: float = sheet.position.x + 6.0 + fmod(float(i) * 61.0, sheet.size.x - 40.0)
		draw_line(Vector2(fiber_x, fiber_y), Vector2(fiber_x + 18.0, fiber_y + 1.0),
			Color(0.0, 0.0, 0.0, 0.035), 1.0)
	# La arruga: una banda clara y su sombra, en diagonal.
	var crease_y: float = sheet.position.y + sheet.size.y * 0.42
	DrawKit.gradient_rect(self, Rect2(Vector2(sheet.position.x, crease_y), Vector2(sheet.size.x, 10.0)),
		Color(1.0, 1.0, 1.0, 0.1), Color(0.0, 0.0, 0.0, 0.07))
	for corner: Vector2 in [sheet.position, Vector2(sheet.end.x, sheet.position.y),
			Vector2(sheet.position.x, sheet.end.y), sheet.end]:
		draw_rect(Rect2(corner - Vector2(17.0, 7.0), Vector2(34.0, 14.0)), TAPE)

	var font: Font = get_theme_default_font()
	_draw_centered(font, Vector2(0.0, sheet.position.y + 26.0), "ETIQUETADO DE CAMARAS", 16, PAPER_INK)
	draw_line(Vector2(sheet.position.x + 14.0, sheet.position.y + 34.0),
		Vector2(sheet.end.x - 14.0, sheet.position.y + 34.0), Color(PAPER_INK.r, PAPER_INK.g, PAPER_INK.b, 0.5), 1.0)
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
