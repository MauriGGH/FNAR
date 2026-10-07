class_name OfficeLayers
extends RefCounted

## Dónde cae cada profe dentro de su recorte de la vista central. Los recortes
## son del tamaño de la vista entera y casi todo es transparente, así que el
## rectángulo de abajo es el recuadro de lo que de verdad se pinta.
##
## El juego lo usa para saber a quién le está dando el cono de la linterna: si
## el haz toca ese rectángulo, ese profe está alumbrado.
##
## Son medidas, no inventadas: las saca `tools/measure_office_layers.py` de los
## propios PNG. Si cambia el arte, se vuelve a correr y se copian aquí.

## slug del profe -> su recuadro, normalizado sobre la vista.
const BOXES: Dictionary = {
	"mamador": Rect2(0.3949, 0.3047, 0.1295, 0.3880),
	"barcosa": Rect2(0.6065, 0.2799, 0.2422, 0.4128),
	"audel": Rect2(0.7193, 0.1706, 0.1156, 0.4740),
	"urena": Rect2(0.4545, 0.2773, 0.2124, 0.4154),
	"juan": Rect2(0.7855, 0.2878, 0.1382, 0.4049),
	"armando": Rect2(0.6538, 0.3047, 0.1215, 0.3880),
}

## El ojo de Armando: el píxel naranja más brillante de `centro_armando`, que es
## rgb(156, 88, 31). Ahí se pinta el puntito que parpadea cuando está a oscuras.
const ARMANDO_EYE: Vector2 = Vector2(0.7193, 0.3607)
const ARMANDO_EYE_COLOR: Color = Color(0.86, 0.45, 0.14)

## Los que se ven siempre, aunque sea a oscuras, porque ya están dentro o muy
## cerca de la oficina. Los demás solo existen dentro del cono.
const ALWAYS_VISIBLE: Array[String] = ["mamador", "barcosa", "audel"]
## Lo apagados que se ven esos tres fuera del cono.
const DIM_BRIGHTNESS: float = 0.35


static func box_of(slug: String) -> Rect2:
	return BOXES.get(slug, Rect2()) as Rect2


static func has_box(slug: String) -> bool:
	return BOXES.has(slug)


static func is_always_visible(slug: String) -> bool:
	return slug in ALWAYS_VISIBLE
