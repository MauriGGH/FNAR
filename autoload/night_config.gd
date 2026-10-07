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
const IDLE_DRAIN_PER_HOUR: float = 11.0  # consumo base de la oficina
const DOOR_DRAIN_PER_HOUR: float = 22.0    # extra mientras la puerta está cerrada
const CAMERA_DRAIN_PER_HOUR: float = 14.0  # extra mientras las cámaras están abiertas
const PC_DRAIN_PER_HOUR: float = 12.0      # extra mientras la PC está encendida
const FLASHLIGHT_DRAIN_PER_HOUR: float = 16.0  # extra mientras la linterna alumbra


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
