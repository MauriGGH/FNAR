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
