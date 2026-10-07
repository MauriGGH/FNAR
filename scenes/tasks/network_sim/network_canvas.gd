class_name NetworkCanvas
extends Control

## El lienzo del simulador: cuadrícula tenue, equipos con íconos dibujados a
## mano (sin imágenes ni marcas), cables verdes o rojos, y el arrastre de
## puerto a puerto para conectar. También anima el sobre del modo Simulación.

signal device_clicked(device_id: String)
signal link_rejected(reason: String)
signal link_created(device_id: String)
signal packet_arrived()

const GRID_STEP: float = 26.0
const BACKGROUND_COLOR: Color = Color(0.9, 0.91, 0.88)
const GRID_COLOR: Color = Color(0.0, 0.0, 0.0, 0.07)
const LINK_OK_COLOR: Color = Color(0.11, 0.58, 0.25)
const LINK_BAD_COLOR: Color = Color(0.78, 0.16, 0.14)
const LINK_WIDTH: float = 3.0
const DRAG_COLOR: Color = Color(0.2, 0.3, 0.45, 0.7)

const ICON_SIZE: Vector2 = Vector2(52.0, 40.0)
const LABEL_HEIGHT: float = 16.0
const PORT_SIZE: float = 9.0
const PORT_FREE: Color = Color(0.35, 0.37, 0.4)
const PORT_BUSY: Color = Color(0.11, 0.58, 0.25)
const PORT_HOVER: Color = Color(0.95, 0.65, 0.1)

const BODY_COLOR: Color = Color(0.29, 0.33, 0.38)
const BODY_EDGE: Color = Color(0.13, 0.15, 0.18)
const INK: Color = Color(0.85, 0.88, 0.9)
const LED_COLOR: Color = Color(0.3, 0.9, 0.45)
const TEXT_COLOR: Color = Color(0.1, 0.12, 0.14)

const PACKET_SPEED: float = 170.0
const PACKET_SIZE: Vector2 = Vector2(16.0, 11.0)
const PACKET_COLOR: Color = Color(0.97, 0.85, 0.35)

var model: NetModel = null
var selected_cable: String = NetModel.CABLE_STRAIGHT

var _drag_device: String = ""
var _drag_port: int = -1
var _drag_to: Vector2 = Vector2.ZERO
var _hover_device: String = ""
var _hover_port: int = -1

var _packet_path: PackedStringArray = PackedStringArray()
var _packet_leg: int = 0
var _packet_travelled: float = 0.0


func set_model(new_model: NetModel) -> void:
	model = new_model
	model.changed.connect(queue_redraw)
	queue_redraw()


func set_cable(cable: String) -> void:
	selected_cable = cable


# --- Geometría ----------------------------------------------------------------

func device_rect(device: NetDevice) -> Rect2:
	var center: Vector2 = Vector2(device.position.x * size.x, device.position.y * size.y)
	return Rect2(center - ICON_SIZE * 0.5, ICON_SIZE)


func device_center(device: NetDevice) -> Vector2:
	return device_rect(device).get_center()


## Los puertos se reparten a lo ancho: los primeros en el borde de arriba y
## el resto en el de abajo, según top_ports del equipo.
func port_position(device: NetDevice, port: int) -> Vector2:
	var rect: Rect2 = device_rect(device)
	var on_top: bool = port < device.top_ports
	var count: int = device.top_ports if on_top else device.port_count - device.top_ports
	var index: int = port if on_top else port - device.top_ports
	var step: float = rect.size.x / float(maxi(count, 1) + 1)
	var x: float = rect.position.x + step * float(index + 1)
	var y: float = rect.position.y - PORT_SIZE * 0.5 if on_top else rect.end.y + PORT_SIZE * 0.5
	return Vector2(x, y)


func _port_at(point: Vector2) -> Dictionary:
	if model == null:
		return {}
	for device: NetDevice in model.device_list():
		for port: int in device.port_count:
			var center: Vector2 = port_position(device, port)
			if point.distance_to(center) <= PORT_SIZE:
				return {"id": device.id, "port": port}
	return {}


func _device_at(point: Vector2) -> String:
	if model == null:
		return ""
	for device: NetDevice in model.device_list():
		if device_rect(device).has_point(point):
			return device.id
	return ""


