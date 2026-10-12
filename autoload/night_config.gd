class_name NightConfig
extends RefCounted

## Valores de diseño de una noche. No es autoload: se usa como NightConfig.CONSTANTE
## desde cualquier script, gracias al class_name.


# --- Interruptores de desarrollo ---------------------------------------------
# Los dos únicos que hay que mover para pasar de "probando" a "jugando".
# Para la versión que les pases a tus amigos, los dos en false.
#
# TEST_MODE acorta la noche: cada hora dura TEST_HOUR_DURATION (10 s) en vez
# de HOUR_DURATION (75 s), así una noche entera cabe en un minuto. El consumo
# de energía NO cambia: se mide siempre contra los 75 s, así que en modo
# prueba la energía parece durar más porque la noche pasa más rápido.
#
# DEBUG_KEYS enciende todas las teclas de data/debug_keys.gd: F3 (la ayuda,
# las zonas de clic y el estado de los profes), F8 (energía infinita) y las
# que mandan a cada profe a su posición de ataque. En false no responde
# ninguna, ni siquiera F3, así que no hay manera de ver nada de depuración.
const TEST_MODE: bool = false
const DEBUG_KEYS: bool = true

const HOUR_DURATION: float = 75.0
const TEST_HOUR_DURATION: float = 10.0


# --- Reloj -------------------------------------------------------------------
const START_HOUR: int = 0  # 12 AM
const END_HOUR: int = 6    # 6 AM, la noche termina


# --- Partida -----------------------------------------------------------------
## La última noche de la historia. Al pasarla se termina el juego.
const LAST_NIGHT: int = 6
## Custom Night y Extras se abren al pasar esta noche.
const EXTRAS_FROM_NIGHT: int = 5
## Lo más largo que puede ser el nombre del guardia.
const MAX_NAME_LENGTH: int = 16


# --- Energía -----------------------------------------------------------------
# Los consumos se escriben por hora, pero se gastan contra la hora NORMAL de
# 75 s, nunca contra la del modo prueba: el modo prueba acorta la noche, no
# acelera la energía. Así la energía baja a la misma velocidad siempre.
const MAX_POWER: float = 100.0
## El consumo base de la oficina, por noche: la instalación va aguantando cada
## vez menos y la noche 6 arranca ya castigada. El índice es la noche menos 1.
const IDLE_DRAIN_BY_NIGHT: Array[float] = [8.0, 9.0, 10.0, 11.0, 12.0, 13.0]
## El de respaldo, por si alguien pregunta sin decir qué noche.
const IDLE_DRAIN_PER_HOUR: float = 9.0
const DOOR_DRAIN_PER_HOUR: float = 22.0    # extra mientras la puerta está cerrada
const CAMERA_DRAIN_PER_HOUR: float = 14.0  # extra mientras las cámaras están abiertas
const PC_DRAIN_PER_HOUR: float = 12.0      # extra mientras la PC está encendida
const FLASHLIGHT_DRAIN_PER_HOUR: float = 16.0  # extra mientras la linterna alumbra


# --- Linterna y los del cristal ----------------------------------------------
# La linterna ya no se apunta: alumbra todo el pasillo de golpe. Mantenerla
# encendida (o darle parpadeos rápidos) le va acumulando susto al que esté en
# el cristal; al llenarse, se va. La barra no se ve.
## Luz acumulada que hace falta para ahuyentar a uno del cristal.
const FLASH_FILL_TIME: float = 1.75
## Lo que tarda el susto en bajar de lleno a cero con la linterna apagada. Es
## mucho más lento que lo que tarda en subir, así que los parpadeos se suman.
const FLASH_DECAY_TIME: float = 5.0

## Lo que aguanta uno del cristal antes de entrar, en la primera y en la última
## noche; las de en medio se interpolan. Descontando los FLASH_FILL_TIME de luz,
## deja unos 7 s de margen en la noche 1 y unos 4 en la 6.
const GLASS_TIME_FIRST_NIGHT: float = 9.0
const GLASS_TIME_LAST_NIGHT: float = 5.5


## Lo que aguanta uno del cristal esa noche antes de entrar.
## El consumo base de esa noche. Una Custom Night se cuenta como la última.
static func idle_drain_per_hour(night: int) -> float:
	return IDLE_DRAIN_BY_NIGHT[clampi(night, 1, IDLE_DRAIN_BY_NIGHT.size()) - 1]


