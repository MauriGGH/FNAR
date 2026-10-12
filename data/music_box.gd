class_name MusicBox
extends RefCounted

## Los tiempos de la canción de la cajita musical, para que el juego pueda
## seguirle el ritmo: las chispas del apagón parpadean con sus pulsos.
##
## Salen de `data/audio/cajita_musical_notas.json`, que trae:
##   - `duracion`: lo que dura el archivo, en segundos.
##   - `pulsos`:   el ritmo, un valor por tiempo fuerte.
##   - `notas`:    cada ataque de la melodía (más densos que los pulsos).
##   - `tempo_bpm`: informativo.
##
## Si el JSON no está, se usan los tiempos del provisional que genera
## ToneBuilder, así que el juego funciona igual aunque falte.
##
## De qué canción se trata no se dice en ninguna parte: es un secreto para la
## segunda entrega y aquí solo interesan sus tiempos.

const DATA_PATH: String = "res://data/audio/cajita_musical_notas.json"

## Se lee una vez y se guarda: el apagón la pide en cada partida.
static var _loaded: bool = false
static var _pulses: PackedFloat32Array = PackedFloat32Array()
static var _notes: PackedFloat32Array = PackedFloat32Array()
static var _length: float = 0.0


## Los tiempos del ritmo. Si no hay JSON, los del provisional.
static func pulse_times() -> PackedFloat32Array:
	_load()
	return _pulses if not _pulses.is_empty() else ToneBuilder.music_box_note_times()


## Cada ataque de la melodía. Más densos que los pulsos.
static func note_times() -> PackedFloat32Array:
	_load()
	return _notes if not _notes.is_empty() else ToneBuilder.music_box_note_times()


## Lo que dura la canción. Manda lo que diga el archivo de audio de verdad; el
## JSON solo sirve de respaldo, por si el audio todavía no está importado.
static func length() -> float:
	var real: float = AudioManager.length(Sounds.MUSIC_BOX_BLACKOUT)
	if real > 0.0:
		return real
	_load()
	return _length if _length > 0.0 else ToneBuilder.music_box_length()


## Un tramo al azar de la canción, para el apagón: **empieza en un pulso** de la
## primera parte (la que diga start_fraction) y **acaba en otro pulso**, el que
## caiga más cerca de la duración que se pidió. Devuelve el principio y el final
## en segundos. Si no hay pulsos a mano, devuelve un tramo del largo pedido
## contado desde el principio.
static func random_segment(min_seconds: float, max_seconds: float,
		start_fraction: float = 0.5) -> Vector2:
	var wanted: float = randf_range(min_seconds, max_seconds)
	var times: PackedFloat32Array = pulse_times()
	var total: float = length()
	if times.size() < 2:
		return Vector2(0.0, minf(total, wanted))

	# El pulso por donde entra, de la primera parte de la canción.
	var last_start: int = maxi(0, floori(float(times.size()) * start_fraction) - 1)
	var from: int = randi_range(0, last_start)
	var start: float = times[from]

	# Y el pulso que cae más cerca de lo que tenía que durar.
	var best: int = -1
	var best_gap: float = 0.0
	for i: int in range(from + 1, times.size()):
		var gap: float = absf((times[i] - start) - wanted)
		if best < 0 or gap < best_gap:
			best = i
			best_gap = gap
	if best < 0:
		return Vector2(start, minf(total, start + wanted))
	var end: float = times[best]
	if total > 0.0:
		end = minf(end, total)
	return Vector2(start, end)


## true si los tiempos salieron del JSON y no del provisional.
static func has_data() -> bool:
	_load()
	return not _pulses.is_empty()


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(DATA_PATH):
		return
	var file: FileAccess = FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("No se pudo abrir " + DATA_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Los tiempos de la cajita no son un JSON válido")
		return
	var data: Dictionary = parsed as Dictionary
	_pulses = _to_times(data.get("pulsos", []))
	_notes = _to_times(data.get("notas", []))
	_length = float(data.get("duracion", 0.0))


## Los pasa a float y los deja en orden, por si vinieran revueltos.
static func _to_times(value: Variant) -> PackedFloat32Array:
	var times: PackedFloat32Array = PackedFloat32Array()
	for item: Variant in (value as Array if value is Array else []):
		times.append(float(item))
	times.sort()
	return times
