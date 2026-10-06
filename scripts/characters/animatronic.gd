class_name Animatronic
extends Node

## Clase base de los profes. Cada move_interval segundos tira el "dado" de la IA:
## si randi_range(1, 20) <= ai_level, avanza un paso de su ruta.
## Cada profe hereda de aquí y sobrescribe solo lo que lo hace único
## (normalmente can_move() y advance()).

## Avisa que el profe cambió de habitación. from_room queda vacío al empezar.
signal moved(from_room: String, to_room: String)

## Ruido del profe. Mientras no haya audio, la oficina lo muestra como texto.
signal made_noise(text: String, duration: float)

@export var display_name: String = "Profe"
## Nivel de IA de 0 a 20. En 0 el profe no se mueve en toda la noche.
@export_range(0, 20) var ai_level: int = 0
## Segundos entre cada oportunidad de moverse.
@export var move_interval: float = 5.0
## Ids de habitaciones de data/rooms.gd, en orden.
@export var route: PackedStringArray = PackedStringArray()

var current_room: String = ""
var is_active: bool = false

# Lo que está haciendo el jugador. El night.gd lo mantiene al día para todos.
var watched_camera: int = Rooms.NO_CAMERA  # 0 = no está viendo cámaras
var door_closed: bool = false

var _route_index: int = 0
var _elapsed: float = 0.0


## Lo coloca al principio de su ruta y lo pone a moverse.
func start() -> void:
	_route_index = 0
	_elapsed = 0.0
	current_room = route[0] if not route.is_empty() else ""
	is_active = ai_level > 0 and not route.is_empty()
	moved.emit("", current_room)


func stop() -> void:
	is_active = false


func set_watched_camera(camera: int) -> void:
	watched_camera = camera


func set_door_closed(closed: bool) -> void:
	door_closed = closed


## true si el jugador está viendo justo la cámara de donde está este profe.
func is_being_watched() -> bool:
	return watched_camera != Rooms.NO_CAMERA and watched_camera == Rooms.camera_of(current_room)


func _process(delta: float) -> void:
	if not is_active:
		return
	_elapsed += delta
	if _elapsed < move_interval:
		return
	_elapsed = 0.0
	try_move()


## Tira el dado de la IA. Devuelve true si le tocó moverse.
func try_move() -> bool:
	if not can_move():
		return false
	if randi_range(1, 20) > ai_level:
		return false
	advance()
	return true


## Gancho: cada profe decide si puede moverse ahora mismo
## (por ejemplo, Barcosa espera a que el pasillo esté libre).
func can_move() -> bool:
	return true


## Paso por defecto: avanzar un lugar en la ruta y quedarse quieto al final.
func advance() -> void:
	if _route_index + 1 >= route.size():
		return
	move_to_step(_route_index + 1)


## Gancho de depuración: lo que la etiqueta de F3 muestra de este profe.
func debug_text() -> String:
	return ""


## Texto provisional para la oficina mientras este profe está en la puerta.
## Cadena vacía = no está ahí. Lo reemplazarán los sprites.
func door_presence() -> String:
	return ""


## Lo mismo, para cuando está asomado al cristal.
func window_presence() -> String:
	return ""


## Mueve al profe al paso indicado de su ruta y avisa con la señal.
func move_to_step(index: int) -> void:
	var target: String = route[index]
	assert(Rooms.has_room(target), "Habitación desconocida en la ruta: " + target)
	var previous: String = current_room
	_route_index = index
	current_room = target
	moved.emit(previous, current_room)