static func glass_time(night: int) -> float:
	var span: int = maxi(LAST_NIGHT - 1, 1)
	var t: float = float(clampi(night, 1, LAST_NIGHT) - 1) / float(span)
	return lerpf(GLASS_TIME_FIRST_NIGHT, GLASS_TIME_LAST_NIGHT, t)


## El margen de reacción que queda esa noche: lo que aguanta menos lo que
## cuesta ahuyentarlo. Lo usa el panel de pruebas para enseñarlo.
static func glass_margin(night: int) -> float:
	return glass_time(night) - FLASH_FILL_TIME


# --- Barcosa ------------------------------------------------------------------
## Barcosa no avanza de etapa con un dado: avanza cuando pasa demasiado tiempo
## **sin que lo revises** por la CAM 10, y verlo pone la cuenta otra vez a cero.
## Lo que aguanta sale de su nivel, que es lo que cambia por noche: con el de la
## noche 2 (3) son 45 s por etapa, y con el de la noche 6 (15), 15 s. Las de en
## medio se interpolan, y en una Custom Night con el nivel al tope nunca baja de
## BARCOSA_MIN_STAGE_TIME, para que siga siendo jugable.
const BARCOSA_EASY_LEVEL: int = 3
const BARCOSA_HARD_LEVEL: int = 15
const BARCOSA_EASY_STAGE_TIME: float = 45.0
const BARCOSA_HARD_STAGE_TIME: float = 15.0
const BARCOSA_MIN_STAGE_TIME: float = 8.0

## Y lo que tarda en cruzar el pasillo desde que sale hasta que llega a la
## puerta: 6 s con el nivel de la noche 2 y 3 s con el de la 6. Ese es el tiempo
## que tienes para cerrar cuando lo oyes venir corriendo.
const BARCOSA_EASY_RUN_TIME: float = 6.0
const BARCOSA_HARD_RUN_TIME: float = 3.0
const BARCOSA_MIN_RUN_TIME: float = 2.0


## Dónde cae un nivel de Barcosa entre el de la noche 2 y el de la noche 6.
## Por debajo o por encima se sigue la misma recta, de ahí que haya topes.
static func _barcosa_t(ai_level: int) -> float:
	var span: float = float(maxi(BARCOSA_HARD_LEVEL - BARCOSA_EASY_LEVEL, 1))
	return float(ai_level - BARCOSA_EASY_LEVEL) / span


## Lo que aguanta sin que lo revisen antes de subir una etapa.
static func barcosa_stage_time(ai_level: int) -> float:
	return maxf(lerpf(BARCOSA_EASY_STAGE_TIME, BARCOSA_HARD_STAGE_TIME,
		_barcosa_t(ai_level)), BARCOSA_MIN_STAGE_TIME)


## Lo que tarda en llegar a la puerta desde que sale corriendo.
static func barcosa_run_time(ai_level: int) -> float:
	return maxf(lerpf(BARCOSA_EASY_RUN_TIME, BARCOSA_HARD_RUN_TIME,
		_barcosa_t(ai_level)), BARCOSA_MIN_RUN_TIME)


# --- Breaker y cortaso -------------------------------------------------------
## Lo que dura la corriente cortada cuando se baja la palanca.
const BLACKOUT_TIME: float = 3.0
## Lo que hay que esperar, después, para poder volver a bajarla.
const BREAKER_COOLDOWN: float = 10.0
## Energía que se pierde de golpe con el cortaso de Audel.
const CORTASO_POWER_LOSS: float = 15.0
## Lo que la linterna queda inservible después del cortaso.
const FLASHLIGHT_DISABLED_TIME: float = 45.0


## Cuánto dura una hora de juego en segundos reales. Solo para el reloj.
static func hour_duration() -> float:
	# El panel de pruebas puede forzarlas cortas sin tocar la constante.
	if GameManager.force_short_hours:
		return TEST_HOUR_DURATION
	return TEST_HOUR_DURATION if TEST_MODE else HOUR_DURATION


## Los segundos contra los que se mide el consumo de energía. A diferencia de
## hour_duration(), este no cambia en modo prueba.
static func power_hour_duration() -> float:
	return HOUR_DURATION
