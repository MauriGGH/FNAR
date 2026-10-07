class_name Nights
extends RefCounted

## Niveles de IA por noche, igual que la tabla de CLAUDE.md. No es autoload:
## se usa como Nights.ai_level(noche, Nights.BARCOSA) desde cualquier script.
## Cuántas tareas pide cada noche está en data/tasks.gd (TASKS_PER_NIGHT).

# Claves de cada profe en la tabla. Las usa su propio script en ai_key().
const BARCOSA: String = "barcosa"
const MAMADOR: String = "mamador"
const URENA: String = "urena"
const ROCHIS: String = "rochis"
const AUDEL: String = "audel"
const JUAN_EXE: String = "juan_exe"
const ARMANDO: String = "armando"

## Velocidad del Come Trabas. Los números son los de ComeTrabas.Speed, en el
## mismo orden: lenta, media, rápida y muy rápida.
const COME_TRABAS: String = "come_trabas"

## Las ocho claves juntas, para recorrerlas sin repetir la lista.
const ALL_KEYS: Array[String] = [
	"barcosa", "mamador", "urena", "rochis", "audel", "juan_exe", "armando", "come_trabas",
]

const FIRST_NIGHT: int = 1
const LAST_NIGHT: int = 6

## Mientras no exista el menú (hito 6), la noche de prueba sale de aquí.
const LEVELS: Dictionary = {
	1: {BARCOSA: 0, MAMADOR: 3, URENA: 0, ROCHIS: 0, AUDEL: 0, COME_TRABAS: 0, JUAN_EXE: 2, ARMANDO: 0},
	2: {BARCOSA: 3, MAMADOR: 5, URENA: 0, ROCHIS: 0, AUDEL: 0, COME_TRABAS: 0, JUAN_EXE: 4, ARMANDO: 2},
	3: {BARCOSA: 5, MAMADOR: 7, URENA: 4, ROCHIS: 3, AUDEL: 0, COME_TRABAS: 1, JUAN_EXE: 6, ARMANDO: 4},
	4: {BARCOSA: 8, MAMADOR: 9, URENA: 7, ROCHIS: 6, AUDEL: 5, COME_TRABAS: 1, JUAN_EXE: 8, ARMANDO: 6},
	5: {BARCOSA: 11, MAMADOR: 12, URENA: 10, ROCHIS: 10, AUDEL: 9, COME_TRABAS: 2, JUAN_EXE: 10, ARMANDO: 9},
	6: {BARCOSA: 15, MAMADOR: 16, URENA: 15, ROCHIS: 15, AUDEL: 14, COME_TRABAS: 3, JUAN_EXE: 14, ARMANDO: 13},
}

## --- Tickets ---------------------------------------------------------------
## Las tareas no están desde las 12: llegan como tickets repartidos en la
## noche. Cuántos llegan lo dice Tasks.TASKS_PER_NIGHT; aquí va el reparto y
## el plazo de cada uno.
##
## El plazo está en HORAS DE JUEGO, no en segundos, así que se acorta solo en
## modo prueba y se puede leer contra el reloj: en la noche 1 tienes dos horas
## y media para cada ticket, en la noche 6 poco más de una.
const TICKET_DEADLINE_HOURS: Dictionary = {
	1: 2.5, 2: 2.2, 3: 2.0, 4: 1.7, 5: 1.4, 6: 1.1,
}

## El primer ticket llega casi al empezar; los demás se reparten hasta poco
## antes de las 5 AM, con algo de azar para que no caigan siempre en la misma
## hora. El último entra a las 4.2 y no a las 5 para que su plazo quepa dentro
## de la noche y se pueda terminar.
const FIRST_TICKET_AT: float = 0.15
const LAST_TICKET_AT: float = 4.2
const TICKET_JITTER: float = 0.35

## Lo que cuesta dejar vencer un ticket, y lo que sube Mamador por una hora.
const TICKET_POWER_COST: float = 5.0
const TICKET_MAMADOR_BOOST: int = 3
const TICKET_BOOST_HOURS: float = 1.0

## --- Esperas de las tareas --------------------------------------------------
## Casi toda tarea tiene un paso que tarda, con barra. En la noche 1 entre 10
## y 20 s; cada noche se alarga un 12 %.
const WAIT_MIN_SECONDS: float = 10.0
const WAIT_MAX_SECONDS: float = 20.0
const WAIT_GROWTH_PER_NIGHT: float = 0.12

## Lo que se ofende Ureña si le cuelgan: sube esto por una hora de juego.
const URENA_SNUB_BOOST: int = 5
const URENA_SNUB_HOURS: float = 1.0


## El plazo de un ticket esa noche, en horas de juego.
static func ticket_deadline_hours(night: int) -> float:
	return float(TICKET_DEADLINE_HOURS.get(clampi(night, FIRST_NIGHT, LAST_NIGHT), 2.0))


## A qué hora de la noche llega cada ticket, de 0 (12 AM) a 6 (6 AM).
static func ticket_times(night: int, count: int) -> PackedFloat32Array:
	var times: PackedFloat32Array = PackedFloat32Array()
	if count <= 0:
		return times
	times.append(FIRST_TICKET_AT)
	if count == 1:
		return times
	# Los demás, repartidos parejo hasta las 5 AM y movidos un poco al azar.
	var step: float = (LAST_TICKET_AT - FIRST_TICKET_AT) / float(count - 1)
	for i: int in range(1, count):
		var at: float = FIRST_TICKET_AT + step * float(i)
		at += randf_range(-TICKET_JITTER, TICKET_JITTER)
		times.append(clampf(at, FIRST_TICKET_AT, LAST_TICKET_AT))
	return times


## Lo que tarda un paso con espera esa noche, en segundos reales.
static func wait_seconds(night: int) -> float:
	var growth: float = 1.0 + float(maxi(night - 1, 0)) * WAIT_GROWTH_PER_NIGHT
	return randf_range(WAIT_MIN_SECONDS, WAIT_MAX_SECONDS) * growth


## La cara de Armando en la pantalla de Claudio no sale antes de esta noche.
const ARMANDO_PC_FROM_NIGHT: int = 4

## Lo máximo que acepta un nivel de IA, para la Custom Night del hito 6.
const MAX_AI_LEVEL: int = 20


## El nivel que le toca a un profe esa noche. Las noches fuera de la tabla
## usan la última, por si alguna vez hay noche 7 o Custom Night.
static func ai_level(night: int, who: String) -> int:
	return int(_for_night(night).get(who, 0))


## La velocidad del Come Trabas de esa noche, como índice de ComeTrabas.Speed.
static func come_trabas_speed(night: int) -> int:
	return int(_for_night(night).get(COME_TRABAS, 0))


## true si esta noche Armando ya puede aparecerse en la pantalla de Claudio.
static func armando_pc_enabled(night: int, armando_level: int) -> bool:
	return night >= ARMANDO_PC_FROM_NIGHT and armando_level > 0


## Para Custom Night: reparte un nivel de 1 a 20 entre las cuatro velocidades
## del Come Trabas, que no usa el dado de la IA.
static func speed_for_level(level: int) -> int:
	if level <= 5:
		return 0   # lenta
	if level <= 10:
		return 1   # media
	if level <= 15:
		return 2   # rápida
	return 3       # muy rápida


static func _for_night(night: int) -> Dictionary:
	if LEVELS.has(night):
		return LEVELS[night]
	return LEVELS.get(clampi(night, FIRST_NIGHT, LAST_NIGHT), LEVELS[LAST_NIGHT])
