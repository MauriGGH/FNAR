shader_type canvas_item;

// Capa oscura encima de la cámara: líneas de escaneo que bajan despacio
// y viñeta que oscurece los bordes. Solo pinta negro con distinta opacidad.

uniform float scanline_strength : hint_range(0.0, 1.0) = 0.22;
uniform float scanline_count = 180.0;
uniform float scanline_speed = 0.02;
uniform float vignette_start : hint_range(0.0, 1.0) = 0.3;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	float scan = 0.5 + 0.5 * sin((UV.y + TIME * scanline_speed) * scanline_count * 6.2831853);
	float darkness = scanline_strength * (1.0 - scan);

	// distance() llega a 0.7071 en las esquinas, así que lo normalizo a 0..1.
	float edge = distance(UV, vec2(0.5)) * 1.4142;
	darkness += smoothstep(vignette_start, 1.0, edge) * vignette_strength;

	COLOR = vec4(0.0, 0.0, 0.0, clamp(darkness, 0.0, 1.0));
}