# --- Interacción --------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null:
		_drag_to = motion.position
		var hovered: Dictionary = _port_at(motion.position)
		var new_device: String = str(hovered.get("id", ""))
		var new_port: int = int(hovered.get("port", -1))
		if new_device != _hover_device or new_port != _hover_port:
			_hover_device = new_device
			_hover_port = new_port
			queue_redraw()
		elif not _drag_device.is_empty():
			queue_redraw()
		return

	var click: InputEventMouseButton = event as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT:
		return

	if click.pressed:
		_on_press(click.position)
	else:
		_on_release(click.position)
	accept_event()


func _on_press(point: Vector2) -> void:
	var port: Dictionary = _port_at(point)
	if not port.is_empty():
		_drag_device = str(port["id"])
		_drag_port = int(port["port"])
		_drag_to = point
		queue_redraw()
		return
	var device_id: String = _device_at(point)
	if not device_id.is_empty():
		device_clicked.emit(device_id)


## Al soltar sobre otro puerto se intenta el cable; si no se puede, dice por qué.
func _on_release(point: Vector2) -> void:
	if _drag_device.is_empty():
		return
	var from_device: String = _drag_device
	var from_port: int = _drag_port
	_drag_device = ""
	_drag_port = -1

	var target: Dictionary = _port_at(point)
	if target.is_empty():
		queue_redraw()
		return
	var problem: String = model.connect_ports(
		from_device, from_port, str(target["id"]), int(target["port"]), selected_cable)
	if problem.is_empty():
		link_created.emit(from_device)
	else:
		link_rejected.emit(problem)
	queue_redraw()


# --- Sobre del modo Simulación ------------------------------------------------

## Manda un sobre por la ruta, de equipo en equipo.
func play_packet(path: PackedStringArray) -> void:
	_packet_path = path
	_packet_leg = 0
	_packet_travelled = 0.0
	queue_redraw()


func is_packet_flying() -> bool:
	return _packet_path.size() > 1


func _process(delta: float) -> void:
	if not is_packet_flying():
		return
	var from_device: NetDevice = model.device(_packet_path[_packet_leg])
	var to_device: NetDevice = model.device(_packet_path[_packet_leg + 1])
	if from_device == null or to_device == null:
		_packet_path.clear()
		return
	var leg_length: float = device_center(from_device).distance_to(device_center(to_device))
	_packet_travelled += PACKET_SPEED * delta
	if _packet_travelled >= leg_length:
		_packet_travelled = 0.0
		_packet_leg += 1
		if _packet_leg >= _packet_path.size() - 1:
			_packet_path.clear()
			packet_arrived.emit()
	queue_redraw()


# --- Dibujo -------------------------------------------------------------------

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)
	_draw_grid()
	if model == null:
		return
	_draw_links()
	if not _drag_device.is_empty():
		var start: Vector2 = port_position(model.device(_drag_device), _drag_port)
		draw_line(start, _drag_to, DRAG_COLOR, 2.0, true)
	for device: NetDevice in model.device_list():
		_draw_device(device)
	_draw_packet()


func _draw_grid() -> void:
	var x: float = GRID_STEP
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), GRID_COLOR, 1.0)
		x += GRID_STEP
	var y: float = GRID_STEP
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), GRID_COLOR, 1.0)
		y += GRID_STEP


func _draw_links() -> void:
	for link: NetLink in model.links:
		var a: NetDevice = model.device(link.a_id)
		var b: NetDevice = model.device(link.b_id)
		if a == null or b == null:
			continue
		var color: Color = LINK_OK_COLOR if link.ok else LINK_BAD_COLOR
		draw_line(port_position(a, link.a_port), port_position(b, link.b_port), color, LINK_WIDTH, true)


func _draw_device(device: NetDevice) -> void:
	var rect: Rect2 = device_rect(device)
	match device.kind:
		NetDevice.Kind.ROUTER:
			_draw_router(rect)
		NetDevice.Kind.SWITCH:
			_draw_switch(rect)
		NetDevice.Kind.SERVER:
			_draw_server(rect)
		_:
			_draw_pc(rect)

	# Puertos.
	for port: int in device.port_count:
		var center: Vector2 = port_position(device, port)
		var color: Color = PORT_BUSY if model.port_in_use(device.id, port) else PORT_FREE
		if device.id == _hover_device and port == _hover_port:
			color = PORT_HOVER
		draw_rect(Rect2(center - Vector2.ONE * PORT_SIZE * 0.5, Vector2.ONE * PORT_SIZE), color)

	# Nombre debajo del ícono.
	var font: Font = Fonts.terminal()
	var font_size: int = 15
	var text: String = device.label
	var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	var below_ports: bool = device.top_ports < device.port_count
	var baseline: Vector2 = Vector2(rect.get_center().x - width * 0.5,
		rect.end.y + LABEL_HEIGHT + (PORT_SIZE + 2.0 if below_ports else 2.0))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, TEXT_COLOR)


