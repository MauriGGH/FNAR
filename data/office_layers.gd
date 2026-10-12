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

## Dónde cae cada silueta dentro de su capa. Medidas con la misma herramienta y
## comprobado que **ninguna se encima con otra**: cada profe tiene su sitio al
## otro lado del cristal, así que pueden verse varias a la vez.
const SILHOUETTE_BOXES: Dictionary = {
	"barcosa": Rect2(0.3120, 0.3984, 0.0822, 0.2409),
	"mamador": Rect2(0.4691, 0.4323, 0.0415, 0.1211),
	"urena": Rect2(0.5120, 0.3958, 0.0575, 0.1758),
	"juan": Rect2(0.5760, 0.4206, 0.0516, 0.1510),
	"armando": Rect2(0.6647, 0.4310, 0.0524, 0.1237),
}

## El ojo de Armando: el píxel naranja más brillante de `centro_armando`, que es
## rgb(156, 88, 31). Ahí se pinta el puntito que parpadea cuando está a oscuras.
const ARMANDO_EYE: Vector2 = Vector2(0.7193, 0.3607)
const ARMANDO_EYE_COLOR: Color = Color(0.86, 0.45, 0.14)

## Capas que existen como archivo pero ya no se usan:
##
## - `derecha_rochis.png` es de la vista derecha vieja y no cuadra con la nueva.
##   En cuanto llegue la de verdad, se quita de aquí y vuelve a dibujarse.
## - `centro_barcosa.png` solo salía cuando Barcosa golpeaba la puerta, y eso
##   ahora no se dibuja: está detrás de la cortina. Además su sitio es el de la
##   oficina vieja (x 0.61, cuando la puerta está en x 0.30).
const DISABLED: Array[String] = ["derecha_rochis", "centro_barcosa"]

## Los cuartos que se alcanzan a ver desde la oficina a través del cristal. Un
## profe que esté en uno de ellos y tenga su `layers/silueta_<id>.png` se
## dibuja como silueta al fondo del pasillo.
const GLASS_ROOMS: Array[String] = ["recepcion", "pasillo_sur"]
## Cómo se ve una silueta fuera del cono: apagada y desenfocada.
const SILHOUETTE_BLUR: float = 0.004

## Los que se ven siempre, aunque sea a oscuras, porque ya están dentro o muy
## cerca de la oficina. Los demás solo existen dentro del cono.
const ALWAYS_VISIBLE: Array[String] = ["mamador", "barcosa", "audel"]
## Lo apagados que se ven esos tres fuera del cono.
const DIM_BRIGHTNESS: float = 0.35


## Todo el pasillo: el recuadro que abarca a los seis recortes juntos. Es lo
## que tiene que alumbrar la linterna, que ya no se apunta a nadie en concreto.
static func hallway_rect() -> Rect2:
	var union: Rect2 = Rect2()
	var first: bool = true
	for slug: Variant in BOXES:
		var box: Rect2 = BOXES[slug] as Rect2
		union = box if first else union.merge(box)
		first = false
	return union


static func box_of(slug: String) -> Rect2:
	return BOXES.get(slug, Rect2()) as Rect2


static func has_box(slug: String) -> bool:
	return BOXES.has(slug)


static func is_always_visible(slug: String) -> bool:
	return slug in ALWAYS_VISIBLE


static func is_disabled(file_name: String) -> bool:
	return file_name in DISABLED


## El nombre del archivo de la silueta de un profe.
static func silhouette_name(slug: String) -> String:
	return "silueta_%s" % slug


## true si ese cuarto se ve desde la oficina por el cristal.
static func is_glass_room(room_id: String) -> bool:
	return room_id in GLASS_ROOMS


static func silhouette_box(slug: String) -> Rect2:
	return SILHOUETTE_BOXES.get(slug, Rect2()) as Rect2


static func has_silhouette(slug: String) -> bool:
	return SILHOUETTE_BOXES.has(slug)
