class_name Calls
extends RefCounted

## Los guiones del teléfono. Cada noche tiene su mensaje, que suena a los
## pocos segundos de empezar. Son textos de ejemplo: los reales los escribirá
## el equipo, línea por línea, y aquí solo hay que cambiar el arreglo.

## Lo que tarda en sonar el teléfono al empezar la noche.
const NIGHTLY_CALL_DELAY: float = 3.0
## Lo que suena antes de darse por perdida. No contestar no tiene castigo.
const NIGHTLY_RING_TIME: float = 10.0

const BY_NIGHT: Dictionary = {
	1: [
		"Hola, bienvenido a la Coordinacion de Sistemas.",
		"Tu chamba es simple: aguantar de doce a seis.",
		"Si oyes pasos corriendo, cierra la chapa y ya.",
		"Ah, y no dejes la ventana del asistente abierta. Confia en mi.",
	],
	2: [
		"Segunda noche. Veo que no renunciaste.",
		"Barcosa se esconde en el salon B. Revisalo seguido.",
		"Si lo descuidas, viene corriendo. No te va a avisar.",
	],
	3: [
		"Tercera. Ya le vas cogiendo el modo.",
		"Hoy puede que suene el telefono otra vez. Contesta.",
		"En serio: contesta.",
	],
	4: [
		"Cuarta noche. Si ves luces en el techo, no subas.",
		"Y si una camara se queda sin señal, hay que ir al rack.",
		"La hoja del etiquetado esta pegada ahi. Leela, cambia cada noche.",
	],
	5: [
		"Quinta. Ya sabes como va esto.",
		"Hoy nada esta de tu lado. Cuida la cuerda.",
	],
	6: [
		"Sexta noche. Nadie llega a la sexta.",
		"Suerte.",
	],
}


## El guion de una noche. Las que no estén definidas usan el de la noche 1.
static func for_night(night: int) -> PackedStringArray:
	return PackedStringArray(BY_NIGHT.get(night, BY_NIGHT[1]))