## Router: cuerpo bajo con tres flechas que salen, dibujado propio.
func _draw_router(rect: Rect2) -> void:
	_draw_body(rect, 6)
	var center: Vector2 = rect.get_center()
	for i: int in 3:
		var from_point: Vector2 = center + Vector2(-14.0 + i * 14.0, 6.0)
		var to_point: Vector2 = from_point + Vector2(0.0, -12.0)
		draw_line(from_point, to_point, INK, 2.0)
		draw_colored_polygon(PackedVector2Array([
			to_point + Vector2(-4.0, 0.0), to_point + Vector2(4.0, 0.0),
			to_point + Vector2(0.0, -5.0)]), INK)


## Switch: caja plana con su hilera de puertos dibujada.
func _draw_switch(rect: Rect2) -> void:
	_draw_body(rect, 3)
	for i: int in 6:
		var slot: Rect2 = Rect2(
			Vector2(rect.position.x + 6.0 + i * 7.0, rect.get_center().y + 2.0), Vector2(5.0, 7.0))
		draw_rect(slot, INK)
	draw_circle(Vector2(rect.end.x - 9.0, rect.position.y + 9.0), 3.0, LED_COLOR)


## PC: monitor con base.
func _draw_pc(rect: Rect2) -> void:
	var screen: Rect2 = Rect2(rect.position, Vector2(rect.size.x, rect.size.y - 10.0))
	_draw_body(screen, 3)
	draw_rect(Rect2(screen.position + Vector2(4.0, 4.0), screen.size - Vector2(8.0, 8.0)), Color(0.45, 0.62, 0.7))
	draw_rect(Rect2(Vector2(rect.get_center().x - 5.0, screen.end.y), Vector2(10.0, 5.0)), BODY_COLOR)
	draw_rect(Rect2(Vector2(rect.get_center().x - 13.0, rect.end.y - 5.0), Vector2(26.0, 4.0)), BODY_COLOR)


## Servidor: torre con sus bahías y dos luces.
func _draw_server(rect: Rect2) -> void:
	_draw_body(rect, 3)
	for i: int in 3:
		draw_rect(Rect2(Vector2(rect.position.x + 7.0, rect.position.y + 7.0 + i * 9.0),
			Vector2(rect.size.x - 24.0, 5.0)), INK)
	draw_circle(Vector2(rect.end.x - 10.0, rect.position.y + 10.0), 3.0, LED_COLOR)
	draw_circle(Vector2(rect.end.x - 10.0, rect.position.y + 20.0), 3.0, Color(0.95, 0.75, 0.2))


func _draw_body(rect: Rect2, radius: int) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = BODY_COLOR
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color = BODY_EDGE
	draw_style_box(style, rect)


func _draw_packet() -> void:
	if not is_packet_flying():
		return
	var from_device: NetDevice = model.device(_packet_path[_packet_leg])
	var to_device: NetDevice = model.device(_packet_path[_packet_leg + 1])
	if from_device == null or to_device == null:
		return
	var from_point: Vector2 = device_center(from_device)
	var to_point: Vector2 = device_center(to_device)
	var leg_length: float = maxf(from_point.distance_to(to_point), 1.0)
	var position: Vector2 = from_point.lerp(to_point, clampf(_packet_travelled / leg_length, 0.0, 1.0))
	var box: Rect2 = Rect2(position - PACKET_SIZE * 0.5, PACKET_SIZE)
	draw_rect(box, PACKET_COLOR)
	draw_rect(box, BODY_EDGE, false, 1.0)
	# La solapa del sobre.
	draw_line(box.position, box.get_center(), BODY_EDGE, 1.0)
	draw_line(Vector2(box.end.x, box.position.y), box.get_center(), BODY_EDGE, 1.0)
