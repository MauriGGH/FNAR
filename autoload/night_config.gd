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
# El gasto se define por hora de juego y no por segundo real, para que el modo
# prueba no vuelva la energía irrelevante.
const MAX_POWER: float = 100.0
const IDLE_DRAIN_PER_HOUR: float = 11.0  # consumo base de la oficina
const DOOR_DRAIN_PER_HOUR: float = 22.0    # extra mientras la puerta está cerrada
const CAMERA_DRAIN_PER_HOUR: float = 14.0  # extra mientras las cámaras están abiertas
const PC_DRAIN_PER_HOUR: float = 12.0      # extra mientras la PC está encendida


## Cuánto dura una hora de juego en segundos reales.
static func hour_duration() -> float:
	return TEST_HOUR_DURATION if TEST_MODE else HOUR_DURATION
