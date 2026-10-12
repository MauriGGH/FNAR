class_name CustomNightFaces
extends RefCounted

## Los retratos de la Custom Night: de dónde sale la cara de cada profe.
##
## Los expedientes de `assets/art/extras/` son la escena completa (la carpeta,
## la hoja y el plano) y traen pegada una foto tipo polaroid en blanco y negro.
## La Custom Night enseña **solo esa foto**, recortada en cuadrado.
##
## Las medidas **no se adivinan**: las saca `tools/measure_dossier_faces.py`
## buscando el bloque de píxeles grises de la hoja, y de ahí se copian aquí. Si
## cambia el arte, se vuelve a correr. Los ocho usan la misma plantilla, así que
## salen casi idénticas; se guardan una por una de todos modos, porque mañana
## alguno puede traer la foto en otro sitio.
##
## Si a un profe le falta el expediente, el juego se cae a su jumpscare, que ya
## es un primer plano: ese no necesita recorte.

## La foto de cada expediente, normalizada sobre el tamaño de la imagen.
const PHOTOS: Dictionary = {
	"barcosa": Rect2(0.3141, 0.2528, 0.1484, 0.3148),
	"mamador": Rect2(0.3141, 0.2537, 0.1484, 0.3130),
	"urena": Rect2(0.3141, 0.2537, 0.1490, 0.3139),
	"rochis": Rect2(0.3151, 0.2537, 0.1474, 0.3111),
	"audel": Rect2(0.3141, 0.2537, 0.1490, 0.3111),
	"juan": Rect2(0.3141, 0.2537, 0.1484, 0.3130),
	"armando": Rect2(0.3141, 0.2537, 0.1490, 0.3120),
	"come_trabas": Rect2(0.3135, 0.2537, 0.1495, 0.3120),
}


static func has_photo(character_id: String) -> bool:
	return PHOTOS.has(character_id)


## El recorte cuadrado de la cara, en píxeles de la imagen: el cuadrado de
## arriba de la foto, que es donde cae la cabeza. La foto es más alta que ancha,
## así que el lado del cuadrado es su ancho y lo que sobra por abajo (el pecho)
## se queda fuera.
static func face_region(character_id: String, texture_size: Vector2) -> Rect2:
	if not PHOTOS.has(character_id) or texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2()
	var photo: Rect2 = PHOTOS[character_id] as Rect2
	var side: float = photo.size.x * texture_size.x
	return Rect2(photo.position.x * texture_size.x, photo.position.y * texture_size.y,
		side, side)


## La textura ya recortada, lista para meter en un TextureRect. Devuelve null si
## no hay expediente de ese profe.
static func face_texture(character_id: String) -> Texture2D:
	var dossier: Texture2D = Extras.dossier_texture(character_id)
	if dossier == null or not has_photo(character_id):
		return null
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = dossier
	atlas.region = face_region(character_id, dossier.get_size())
	return atlas
