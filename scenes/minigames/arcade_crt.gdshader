shader_type canvas_item;

// La pantalla de la maquinita, encima de todo el minijuego: scanlines
// marcadas, la curvatura del tubo con las esquinas oscurecidas, los colores
// separándose en los bordes, un parpadeo muy leve y, de vez en cuando, una
// línea de interferencia que baja.
//
// Va sobre el SubViewportContainer, así que su TEXTURE es la imagen del juego
// ya renderizada a 160x90.

// Cuántas scanlines y cuánto oscurecen.
uniform float lines = 90.0;
uniform float line_strength : hint_range(0.0, 1.0) = 0.24;
// Lo que se curva el tubo y lo que se oscurecen las esquinas.
uniform float curve : hint_range(0.0, 0.5) = 0.07;
uniform float vignette : hint_range(0.0, 2.0) = 0.9;
// La separación de color, en fracción de pantalla, solo en los bordes.
uniform float chroma : hint_range(0.0, 0.02) = 0.0025;
// El parpadeo: cuánto y a qué ritmo.
uniform float flicker : hint_range(0.0, 0.2) = 0.03;
// La línea de interferencia: cada cuánto pasa y lo gorda que es.
uniform float roll_every = 3.4;
uniform float roll_height : hint_range(0.0, 0.3) = 0.045;
// El apagón del final: 1 = normal, 0 = la imagen ya aplastada en una línea.
uniform float shutdown : hint_range(0.0, 1.0) = 1.0;
uniform float time_scale = 1.0;

void fragment() {
	float t = TIME * time_scale;
	vec2 uv = UV;
	// Lo que se queda negro: lo de fuera del tubo y lo de fuera de la raya del
	// apagón. No se puede cortar con `return` dentro de fragment(), así que se
	// marca aquí y se apaga al final.
	float dark = 0.0;

	// El apagón: la imagen se aplasta hacia el centro hasta ser una raya.
	float half_height = max(shutdown, 0.004) * 0.5;
	float from_center = (uv.y - 0.5) / half_height;
	if (shutdown < 1.0) {
		dark = max(dark, step(1.0, abs(from_center)));
		uv.y = 0.5 + from_center * 0.5;
	}

	// Curvatura: el centro queda igual y los bordes se estiran.
	vec2 centered = uv * 2.0 - 1.0;
	float r2 = dot(centered, centered);
	centered *= 1.0 + curve * r2;
	vec2 curved = centered * 0.5 + 0.5;
	dark = max(dark, step(curved.x, 0.0) + step(1.0, curved.x)
		+ step(curved.y, 0.0) + step(1.0, curved.y));
	curved = clamp(curved, vec2(0.0), vec2(1.0));

	// La separación de color crece con la distancia al centro.
	float edge = clamp(r2, 0.0, 1.0);
	float split = chroma * edge;
	vec4 color = texture(TEXTURE, curved);
	color.r = texture(TEXTURE, vec2(clamp(curved.x + split, 0.0, 1.0), curved.y)).r;
	color.b = texture(TEXTURE, vec2(clamp(curved.x - split, 0.0, 1.0), curved.y)).b;

	// Scanlines: una raya oscura cada dos píxeles del lienzo.
	float line = sin(curved.y * lines * 3.14159265);
	color.rgb *= 1.0 - line_strength * (0.5 + 0.5 * line);

	// La línea de interferencia, que baja de arriba abajo.
	float roll_y = fract(t / roll_every);
	float in_roll = 1.0 - smoothstep(0.0, roll_height, abs(curved.y - roll_y));
	color.rgb += in_roll * 0.12;

	// Esquinas oscurecidas y el parpadeo del tubo.
	color.rgb *= 1.0 - vignette * pow(edge, 2.4) * 0.55;
	color.rgb *= 1.0 - flicker * (0.5 + 0.5 * sin(t * 47.0));
	// Al apagarse, la raya que queda se pone blanca.
	if (shutdown < 1.0) {
		color.rgb = mix(vec3(1.0), color.rgb, clamp(shutdown * 1.4, 0.0, 1.0));
	}
	COLOR = vec4(color.rgb * (1.0 - clamp(dark, 0.0, 1.0)), 1.0);
}
