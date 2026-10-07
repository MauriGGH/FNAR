class_name CameraOverlays
extends RefCounted

## Recortes que el código encima sobre la imagen de una cámara. Los
## rectángulos están medidos sobre la imagen de verdad, normalizados de 0 a 1,
## y no se adivinan: si cambia el arte, se vuelven a medir y se corrigen aquí.
##
## Hay dos clases de recorte. Uno sale de una imagen completa de la cámara y
## se recorta a su rectángulo: así es la cortina de la CAM 2, que se saca de
## cam02_cortina y se encima cuando la puerta está cerrada, sin necesidad de
## una imagen por combinación. El otro ya viene como capa transparente del
## tamaño de la cámara y va completo: así es la foto de la CAM 3.

## La cámara desde la que se ve la puerta de la oficina.
const DOOR_CAMERA: int = 2
## De dónde sale el recorte, sin extensión (sirve png, jpg o jpeg).
const DOOR_IMAGE: String = "res://assets/art/cameras/cam02_cortina"
## La cortina dentro de la imagen de la CAM 2.
const DOOR_RECT: Rect2 = Rect2(0.729, 0.223, 0.1245, 0.752)
## Los estados que ya traen la cortina abajo: esos no llevan nada encima.
const DOOR_BAKED_PREFIX: String = "barcosa-golpeando"

## La CAM 3, el cubículo de Rochis.
const PHOTO_CAMERA: int = 3
## La foto de su esposa difunta, colgada en la pared. Es una capa
## transparente del tamaño de la cámara, así que se encima completa sobre
## cualquier estado (vacia, sentado, medio, de_pie); si algún estado ya la
## trae pintada, dibujarla otra vez encima no cambia nada.
const PHOTO_IMAGE: String = "res://assets/art/cameras/cam03_foto"
## Dónde cuelga, por si algún día se quiere poder clicar. OJO: la capa pinta
## un poco más que esto (medido: hasta x 0.595 y y 0.238), así que el recorte
## NO se usa para dibujar, solo quedaría para la zona de clic.
const PHOTO_RECT: Rect2 = Rect2(0.52, 0.04, 0.07, 0.18)

## La imagen entera, para las capas que ya vienen del tamaño de la cámara.
const FULL_IMAGE: Rect2 = Rect2(0.0, 0.0, 1.0, 1.0)


## Lo que hay que encimar en esa cámara ahora mismo, o un diccionario vacío
## si no lleva nada. Queda {"image": ruta sin extensión, "region": Rect2
## normalizado}; la región es FULL_IMAGE cuando la capa va completa.
static func overlay_for(camera: int, state: String, is_door_closed: bool) -> Dictionary:
	if needs_door_curtain(camera, state, is_door_closed):
		return {"image": DOOR_IMAGE, "region": DOOR_RECT}
	if camera == PHOTO_CAMERA:
		# La capa es transparente alrededor de la foto: recortarla a
		# PHOTO_RECT le cortaría el marco, así que va completa.
		return {"image": PHOTO_IMAGE, "region": FULL_IMAGE}
	return {}


## true si hay que encimar la cortina en esa cámara, con ese estado y con la
## puerta en ese momento.
static func needs_door_curtain(camera: int, state: String, is_door_closed: bool) -> bool:
	if camera != DOOR_CAMERA or not is_door_closed:
		return false
	return not state.begins_with(DOOR_BAKED_PREFIX)
