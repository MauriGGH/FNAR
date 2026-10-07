class_name NightCalls
extends RefCounted

## La llamada con la que empieza cada noche, como el Phone Guy de FNAF: el
## teléfono suena a los pocos segundos y, si contestas, el guion sale como
## subtítulos con voz. Se puede colgar con "Silenciar llamada".
##
## Los guiones los escribe el equipo. Mientras los arreglos estén vacíos, el
## teléfono NO suena en esa noche: no hay llamada que perder ni castigo.
## Para activar una noche, basta con llenar su arreglo, una línea por frase.

## Lo que tarda en sonar desde que empieza la noche.
const CALL_DELAY: float = 3.0
## Lo que suena antes de darse por perdida. No contestar no tiene castigo.
const RING_TIME: float = 10.0

## Voz de la síntesis de Godot para estos subtítulos: en español y un poco
## apagada, como un teléfono viejo. 1.0 es el tono normal.
const TTS_LANGUAGE: String = "es"
const TTS_PITCH: float = 0.85
const TTS_RATE: float = 0.95
const TTS_VOLUME: int = 55

## Una línea por frase. Vacío = esa noche no llama.
const BY_NIGHT: Dictionary = {
	1: [],
	2: [],
	3: [],
	4: [],
	5: [],
	6: [],
}


## El guion de una noche, o vacío si esa noche no tiene llamada.
static func for_night(night: int) -> PackedStringArray:
	return PackedStringArray(BY_NIGHT.get(night, []))


## true si esa noche tiene algo que decir.
static func has_call(night: int) -> bool:
	return not for_night(night).is_empty()
