class_name NightConfig
extends RefCounted

## Valores de diseño de una noche. No es autoload: se usa como NightConfig.CONSTANTE
## desde cualquier script, gracias al class_name.


# --- Modo prueba -------------------------------------------------------------
# Con TEST_MODE activo cada hora dura TEST_HOUR_DURATION en vez de HOUR_DURATION,
# para poder probar una noche entera en un minuto.
const TEST_MODE: bool = true

const HOUR_DURATION: float = 75.0
const TEST_HOUR_DURATION: float = 10.0


# --- Reloj -------------------------------------------------------------------
const START_HOUR: int = 0  # 12 AM
const END_HOUR: int = 6    # 6 AM, la noche termina


# --- Energía -----------------------------------------------------------------
# Los consumos se escriben por hora, pero se gastan contra la hora NORMAL de
# 75 s, nunca contra la del modo prueba: el modo prueba acorta la noche, no
# acelera la energía. Así la energía baja a la misma velocidad siempre.
const MAX_POWER: float = 100.0
const IDLE_DRAIN_PER_HOUR: float = 11.0  # consumo base de la oficina
const DOOR_DRAIN_PER_HOUR: float = 22.0    # extra mientras la puerta está cerrada
const CAMERA_DRAIN_PER_HOUR: float = 14.0  # extra mientras las cámaras están abiertas
const PC_DRAIN_PER_HOUR: float = 12.0      # extra mientras la PC está encendida


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
	return TEST_HOUR_DURATION if TEST_MODE else HOUR_DURATION


## Los segundos contra los que se mide el consumo de energía. A diferencia de
## hour_duration(), este no cambia en modo prueba.
static func power_hour_duration() -> float:
	return HOUR_DURATION
