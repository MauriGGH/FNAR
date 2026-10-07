class_name CameraOverlays
extends RefCounted

## Recortes que el código encima sobre la imagen de una cámara. Los
## rectángulos están medidos sobre la imagen de verdad, normalizados de 0 a 1,
## y no se adivinan: si cambia el arte, se vuelven a medir y se corrigen aquí.
##
## Por ahora solo hay uno: la cortina de la puerta de la oficina en la CAM 2.
## La imagen base de esa cámara ya trae pintada la caja de la cortina, así que
## cuando la puerta está cerrada basta encimar este pedazo de cam02_cortina
## sobre el estado que toque, sin necesidad de una imagen por combinación.

## La cámara desde la que se ve la puerta de la oficina.
const DOOR_CAMERA: int = 2
## De dónde sale el recorte, sin extensión (sirve png, jpg o jpeg).
const DOOR_IMAGE: String = "res://assets/art/cameras/cam02_cortina"
## La cortina dentro de la imagen de la CAM 2.
const DOOR_RECT: Rect2 = Rect2(0.729, 0.223, 0.1245, 0.752)
## Los estados que ya traen la cortina abajo: esos no llevan nada encima.
const DOOR_BAKED_PREFIX: String = "barcosa-golpeando"


## true si hay que encimar la cortina en esa cámara, con ese estado y con la
## puerta en ese momento.
static func needs_door_curtain(camera: int, state: String, is_door_closed: bool) -> bool:
	if camera != DOOR_CAMERA or not is_door_closed:
		return false
	return not state.begins_with(DOOR_BAKED_PREFIX)
