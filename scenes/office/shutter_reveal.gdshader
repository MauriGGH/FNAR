shader_type canvas_item;

// La cortina metálica de la puerta, igual que el fondo del pasillo: tiene dos
// fotos, la de a oscuras y la iluminada, y la linterna decide cuál se ve.
//
//   - `TEXTURE` es `cortina_capa.png`, la iluminada.
//   - `dark_texture` es `cortina_capa_oscura.png`, la misma lámina sin luz.
//
// Las dos están alineadas entre sí y con la vista, así que se muestrean con
// las mismas UV y la lámina no se mueve ni un píxel al cambiar de una a otra.

uniform sampler2D dark_texture : source_color, filter_linear;

// El cono de la linterna, igual que en flashlight_reveal.gdshader.
uniform vec2 beam_center = vec2(0.5, 0.5);
uniform vec2 beam_half = vec2(0.3, 0.3);
uniform float beam_softness : hint_range(0.001, 0.5) = 0.14;
uniform float beam_strength : hint_range(0.0, 1.0) = 0.0;
uniform float aspect = 1.78;
// El desenfoque del giro de cabeza, que va para toda la vista.
uniform float motion_blur : hint_range(0.0, 0.2) = 0.0;

varying vec4 node_modulate;

void vertex() {
	node_modulate = COLOR;
}

void fragment() {
	vec2 away = abs(UV - beam_center) - beam_half;
	away.x *= aspect;
	float outside = length(max(away, vec2(0.0)));
	float inside = (1.0 - smoothstep(0.0, beam_softness, outside)) * beam_strength;

	vec4 lit = texture(TEXTURE, UV);
	vec4 dark = texture(dark_texture, UV);
	if (motion_blur > 0.0001) {
		lit = vec4(0.0);
		dark = vec4(0.0);
		for (int i = -3; i <= 3; i++) {
			vec2 at = UV + vec2(float(i) / 3.0 * motion_blur, 0.0);
			lit += texture(TEXTURE, at);
			dark += texture(dark_texture, at);
		}
		lit /= 7.0;
		dark /= 7.0;
	}
	COLOR = mix(dark, lit, inside) * node_modulate;
}
