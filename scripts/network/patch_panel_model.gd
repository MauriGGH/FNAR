class_name PatchPanelModel
extends RefCounted

## Estado del patch panel de la sala de servidores: qué puerto le toca a cada
## cámara y cuáles están desconectadas por una descarga de Audel.
## La relación entre puertos se baraja cada noche, así que la hoja de
## etiquetado hay que leerla de verdad.

signal discharge_happened(cameras: PackedInt32Array)
signal camera_restored(camera: int)

const PORT_COUNT: int = 12
## Cuántas cámaras tumba una descarga.
const MIN_AFFECTED: int = 1
const MAX_AFFECTED: int = 3
## Antes de esta noche, la CAM 4 nunca se desconecta.
const CAM4_SAFE_BEFORE_NIGHT: int = 5
const PROTECTED_CAMERA: int = 4

## Colores de los patch cords, en el orden en que se reparten.
## Desaturados a propósito, para que peguen con las fotos de la oficina.
const CORD_COLORS: Array[Color] = [
	Color(0.3, 0.4, 0.55),    # azul
	Color(0.66, 0.6, 0.34),   # amarillo
	Color(0.45, 0.46, 0.48),  # gris
	Color(0.54, 0.3, 0.28),   # rojo
]

## cámara -> {"pp": int, "gi": int, "color": Color}
var wiring: Dictionary = {}
var disconnected: Array[int] = []


## Baraja los puertos de la noche y deja todo conectado.
func reset_for_night() -> void:
	wiring.clear()
	disconnected.clear()

	var pp_ports: Array[int] = []
	var gi_ports: Array[int] = []
	for i: int in PORT_COUNT:
		pp_ports.append(i + 1)
		gi_ports.append(i + 1)
	pp_ports.shuffle()
	gi_ports.shuffle()

	for i: int in PORT_COUNT:
		var camera: int = i + 1
		wiring[camera] = {
			"pp": pp_ports[i],
			"gi": gi_ports[i],
			"color": CORD_COLORS[i % CORD_COLORS.size()],
		}


func pp_of(camera: int) -> int:
	return int(wiring.get(camera, {}).get("pp", 0))


func gi_of(camera: int) -> int:
	return int(wiring.get(camera, {}).get("gi", 0))


func color_of(camera: int) -> Color:
	return wiring.get(camera, {}).get("color", Color.WHITE)


func is_camera_down(camera: int) -> bool:
	return camera in disconnected


## Qué cámara usa un puerto del switch, o 0 si está libre.
func camera_at_gi(gi_port: int) -> int:
	for camera: int in wiring:
		if gi_of(camera) == gi_port:
			return camera
	return 0


## true si ese puerto del switch tiene su cable puesto.
func is_gi_connected(gi_port: int) -> bool:
	var camera: int = camera_at_gi(gi_port)
	return camera != 0 and not is_camera_down(camera)


## La descarga del pararrayos: tumba de 1 a 3 cámaras que todavía estén bien.
## Devuelve las que se cayeron ahora.
func cause_discharge(night: int) -> PackedInt32Array:
	var available: Array[int] = []
	for camera: int in wiring:
		if is_camera_down(camera):
			continue
		if camera == PROTECTED_CAMERA and night < CAM4_SAFE_BEFORE_NIGHT:
			continue  # La caja del Come Trabas se respeta hasta la noche 5.
		available.append(camera)
	if available.is_empty():
		return PackedInt32Array()

	available.shuffle()
	var count: int = mini(randi_range(MIN_AFFECTED, MAX_AFFECTED), available.size())
	var affected: PackedInt32Array = PackedInt32Array()
	for i: int in count:
		disconnected.append(available[i])
		affected.append(available[i])
	affected.sort()
	discharge_happened.emit(affected)
	return affected


## Intenta meter el cable de una cámara en un puerto del switch.
## Devuelve true solo si era el puerto que decía la hoja.
func try_connect(camera: int, gi_port: int) -> bool:
	if not is_camera_down(camera) or gi_of(camera) != gi_port:
		return false
	disconnected.erase(camera)
	camera_restored.emit(camera)
	return true
