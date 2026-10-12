class_name MissingAudioReport
extends RefCounted

## Escribe docs/audios_faltantes.md: la lista de todos los sonidos del catálogo
## que **todavía no tienen archivo** en assets/audio/, con su id, el nombre que
## se espera y cómo tiene que sonar.
##
## La descripción no se inventa aquí: sale del campo "desc" de cada entrada de
## `data/sounds.gd`, que es donde vive el catálogo. Así la lista nunca se
## desactualiza: se vuelve a generar y ya.
##
## Lo lanza el panel de pruebas (F1 → Audio). Escribe en res://, así que solo
## funciona corriendo el proyecto desde la carpeta, no en el juego exportado.

const PATH: String = "res://docs/audios_faltantes.md"

const HEADER: String = """# Audios que faltan

Los sonidos del catálogo (`data/sounds.gd`) que todavía no tienen archivo en
`assets/audio/`. Mientras falten, el juego usa el provisional que genera
`scripts/audio/tone_builder.gd`, y los que no tienen provisional sencillamente
no suenan.

**Para meter uno:** deja el archivo con ese nombre exacto en `assets/audio/` y
corre `godot --headless --import`. No hay que tocar código.

Esta lista la escribe el panel de pruebas (F1 → Audio → «Escribir la lista de
audios que faltan»); no se edita a mano.
"""


## Los ids del catálogo que no tienen archivo, en el orden del catálogo.
static func missing_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: Variant in Sounds.CATALOG:
		if not AudioManager.has_real_file(str(id)):
			ids.append(str(id))
	return ids


## Escribe el documento y devuelve la ruta. Si no se puede, devuelve "".
static func write() -> String:
	var missing: Array[String] = missing_ids()
	var total: int = Sounds.CATALOG.size()
	var text: String = HEADER
	text += "\nFaltan **%d de %d**. Generado desde el catálogo.\n" % [missing.size(), total]
	text += _table("Sin archivo y sin provisional (no suena nada)",
		missing, false)
	text += _table("Sin archivo, pero con provisional por código", missing, true)
	if not DirAccess.dir_exists_absolute("res://docs"):
		DirAccess.make_dir_recursive_absolute("res://docs")
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if file == null:
		push_warning("[audio] no se pudo escribir %s" % PATH)
		return ""
	file.store_string(text)
	file.close()
	return PATH


## Una de las dos tablas: los que tienen provisional o los que no.
static func _table(title: String, ids: Array[String], with_generator: bool) -> String:
	var rows: String = ""
	for id: String in ids:
		var has_generator: bool = not Sounds.generator_of(id).is_empty()
		if has_generator != with_generator:
			continue
		rows += "| `%s` | `%s` | %s | %s |\n" % [id, Sounds.file_name(id),
			Sounds.bus_of(id), _desc(id)]
	if rows.is_empty():
		return "\n## %s\n\nNinguno.\n" % title
	return "\n## %s\n\n| id | archivo que se espera | bus | cómo debe sonar |\n| --- | --- | --- | --- |\n%s" % [
		title, rows]


static func _desc(id: String) -> String:
	var text: String = str(Sounds.entry(id).get("desc", ""))
	return text if not text.is_empty() else "(sin descripción en el catálogo)"
