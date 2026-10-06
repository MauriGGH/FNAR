shader_type canvas_item;

// Capa encima del escritorio: líneas de escaneo y oscurecimiento de las orillas
// que imita la curvatura del tubo. Solo pinta negro con distinta opacidad, así
// que no mueve ni un píxel del contenido y los clics siguen cayendo donde deben.

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.16;
uniform float scanline_count = 260.0;
uniform float tube_edge : hint_range(0.0, 1.0) = 0.55;
uniform float tube_center : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	float scan = 0.5 + 0.5 * sin(UV.y * scanline_count * 6.2831853);
	float darkness = scanline_strength * (1.0 - scan);

	// Caja redondeada: con exponente 4 las esquinas caen antes que los lados,
	// que es lo que da la sensación de pantalla abombada.
	vec2 centered = (UV - 0.5) * 2.0;
	float box = pow(abs(centered.x), 4.0) + pow(abs(centered.y), 4.0);
	darkness += smoothstep(0.55, 1.45, box) * tube_edge;
	darkness += dot(centered, centered) * tube_center * 0.25;

	COLOR = vec4(0.0, 0.0, 0.0, clamp(darkness, 0.0, 1.0));
}
