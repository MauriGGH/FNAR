shader_type canvas_item;

// Imagen de una vista de la oficina. Lo único que hace es el desenfoque
// horizontal que el script sube durante el giro de cabeza.
//
// Ya no corrige color: las fotos vienen con su color y su oscuridad finales,
// así que cualquier ganancia, saturación o brillo extra las estropearía.

// Desenfoque en fracción del ancho de la textura. 0 = imagen limpia.
uniform float blur_amount = 0.0;

const int TAPS = 4;

// El modulate del nodo no llega a fragment() por su cuenta: al escribir COLOR
// se perdería. Se trae del vertex, donde COLOR sí lo trae. Las fotos no lo
// usan (van en blanco), pero el tótem de la mesa sí: es lo que lo baja al
// brillo de la habitación.
varying vec4 node_modulate;

void vertex() {
	node_modulate = COLOR;
}

void fragment() {
	// Con blur_amount en 0 todas las muestras caen en el mismo punto,
	// así que la imagen sale idéntica y no hace falta ningún caso aparte.
	vec4 sum = vec4(0.0);
	float total = 0.0;
	for (int i = -TAPS; i <= TAPS; i++) {
		float offset = float(i) / float(TAPS);
		float weight = 1.0 - abs(offset) * 0.55;
		sum += texture(TEXTURE, UV + vec2(offset * blur_amount, 0.0)) * weight;
		total += weight;
	}
	COLOR = (sum / total) * node_modulate;
}
