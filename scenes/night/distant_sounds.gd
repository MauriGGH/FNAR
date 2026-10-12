extends Node

## Lo que se oye de lejos, por el bus Lejos: pasos en otro pasillo, un radio,
## el agua de los baños, el módem de Armando... Sirve para que la oficina no
## esté muda y para que el jugador sepa que algo se está moviendo sin verlo.
##
## Dos fuentes:
##   - Los profes: cada uno tiene su sonido, que suena al moverse o mientras
##     esté en cierto sitio. Lleva probabilidad, para que no cante siempre.
##   - El ambiente: cada 40 a 120 s sale uno al azar de los cinco sueltos.
##
## Todos los ids están en data/sounds.gd, así que meter los archivos de verdad
## es dejarlos en assets/audio/lejos/ y ya.

## Cada cuánto sale un ambiental.
const MIN_AMBIENT_GAP: float = 40.0
const MAX_AMBIENT_GAP: float = 120.0

## Probabilidad de que un profe suene cuando le toca. No siempre, para que no
## se vuelva un metrónomo.
const MOVE_CHANCE: float = 0.55
## La de Barcosa al salir corriendo es casi segura: es un aviso de verdad.
const RUN_CHANCE: float = 0.9
## Y lo que se espera, como mínimo, entre dos sonidos del mismo profe.
const PER_PROFE_GAP: float = 6.0

## Los cuartos donde cada profe tiene un sonido de fondo en bucle, con el id
## que le toca. Suena mientras esté ahí y se corta en cuanto se va.
const ROOM_LOOPS: Dictionary = {
	"banos": "urena_banos",
	"sala_juntas": "juan_teclado",
	"techo": "audel_chispa",
}

var _ambient_left: float = 0.0
## slug -> cuánto falta para que ese profe pueda volver a sonar.
var _cooldowns: Dictionary = {}
## Los bucles de sitio que están sonando ahora mismo.
var _active_loops: Array[String] = []


func _ready() -> void:
	_ambient_left = randf_range(MIN_AMBIENT_GAP, MAX_AMBIENT_GAP)


## Un sonido suelto de un profe, con su probabilidad y su espera.
func play_for(slug: String, sound_id: String, chance: float = MOVE_CHANCE) -> void:
	if sound_id.is_empty() or not GameManager.is_night_active:
		return
	if float(_cooldowns.get(slug, 0.0)) > 0.0:
		return
	if randf() > chance:
		return
	_cooldowns[slug] = PER_PROFE_GAP
	AudioManager.play(sound_id)


## Los bucles de sitio: se mira dónde está cada profe y se prenden o apagan.
func refresh_room_loops(animatronics: Array[Animatronic]) -> void:
	var wanted: Array[String] = []
	for animatronic: Animatronic in animatronics:
		if not animatronic.is_active:
			continue
		var sound_id: String = str(ROOM_LOOPS.get(animatronic.current_room, ""))
		if not sound_id.is_empty() and not sound_id in wanted:
			wanted.append(sound_id)
	for sound_id: String in wanted:
		if not sound_id in _active_loops:
			AudioManager.play_loop(sound_id)
	for sound_id: String in _active_loops:
		if not sound_id in wanted:
			AudioManager.stop(sound_id)
	_active_loops = wanted


func _process(delta: float) -> void:
	for slug: Variant in _cooldowns:
		_cooldowns[slug] = maxf(float(_cooldowns[slug]) - delta, 0.0)
	if not GameManager.is_night_active:
		return
	_ambient_left -= delta
	if _ambient_left > 0.0:
		return
	_ambient_left = randf_range(MIN_AMBIENT_GAP, MAX_AMBIENT_GAP)
	play_ambient()


## Uno de los cinco ambientales, al azar. También lo usa el panel de pruebas.
func play_ambient() -> void:
	var ids: Array[String] = Sounds.FAR_AMBIENT
	if ids.is_empty():
		return
	AudioManager.play(ids[randi() % ids.size()])


## Calla todo lo que esté sonando de lejos. Lo usa el fin de noche.
func stop_all() -> void:
	for sound_id: String in _active_loops:
		AudioManager.stop(sound_id)
	_active_loops.clear()


## Para el panel de pruebas: salta la espera del siguiente ambiental.
func debug_clear_gaps() -> void:
	_cooldowns.clear()
	_ambient_left = 0.0
