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
## Mirando fijo a la cámara, a punto de salir de su lugar inicial.
var is_stalking: bool = false

# Lo que está haciendo el jugador. El night.gd lo mantiene al día para todos.
var watched_camera: int = Rooms.NO_CAMERA  # 0 = no está viendo cámaras
var door_closed: bool = false

var _route_index: int = 0
var _elapsed: float = 0.0


## Lo coloca al principio de su ruta y lo pone a moverse.
func start() -> void:
	_route_index = 0
	_elapsed = 0.0
	is_stalking = false
	current_room = route[0] if not route.is_empty() else ""
	is_active = ai_level > 0 and not route.is_empty()
	moved.emit("", current_room)


func stop() -> void:
	is_active = false


func set_watched_camera(camera: int) -> void:
	watched_camera = camera


func set_door_closed(closed: bool) -> void:
	door_closed = closed


## El night.gd avisa aquí cuando el jugador prende o apaga la linterna.
## A Ureña lo ahuyenta; a Mamador le da igual.
func set_flashlight_on(_is_on: bool) -> void:
	pass


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
	# Acecho: la primera oportunidad en su lugar inicial no lo mueve, solo lo
	# pone a mirar fijo a la cámara; la siguiente ya lo saca.
	if _should_start_stalking():
		is_stalking = true
		return true
	advance()
	return true


## Solo acecha el último que quede en su lugar inicial: en la sala de juntas,
## mientras haya más de uno, nadie se queda mirando a la cámara.
func _should_start_stalking() -> bool:
	return (stalks_before_leaving() and not is_stalking
		and _route_index == 0 and others_in_room() == 0)


## Gancho: este profe hace una pausa de acecho antes de salir de su lugar.
func stalks_before_leaving() -> bool:
	return false


## Cuántos otros profes activos están en la misma habitación que este. Son
## todos hermanos del mismo nodo Animatronics, así que se preguntan ahí.
func others_in_room() -> int:
	var parent: Node = get_parent()
	if parent == null:
		return 0
	var count: int = 0
	for sibling: Node in parent.get_children():
		var other: Animatronic = sibling as Animatronic
		if other != null and other != self and other.is_active and other.current_room == current_room:
			count += 1
	return count


## Gancho: con qué causa termina la noche si este profe te atrapa. Cadena
## vacía si no mata. Lo usa el guardado para abrir su ficha y su jumpscare.
func game_over_cause() -> String:
	return ""


## Gancho: la clave de este profe en la tabla de niveles de data/nights.gd.
## Cadena vacía = su nivel lo decide él mismo.
func ai_key() -> String:
	return ""


## El nivel de IA que le toca esta noche según la tabla. Lo llama su start().
func night_ai_level() -> int:
	var key: String = ai_key()
	if key.is_empty():
		return ai_level
	return GameManager.ai_level_for(key)


## Gancho de depuración: lo pone a moverse aunque la noche le haya dado
## nivel 0. Lo usan las teclas que mandan a un profe a su posición de ataque.
func debug_activate() -> void:
	if route.is_empty():
		return
	is_active = true


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


## Texto provisional para la oficina mientras este profe se ve en una zona
## (la puerta, el cristal, la escalera). Cadena vacía = no se ve ahí.
## Lo reemplazarán los sprites.
func zone_presence(_zone_id: String) -> String:
	return ""


## Gancho: ¿se ve este profe en esa zona de la oficina? A diferencia de
## zone_presence(), no depende de la linterna: eso lo dice needs_flashlight().
func is_in_zone(_zone_id: String) -> bool:
	return false


## true si en esa zona solo se ve dentro del haz de la linterna.
func needs_flashlight(_zone_id: String) -> bool:
	return false


## El nombre corto con el que este profe sale en los archivos de imagen:
## barcosa, mamador, urena, juan, armando, rochis, audel. Cada uno lo pone.
func image_slug() -> String:
	return ""


## El pedazo que este profe aporta al nombre del estado de una cámara, o
## cadena vacía si no se ve ahí. Cuando hay varios en la misma cámara, el
## sistema los une en el orden fijo: cam02_mamador_urena.
func camera_token(camera: int) -> String:
	if camera == Rooms.NO_CAMERA or camera != Rooms.camera_of(current_room):
		return ""
	return _slug_token()


## true si en esa cámara este profe tapa a los demás. Barcosa corriendo por el
## pasillo es el único caso: se muestra solo a él.
func hides_others(_camera: int) -> bool:
	return false


## El nombre corto, con el sufijo de acecho si está mirando a la cámara.
func _slug_token() -> String:
	var slug: String = image_slug()
	if slug.is_empty():
		return ""
	return "%s-acecho" % slug if is_stalking else slug


## Mueve al profe al paso indicado de su ruta y avisa con la señal.
func move_to_step(index: int) -> void:
	var target: String = route[index]
	assert(Rooms.has_room(target), "Habitación desconocida en la ruta: " + target)
	var previous: String = current_room
	is_stalking = false
	_route_index = index
	current_room = target
	moved.emit(previous, current_room)
