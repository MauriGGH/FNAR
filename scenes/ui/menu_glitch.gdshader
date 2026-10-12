shader_type canvas_item;

// El "lag" del menú: la imagen se desgarra por franjas horizontales, como una
// cinta que patina, y los colores se separan un poco, como una señal mala.
// Todo lo mueve menu_backdrop.gd; aquí no hay tiempo ni animación propia, para
// que el efecto se pueda congelar en seco.

// Lo que se corre una franja, en píxeles. 0 deja la imagen quieta.
uniform float tear_pixels : hint_range(0.0, 120.0) = 0.0;
// La separación de los canales de color, también en píxeles.
uniform float rgb_pixels : hint_range(0.0, 40.0) = 0.0;
// En cuántas franjas se parte la imagen.
uniform float bands : hint_range(1.0, 64.0) = 18.0;
// La ventana donde muerde el desgarro: su centro y su alto, en 0..1 de la
// imagen. Con un alto de 2.0 muerde en toda la imagen; con uno chico es una
// banda, y moviendo el centro se ve bajar.
uniform float tear_y : hint_range(-1.0, 2.0) = 0.5;
uniform float tear_height : hint_range(0.0, 2.0) = 2.0;
// Cambia el sorteo de las franjas, para que dos cuadros seguidos no se repitan.
uniform float noise_seed = 0.0;

// El modulate del nodo. En fragment() no se puede leer, así que se trae desde
// vertex(), donde COLOR es justo eso.
varying vec4 node_modulate;

void vertex() {
	node_modulate = COLOR;
}

// Cuánto y para dónde se corre una franja: un número al azar, pero siempre el
// mismo para la misma franja y la misma semilla. El valor nunca baja de 0.25,
// así que con tear_pixels en 40 las franjas se corren entre 10 y 40 px.
float band_shift(float band) {
	float r = fract(sin(band * 12.9898 + noise_seed * 78.233) * 43758.5453);
	float direction = r < 0.5 ? -1.0 : 1.0;
	return direction * mix(0.25, 1.0, fract(r * 7.0));
}

void fragment() {
	float px = 1.0 / float(textureSize(TEXTURE, 0).x);
	// Fuera de la ventana no se toca nada; el borde va suave.
	float edge = tear_height * 0.5;
	float window = 1.0 - smoothstep(edge, edge + 0.08, abs(UV.y - tear_y));

	vec2 uv = UV;
	uv.x = clamp(uv.x + band_shift(floor(UV.y * bands)) * tear_pixels * px * window,
		0.0, 1.0);
	vec4 base = texture(TEXTURE, uv);
	if (rgb_pixels > 0.0) {
		// La separación de color se nota algo también fuera de la ventana.
		float split = rgb_pixels * px * max(window, 0.3);
		base.r = texture(TEXTURE, clamp(vec2(uv.x + split, uv.y), 0.0, 1.0)).r;
		base.b = texture(TEXTURE, clamp(vec2(uv.x - split, uv.y), 0.0, 1.0)).b;
	}
	COLOR = base * node_modulate;
}
