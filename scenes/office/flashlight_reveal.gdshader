shader_type canvas_item;

// La luz de la linterna sobre el pasillo. No se apunta: alumbra toda la franja
// donde pueden estar los profes, con el borde difuminado para que no se vea
// ninguna línea dura. Se usa para tres cosas con los mismos dos mandos:
//
//   - La foto iluminada del pasillo: fuera de la luz no se ve nada
//     (base_alpha 0), dentro se ve entera, y debajo queda la foto a oscuras.
//   - Los profes que solo existen con luz (Ureña, Juan.exe, Armando): igual.
//   - Los que se ven siempre (Mamador, Barcosa, el Mago): fuera se pintan
//     apagados (base_brightness 0.35) y dentro a todo brillo.
//   - Las siluetas del fondo del pasillo: fuera no se ven (base_alpha 0) y
//     dentro salen en penumbra (lit_brightness 0.55) y algo desenfocadas, para
//     que se note que están lejos y no pegadas al cristal.
//
// La zona iluminada es un rectángulo de esquinas suaves, no un círculo: el
// pasillo es ancho y bajo, y un círculo dejaría las puntas a oscuras.

// El centro de la luz y su media anchura y media altura, en normalizadas.
uniform vec2 beam_center = vec2(0.5, 0.5);
uniform vec2 beam_half = vec2(0.3, 0.3);
// Lo ancho del degradado del borde, hacia afuera.
uniform float beam_softness : hint_range(0.001, 0.5) = 0.14;
// 0 con la linterna apagada, 1 encendida. Lleva el parpadeo del foco.
uniform float beam_strength : hint_range(0.0, 1.0) = 0.0;
// Proporción de la vista (ancho/alto), para que el degradado sea igual de
// ancho por los lados que por arriba.
uniform float aspect = 1.78;

// Cómo se ve lo de fuera de la luz.
uniform float base_alpha : hint_range(0.0, 1.0) = 0.0;
uniform float base_brightness : hint_range(0.0, 1.0) = 1.0;
// Y cómo se ve lo de dentro. Casi todo entra a todo brillo; las siluetas del
// fondo, en penumbra, para que se lean como lejanas.
uniform float lit_brightness : hint_range(0.0, 1.0) = 1.0;
// Desenfoque, en fracción del ancho, fuera y dentro del cono. Las siluetas
// llevan el mismo por los dos lados: están lejos, con luz y sin ella.
uniform float outside_blur : hint_range(0.0, 0.05) = 0.0;
uniform float inside_blur : hint_range(0.0, 0.05) = 0.0;
// Desenfoque horizontal del giro de cabeza, en fracción del ancho. Lo sube y
// lo baja el script durante el barrido, y va para todo: la foto iluminada, los
// profes, las siluetas y la cortina. Manda sobre el de fuera del cono, porque
// mientras la cabeza gira no se distingue nada de todas formas.
uniform float motion_blur : hint_range(0.0, 0.2) = 0.0;

void fragment() {
	// Distancia al borde del rectángulo: 0 dentro, y crece hacia afuera.
	vec2 away = abs(UV - beam_center) - beam_half;
	away.x *= aspect;
	float outside = length(max(away, vec2(0.0)));
	float inside = (1.0 - smoothstep(0.0, beam_softness, outside)) * beam_strength;

	// El desenfoque va de uno a otro con el borde del cono.
	float blur = mix(outside_blur, inside_blur, inside);
	vec4 source;
	if (blur <= 0.0001) {
		source = texture(TEXTURE, UV);
	} else {
		source = vec4(0.0);
		for (int i = -2; i <= 2; i++) {
			for (int j = -2; j <= 2; j++) {
				source += texture(TEXTURE, UV + vec2(float(i), float(j) * aspect) * blur);
			}
		}
		source /= 25.0;
	}
	// El del giro va encima de todo: si está puesto, manda él.
	if (motion_blur > 0.0001) {
		source = vec4(0.0);
		for (int i = -3; i <= 3; i++) {
			source += texture(TEXTURE, UV + vec2(float(i) / 3.0 * motion_blur, 0.0));
		}
		source /= 7.0;
	}

	float alpha = mix(base_alpha, 1.0, inside);
	float brightness = mix(base_brightness, lit_brightness, inside);
	COLOR = vec4(source.rgb * brightness, source.a * alpha);
}
