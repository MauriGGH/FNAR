class_name NightCalls
extends RefCounted

## La llamada con la que empieza cada noche, como el Phone Guy de FNAF: el
## teléfono suena a los pocos segundos y, si contestas, se reproduce el audio
## grabado con sus subtítulos. Se puede silenciar en cualquier momento y no
## bloquea el juego: las cámaras, la puerta y la linterna siguen funcionando.
##
## Una noche tiene llamada si existe su audio en
## `assets/audio/llamadas/llamada_nocheN.ogg`. Si no está, esa noche el
## teléfono no suena: no hay nada que perder ni castigo por no contestar.
##
## Los subtítulos van en `data/llamadas/llamada_nocheN.txt`, una línea por
## frase con el formato `m:ss|texto`. Las líneas que empiezan con # y las
## vacías se ignoran. Cada frase se queda en pantalla hasta que empieza la
## siguiente, así que basta con apuntar en qué segundo entra cada una.

## Lo que tarda en sonar desde que empieza la noche.
const CALL_DELAY: float = 3.0
## Lo que suena antes de darse por perdida. No contestar no tiene castigo.
const RING_TIME: float = 10.0

const SUBTITLES_PATH: String = "res://data/llamadas/llamada_noche%d.txt"
## Lo que se quedan los últimos subtítulos después de la última frase, por si
## el audio termina justo encima.
const TAIL_TIME: float = 2.5

# La síntesis de voz ya no se usa para estas llamadas (son audio grabado),
# pero Ureña sigue hablando con ella, así que su configuración se queda aquí.
const TTS_LANGUAGE: String = "es"
const TTS_PITCH: float = 0.85
const TTS_RATE: float = 0.95
const TTS_VOLUME: int = 55


## El id del catálogo de sonidos para la llamada de esa noche.
static func sound_id(night: int) -> String:
	return Sounds.night_call(night)


## true si esa noche tiene llamada, o sea: si existe el audio.
static func has_call(night: int) -> bool:
	return AudioManager.has_real_file(sound_id(night))


## Los subtítulos de esa noche, en orden: [{"at": segundos, "text": String}].
## Vacío si no hay archivo o no trae ninguna línea aprovechable.
static func subtitles(night: int) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var path: String = SUBTITLES_PATH % night
	if not FileAccess.file_exists(path):
		return lines
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("No se pudo abrir " + path)
		return lines
	while not file.eof_reached():
		var raw: String = file.get_line().strip_edges()
		if raw.is_empty() or raw.begins_with("#"):
			continue
		var cut: int = raw.find("|")
		if cut <= 0:
			continue
		var at: float = _parse_time(raw.substr(0, cut))
		if at < 0.0:
			continue
		lines.append({"at": at, "text": raw.substr(cut + 1).strip_edges()})
	lines.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["at"]) < float(b["at"]))
	return lines


## Convierte "m:ss" (o "mm:ss", o solo segundos) en segundos. -1 si no se puede.
static func _parse_time(text: String) -> float:
	var clean: String = text.strip_edges()
	if clean.is_empty():
		return -1.0
	var parts: PackedStringArray = clean.split(":")
	if parts.size() == 1:
		return float(parts[0]) if parts[0].is_valid_float() else -1.0
	if parts.size() != 2:
		return -1.0
	if not parts[0].is_valid_int() or not parts[1].is_valid_float():
		return -1.0
	return float(parts[0].to_int() * 60) + float(parts[1])
