shader_type canvas_item;

// Imagen de una vista de la oficina. Hace dos cosas:
//   1. Corrección de color, para igualar vistas renderizadas por separado.
//   2. Desenfoque horizontal, que el script sube durante el giro de cabeza.
// Los valores los pone office.gd desde sus constantes.

// Ganancia por canal: bajar verde y azul respecto al rojo le quita el cian.
uniform vec3 channel_gain = vec3(1.0, 1.0, 1.0);
uniform float brightness = 1.0;
uniform float saturation = 1.0;
// Desenfoque en fracción del ancho de la textura. 0 = imagen limpia.
uniform float blur_amount = 0.0;

const int TAPS = 4;

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
	vec4 color = sum / total;

	color.rgb *= channel_gain;
	float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(vec3(luma), color.rgb, saturation);
	color.rgb *= brightness;
	COLOR = color;
}
