# Five Nights at Rocha's

Juego de supervivencia estilo FNAF 2 hecho en Godot 4.7 con GDScript. El jugador es el guardia nocturno de un campus universitario y sobrevive de 12 AM a 6 AM en la oficina de la Coordinación de Sistemas, vigilando cámaras y defendiéndose de las almas de profesores ficticios.

El documento de diseño completo lo tiene el equipo; este archivo resume lo necesario para programar.

## Entorno

- Godot 4.7.2, renderizador Compatibilidad, proyecto 2D.
- Arranca en pantalla completa (stretch `canvas_items`, aspecto `keep`). F11 la alterna desde cualquier pantalla y la opción se guarda en `save.cfg`; también está como botón en el menú principal y en la pausa. Lo lleva el autoload `DisplayManager`.
- Desarrollo en Linux; la exportación principal es Windows (.exe), Linux opcional.
- El usuario es principiante en desarrollo de videojuegos: explica brevemente lo que haces y por qué, y dile cómo probarlo en Godot.

## Convenciones de código

- GDScript con tipado estático (`var energia: float = 100.0`, `func avanzar() -> void:`).
- Nombres de archivos, nodos, variables y funciones en inglés con snake_case; comentarios en español.
- Comunicación entre sistemas con señales; nada de referencias rígidas entre escenas cuando una señal basta.
- Valores de diseño (tiempos, niveles de IA, consumo de energía) en constantes o recursos, nunca números mágicos sueltos.
- No inventes rutas a imágenes que no existen.
- Cambios pequeños y probables: una tarea a la vez. Al terminar, di cómo probarlo y sugiere un mensaje de commit.

## Estructura de carpetas

```
res://
  autoload/        game_manager.gd, power_manager.gd, save_game.gd, display_manager.gd, audio_manager.gd
  scenes/          main_menu, night, office, camera_system, pc_screen, game_over, win_screen
  scenes/tasks/    una escena por tarea (minijuego)
  scripts/characters/  animatronic.gd (clase base) y un script por profe
  data/            rooms.gd (grafo de habitaciones), nights.gd (niveles por noche)
  tools/           programas de medir (capas de la oficina, caras de los expedientes) y de generar voces
  scenes/ui/           pantalla de carga, los cuadros de estática y los shaders compartidos (scanlines, blanco y negro, bloqueado)
  scripts/ui/          ayudantes: fonts.gd, menu_style.gd, menu_list.gd, screen_fx.gd, art_gallery.gd, star_row.gd, menu_backdrop.gd, options_panel.gd, screen_capture.gd
  scripts/audio/       tone_builder.gd, los sonidos provisionales generados por código
  assets/art/backgrounds, assets/art/characters, assets/audio
  assets/art/screens/  las pantallas que son una imagen (solicitud_empleo, pago_noche) y static/
  assets/fonts/        VT323, Special Elite, Oswald, Share Tech Mono, DSEG14, Reenie Beanie y game_theme.tres
```

## Sistemas principales

- **GameManager (autoload):** noche actual, reloj de 12 a 6 AM (cada hora dura unos 75 s), nombre del jugador, victoria y game over con la causa.
- **PowerManager (autoload):** energía de 0 a 100 %. Gastan: puerta cerrada, linterna, cámaras y PC
  abiertas. El **consumo base sube por noche** (`NightConfig.IDLE_DRAIN_BY_NIGHT`: 8, 9, 10, 11, 12
  y 13 %/hora de la noche 1 a la 6; una Custom Night cuenta como la última), que es la manera de
  apretar sin tocar ninguna mecánica. En 0 % todo se apaga. El breaker corta la corriente unos segundos; la chapa de la puerta está en un no-break y sigue funcionando.
- **Grafo de habitaciones:** cada lugar es un id con conexiones. Los profes avanzan por rutas definidas.
- **Animatronic (clase base):** nivel de IA 0 a 20, posición actual, ruta. Cada intervalo tiene una oportunidad de moverse: si `randi_range(1, 20) <= ai_level`, avanza. Cada profe hereda y sobrescribe solo lo que lo hace único.
- **Sistema de cámaras:** 13 cámaras. Cada estado de una cámara es una imagen completa ya renderizada con los profes integrados (como en FNAF), por ejemplo `cam04_desplomada`, `cam04_despertando`, `cam04_vacia`; las pocas combinaciones de varios profes en la misma cámara tienen su propia imagen. Algunos estados tienen una variante rara (el profe mirando de frente, muy cerca de la cámara) que aparece de vez en cuando en lugar de la normal. Cuando un profe entra o sale de la cámara que el jugador está viendo, la imagen se cubre de estática fuerte entre 0.5 y 1 s y al aclararse ya muestra el nuevo estado. Mientras no haya imágenes, se usan etiquetas de texto.
- **Oficina:** tres vistas, con dos movimientos que no se pisan.
  - **El mouse mueve la vista por dentro.** Cada vista se dibuja al **112 %** de la pantalla y se
    desplaza hacia donde está el cursor: hasta **±6 % a lo ancho y ±2 % a lo alto**, suavizado y
    con una zona muerta en el centro para que no tiemble. **El mouse nunca cambia de vista**,
    aunque lo dejes pegado al borde.
  - **A y D (o las flechas) cambian de vista.** Un toque y la cabeza gira a la de al lado con un
    barrido de 0.35 s. No hay que mantener nada.
  - **Desenfoque de movimiento** (`scenes/office/office_view.gdshader`): durante el barrido la
    imagen se corre en horizontal, creciendo hasta la mitad del giro y apagándose al llegar
    (`MAX_SWEEP_BLUR_PIXELS`, 24 px). El parallax del mouse lleva el mismo desenfoque pero
    **mucho más leve** (`MAX_PAN_BLUR_PIXELS`, 5 px) y solo cuando se mueve rápido: a
    `PAN_BLUR_FULL_SPEED` (900 px/s) ya está al tope. Se pide en píxeles de pantalla; el shader lo
    pasa a fracción del ancho de la vista.
  Todo lo que se ve en una vista (zonas de clic, recortes de profes, siluetas, cortina, luz de la
  linterna) cuelga de su nodo `Content`, así que se mueve con la imagen sin tocarlo aparte y los
  clics siguen cayendo en su objeto. Mientras la cabeza gira o la vista se acerca a la PC o al
  breaker manda el tween, no el parallax, para que no se peleen por la posición. Abrir y cerrar el
  monitor no cambia de vista. Al frente, mampara de cristal hacia la recepción y el pasillo, con la puerta de entrada (chapa magnética) al fondo: de ahí vienen Barcosa, Mamador y Ureña. Al costado, mampara con un marco sin puerta hacia la franja de los cubículos y la escalera al techo: de ahí vienen Rochis, el Mago Eléctrico y la botarga del Come Trabas. Linterna hacia el pasillo, breaker, PC.
  Las fotos son de **1375x768** y vienen con su color y su oscuridad finales: el código **no les
  pone ningún filtro, tinte ni modulate**; el shader de vista solo hace el desenfoque del giro.
  La vista central está **a oscuras**, como el pasillo de FNAF 2: de fondo va
  `oficina_centro_oscura.jpeg` y la foto iluminada (`oficina_centro.jpeg`) solo se ve **donde
  alumbra la linterna**. Con la cortina abajo se cambian las dos por
  `oficina_centro_oscura_cerrada.jpeg` y `oficina_centro_cerrada.jpeg`. La linterna **no se apunta**: ilumina de golpe toda la franja del
  pasillo, con el borde difuminado y sin ninguna línea dura
  (`scenes/office/flashlight_reveal.gdshader`), y el foco parpadea un poco. Se mantiene con Ctrl o
  con el clic izquierdo sostenido sobre el cristal, y gasta energía mientras está encendida.

## Audio

Todo el sonido pasa por el autoload **AudioManager**: nadie carga un archivo a mano ni pone un
`AudioStreamPlayer` en una escena. Se le pide un sonido por su id del catálogo
(`data/sounds.gd`), que dice el archivo que espera en `assets/audio/`, el bus y el volumen.

**Si el archivo de verdad no está**, el AudioManager usa el provisional que genera
`scripts/audio/tone_builder.gd` y lo avisa **una sola vez** en consola (`[audio] <id>: falta
<archivo>, suena el provisional`). Para meter un sonido real basta con dejar el archivo con ese
nombre en `assets/audio/`: no hay que tocar código.

**Buses** (en `assets/audio/buses.tres`): Master, Ambiente, Efectos, Voces, Música y **Lejos**.
El de Lejos es para lo que se oye a través de las paredes: manda al Ambiente con −8 dB y lleva un
paso bajo a 2500 Hz, una reverb grande y un paneo que el AudioManager mueve según de dónde venga
cada sonido (izquierda los cubículos y la escalera, centro el pasillo, derecha la sala de
servidores). Como un `AudioStreamPlayer` no tiene paneo propio, el del bus se cambia justo antes
de soltar el sonido; si dos lejanos de lados opuestos se pisaran, mandaría el último, pero son
cosas sueltas y espaciadas. El jugador
los sube y los baja en el menú de opciones y queda guardado en `save.cfg`. El TTS no sale por los
buses, así que quien habla multiplica su volumen por `AudioManager.voice_volume()` a mano.

**Los ruidos no se leen.** Mientras un sonido no esté grabado, el juego **no** escribe
"[pasos corriendo]" en pantalla: esos avisos van por `NoticeBanner.show_sound()`, que solo los
saca por consola y nada más cuando el panel de pruebas está encendido (`DebugKeys.is_enabled()`).
La banda de avisos se queda para lo que el jugador sí tiene que leer (un ticket nuevo, la linterna
muerta), que va por `show_notice()`.

**Qué falta por grabar:** cada entrada del catálogo lleva un campo `"desc"` con cómo tiene que
sonar, y `scripts/audio/missing_audio_report.gd` escribe con eso **`docs/audios_faltantes.md`**:
los ids sin archivo, separados entre los que tienen provisional y los que no suenan, con el nombre
exacto que se espera. Se regenera desde F1 → Audio; no se edita a mano.

**Opciones:** `scripts/ui/options_panel.gd` es una capa que se abre encima de lo que haya, así que
sirve igual en el menú principal y en la pausa de una noche sin cambiar de escena. Lleva los cinco
deslizadores y la pantalla completa, y todo se guarda al momento.

**El catálogo** (72 ids; la lista de los que faltan por grabar está en `docs/audios_faltantes.md`). Todos tienen provisional por código salvo `es_impresionante`, que
mientras no esté grabada la voz de Rochis la dice la síntesis de voz.

| id | archivo | bus | dB | bucle | cuándo suena |
| --- | --- | --- | --- | --- | --- |
| `ambiente_oficina` | `ambiente_oficina.ogg` | Ambiente | −14 | sí | toda la noche; se calla con el apagón |
| `ambiente_pasillo` | `ambiente_pasillo.ogg` | Ambiente | −20 | sí | toda la noche |
| `estatica_camara` | `estatica_camara.ogg` | Ambiente | −22 | sí | mientras el monitor está abierto |
| `menu_blip` | `menu_blip.ogg` | Efectos | −16 | sí | moverse por un menú y aceptar (lo mismo, más agudo) |
| `tecla_maquina` | `tecla_maquina.ogg` | Efectos | −12 | sí | el respaldo de la tecla, si no están las tres grabaciones |
| `tecla_maquina_1`…`3` | `tecla_maquina_N.ogg` | Efectos | −12 | no | cada tecla al escribir el nombre en la solicitud |
| `cajita_musical` | `cajita_musical.ogg` | Música | −16 | sí | la botarga, mientras le quede cuerda |
| `cajita_musical_apagon` | `cajita_musical.ogg` | Música | −4 | no | las chispas del apagón (mismo archivo) |
| `telefono_timbre` | `telefono_timbre.ogg` | Efectos | −6 | sí | mientras el teléfono suena |
| `tono_ocupado` | `tono_ocupado.ogg` | Efectos | −6 | no | al colgarle a Ureña |
| `ticket_nuevo` | `ticket_nuevo.ogg` | Efectos | −4 | no | llega un ticket |
| `puerta_cortina` | `puerta_cortina.ogg` | Efectos | −5 | no | la cortina al bajar o subir |
| `golpes_cortina` | `golpes_cortina.ogg` | Efectos | −3 | no | cada golpe de Barcosa |
| `golpe_metal_1`…`3` | `golpe_metal_N.ogg` | Efectos | −3 | no | cada porrazo de Barcosa, uno al azar sin repetir |
| `llavero` | `llavero.ogg` | Lejos | −4 | no | el llavero de Mamador, con sus pasos al moverse |
| `extras_musica` | `extras_musica.ogg` | Música | −14 | sí | música de Extras y de la Custom Night |
| `camara_cambio` | `camara_cambio.ogg` | Efectos | −10 | no | abrir cámaras y cambiar de una a otra |
| `linterna_click` | `linterna_click.ogg` | Efectos | −14 | no | prender y apagar la linterna |
| `breaker_palanca` | `breaker_palanca.ogg` | Efectos | −6 | no | bajar el breaker |
| `se_aleja` | `se_aleja.ogg` | Efectos | −3 | no | uno del cristal se va con el cuarto destello |
| `pasos_acercandose` | `pasos_acercandose.ogg` | Efectos | −2 | no | los tres pasos del apagón |
| `golpe_grave` | `golpe_grave.ogg` | Efectos | 0 | no | el cuadro de una alucinación |
| `golpe_grave_menu` | `golpe_grave.ogg` | Efectos | −10 | sí | el tic del fondo de los menús (mismo archivo) |
| `grito` | `grito.ogg` | Efectos | 0 | no | el jumpscare |
| `grito_<id>`, `grito_base_1`…`3` | `gritos/<id>.ogg` | Efectos | 0 | no | el grito de cada jumpscare y los tres de reserva |
| `mamador_brecha` | `mamador_brecha.ogg` | Efectos | 0 | no | la irrupción del operativo, antes del WASTED |
| `despertador` | `despertador.ogg` | Efectos | −8 | no | las campanadas de las 6 AM; **ya traen el grito de los niños al final** |
| `campana_escuela` | `campana_escuela.ogg` | Efectos | −4 | no | al entrar el 6 |
| `ninos_yay` | `ninos_yay.ogg` | Efectos | −3 | no | los niños al entrar el 6; solo se usa si no está grabado el despertador |
| `menu_musica` | `menu_musica.ogg` | Música | −14 | sí | música de fondo del menú principal |
| `es_impresionante` | `es_impresionante.ogg` | Voces | −2 | no | el botón de la CAM 3 (si no, la voz sintética) |
| `llamada_noche1`…`6` | `llamadas/llamada_nocheN.ogg` | Voces | 0 | no | la llamada con la que empieza esa noche |
| `telefono_colgar` | `telefono_colgar.ogg` | Efectos | −6 | no | al acabar o silenciar una llamada |
| 7 líneas sueltas | `voces/<id>.ogg` | Voces | 0 | no | ver **Líneas sueltas de profe** |

## Llamadas de inicio de noche

Como el Phone Guy de FNAF: a los 3 s de empezar la noche el teléfono timbra 10 s y, si
se contesta, se reproduce **audio grabado con subtítulos**. No bloquea el juego: se sigue
usando el monitor, la puerta y la linterna, y hay un botón **"Silenciar llamada"** que la
corta en cualquier momento.

- **Audio:** `assets/audio/llamadas/llamada_nocheN.ogg`, por el bus Voces. **Una noche tiene
  llamada si existe ese archivo**; si falta, el teléfono no suena esa noche y no pasa nada.
- **Subtítulos:** `data/llamadas/llamada_nocheN.txt`, una línea por frase con el formato
  `m:ss|texto`. El tiempo admite centésimas (`1:09.45`) y también vale un número de segundos a
  secas. Las líneas que empiezan con `#` y las vacías se ignoran, y cada frase se queda hasta que
  entra la siguiente.
- **`@offset=X`:** una línea así, en cualquier sitio del archivo, suma X segundos (con decimales
  y con signo) a **todos** los tiempos. Sirve para cuadrar los subtítulos cuando al audio se le
  recorta o se le añade silencio al principio, sin reescribir línea por línea.
- **El archivo de la llamada es solo voz.** El timbre (`telefono_timbre`, en bucle hasta que se
  contesta) y el clac de colgar (`telefono_colgar`, al acabar o al silenciar) los pone el juego.
- Van **abajo al centro**, como mucho dos líneas, en VT323 sobre un fondo semitransparente
  (`scenes/phone/call_subtitles.gd`). El tiempo se lee de la posición del audio, no de un
  contador propio, así que no se desfasan si el juego da un tirón.
- El guion completo para grabar las noches que faltan está en `docs/guion_voces.md`.

La llamada de Ureña es otra cosa y sigue como estaba: conversación con respuestas, en la
ventanita de la esquina y con síntesis de voz.

## Música y sonidos lejanos

**Música:** lo único con melodía es la cajita de la botarga, `assets/audio/cajita_musical.ogg`
(28.3 s, empalma sin corte). Funciona como en FNAF 2: **solo se oye con la CAM 4 en pantalla**. En
la oficina no se oye... salvo cuando a la botarga le queda menos del 25 % de cuerda
(`ComeTrabas.WARNING_THRESHOLD`): ahí entra `cajita_musical_aviso`, el mismo archivo a −22 dB por
el bus Lejos, muy bajito y con eco, como aviso de que hay que ir a dársela.

**El tono baja con la cuerda.** Por encima del 25 % suena normal; de ahí para abajo se va volviendo
grave y lenta de forma continua, hasta 0.80 al llegar a cero, como un juguete al que se le acaba la
pila (`ComeTrabas.music_pitch()`, que vale igual para la de la CAM 4 y para el aviso lejano).

**Los tiempos de la canción** están en `data/audio/cajita_musical_notas.json`: `pulsos` (el ritmo,
53) y `notas` (cada ataque, 118), más la duración. Los lee `data/music_box.gd`, que si el JSON
falta se cae a los tiempos del provisional de `tone_builder.gd`. Las chispas del apagón parpadean
**una por pulso** con esos tiempos.

No hay ningún otro bucle con melodía. El zumbido de lámparas y ventilador (`ambiente_oficina`) se
queda como estaba. **De qué canción se trata no se dice en ningún texto**: ni el nombre, ni el
número, ni el autor. Solo se oye.

**Sonidos lejanos** (`scenes/night/distant_sounds.gd`): cada profe tiene el suyo, con probabilidad
(55 %, y 90 % el de Barcosa) y un mínimo de 6 s entre dos del mismo. Los de sitio van en bucle
mientras el profe esté ahí.

| id | Cuándo suena | Qué es |
| --- | --- | --- |
| `barcosa_corre` | Al salir de la CAM 10 | Pasos rápidos que se acercan |
| `mamador_pasos` | Al cambiar de cuarto | Botas pesadas y un radio con estática |
| `urena_banos` | En bucle, mientras está en los baños | Agua de lavabo |
| `juan_teclado` | En bucle, en la sala de juntas | Tecleo lejano |
| `armando_modem` | Al cambiar de cuarto | Módem negociando, distorsionado |
| `audel_chispa` | En bucle, mientras está en el techo | Zumbido eléctrico y un trueno |
| `rochis_silla` | Al cambiar de etapa en la silla | Rechinido de silla |
| `lejos_portazo`, `lejos_silla`, `lejos_pasos_arriba`, `lejos_risa`, `lejos_platos` | Uno al azar cada 40 a 120 s | Ambiente de un edificio vacío |

Los archivos van en `assets/audio/lejos/<id>.ogg`. Mientras no estén, suenan los provisionales de
`tone_builder.gd`.

## Líneas sueltas de profe

Frases de una sola tirada que dicen los profes en la oficina, con su **subtítulo pequeño** abajo
(encima de los de la llamada, para que no se tapen). Los textos y los ids están en
`data/voice_lines.gd`; los archivos van en `assets/audio/voces/<id>.ogg`, por el bus Voces.
**Mientras no estén grabadas las dice la síntesis de voz** y el subtítulo sale igual, así que la
mecánica se entiende desde el primer día.

| Cuándo | Ids | Qué dice |
| --- | --- | --- |
| Barcosa empieza a aporrear la puerta (una al azar) | `barcosa_puerta_1/2/3` | "¿Quién cerró? Tengo clase en este salón." · "Abra, joven. Nada más paso lista y me voy." · "Diez minutos. Le estoy pidiendo diez minutos." |
| Barcosa se rinde y se va | `barcosa_se_va` | "Bueno, ya. Quedan todos con falta." |
| Mamador inspecciona y no encuentra nada (una al azar) | `mamador_ok_1/2/3` | "Sin novedad. Me retiro." · "Nada de inteligencia artificial. Así me gusta." · "Todo en orden. Sigan así." |

El profe las pide con la señal `said_line(id)` de `Animatronic`; el `night.gd` se la pasa al nodo
`Hud/VoiceLine`, que decide entre la grabación y la voz sintética.

**El nombre del jugador no se dice nunca en voz**, porque no se puede grabar:

- El saludo de Ureña se **lee** con el nombre y se **oye** sin él (`GREETING` y `GREETING_SPOKEN`).
- Rochis ya no lo pronuncia: al entrar, su nombre sale **escrito en rojo y grande sobre el
  jumpscare** (`Animatronic.jumpscare_caption()`, que solo él rellena).

## Tipografías

Las familias viven en `assets/fonts/` y se piden siempre por `Fonts` (`scripts/ui/fonts.gd`), que
las cachea. El Theme global `assets/fonts/game_theme.tres` pone Oswald en todo; las demás van como
override donde toca. `Fonts.by_name()` resuelve la que pide un dato por su nombre, que es como la
eligen los campos de `data/pantallas_campos.json`.

| Fuente | Cómo se pide | Para qué | Licencia |
| --- | --- | --- | --- |
| VT323 | `Fonts.terminal()` | lo que sale de una pantalla o un aparato: cámaras, PC, relojes, breaker, patch panel, y el título del menú | OFL |
| Special Elite | `Fonts.typewriter()` | lo escrito a máquina: documentos, periódicos, causa del game over, los campos de la solicitud y del recibo | Apache 2.0 |
| Oswald (variable) | `Fonts.menu()` | menús, botones y etiquetas | OFL |
| Share Tech Mono | `Fonts.mono()` | el reloj de la intro de noche | OFL |
| DSEG14 Classic Bold | `Fonts.digital()` | el display de segmentos del 6 AM | OFL |
| Reenie Beanie | `Fonts.hand()` | lo escrito a mano: la firma de la solicitud y la nota del recibo | OFL |

## Tutorial de la noche 1

La primera vez que alguien juega la noche 1 sale un recuadro arriba a la izquierda con los
controles, en VT323 sobre negro semitransparente (`scenes/night/controls_card.gd`). Se cierra con
Esc o con la X, y se puede volver a abrir desde la pausa, con el botón **"Controles"**. Queda
apuntado en `save.cfg` (`tutorial_seen`), así que solo sale solo una vez.

**No pausa el juego** —se puede mirar y moverse con él puesto— pero la primera vez **el reloj no
avanza** mientras esté abierto (`GameManager.set_clock_held()`), para que nadie se gaste media
noche leyendo. Abierto desde la pausa no hace falta: ahí ya está todo parado.

Los controles **no se escriben a mano** en el recuadro: salen de `data/controls.gd`, que lee del
mapa de entrada los que son acciones (mirar, abrir el monitor) y define **una sola vez** los que
estaban a fuego en el código (`FLASHLIGHT_KEY`, `PAUSE_KEY`), que ahora `office.gd` y
`pause_menu.gd` piden de ahí. Si cambias una tecla, el tutorial cambia solo.

## Estilo de los menús

Todos los menús son iguales por dentro y se ven igual: **negro, VT323 blanco y nada más**. Nada de
paneles grises, bordes redondeados, sombras ni degradados. Vale para el menú principal, la pausa,
las opciones, la Custom Night, Extras, la confirmación de borrado, el final y el game over.
**Quedan fuera** la PC, el patch panel y las hojas (documentos, recibos y periódicos), que tienen
su propia estética.

- **`scripts/ui/menu_style.gd` (`MenuStyle`)** guarda los colores, los tamaños medidos a 1080p (que
  se escalan con el alto), el negro de fondo, el título y el pie de pantalla, y el blip. Los
  títulos van en VT323 grande y en **mayúsculas**, arrancando en el margen izquierdo. Los tamaños
  son **grandes a propósito**, para que se lean de lejos: título de pantalla 56 px, opciones 44 px,
  pies 22 px, y el título del menú principal 72 px en sus cuatro renglones.
- **Las capas que se abren encima de otro menú** (Opciones, la confirmación de borrado) ponen un
  negro al **90 %** y **esconden la lista de abajo** mientras están abiertas, para que no se lea
  nada por detrás; al cerrarse la vuelven a enseñar.
- **`scripts/ui/menu_list.gd` (`MenuList`)** es la lista de opciones de todos ellos: texto a la
  izquierda, `>>` en la elegida, lo apagado en gris oscuro y el cursor se lo salta. Se mueve con
  las flechas o W/S, se acepta con Enter o espacio, se sale con Esc, y **también funciona con el
  mouse** (pasar por encima elige, clic acepta). Cada movimiento y cada aceptación suenan
  (`menu_blip`, más agudo al aceptar).
- **Renglones con valor:** los volúmenes de las opciones son una **barra de bloques**
  `■■■■■■□□□□  60 %` que se mueve con izquierda y derecha o con un clic en el punto de la barra;
  los niveles de la Custom Night son el número pelón, con los mismos controles.
- **No hay botones con caja en ningún menú.** `scripts/ui/ui_button.gd` sigue ahí solo para lo que
  no es menú (la PC y las tareas).
- La pantalla de la **solicitud de empleo** y la del **recibo de pago** no entran aquí: son una
  foto con texto encima (ver **Pantallas que son una imagen**).

**Capturas de todas las pantallas:** el panel de pruebas (F1 → Pantallas → **"Capturar todas"**)
recorre las 27 pantallas del juego —abriendo también las capas que viven dentro de la noche— y
guarda un PNG de cada una con `scripts/ui/screen_capture.gd`. Van a `user://capturas/`, que en
Linux es `~/.local/share/godot/app_userdata/Five Nights at Rocha\'s/capturas/`. La herramienta se
cuelga de la raíz del árbol, no de una escena, porque va cambiando de escena. Ojo: pasar por las
pantallas de documentos y periódicos los deja marcados como vistos en `save.cfg`.

## Transiciones y pantallas

- **Estática:** son los ocho cuadros de `assets/art/screens/static/estatica_0..7.png` (480x270),
  escalados con filtro **nearest** y pasando a ~24 fps desde un cuadro al azar. No hay shader: lo
  lleva `scenes/ui/static_frames.gd` (`StaticFrames`), que es un `TextureRect` con
  `set_strength(0..1)` para su opacidad. Se pide con `ScreenFx.add_static(padre, fuerza)` y cada
  sitio tiene la suya (la cámara en reposo apenas se nota, el jumpscare tapa todo).
- **Intro de noche:** negro pelón con "12:00 AM" al centro y "1ª noche" (2ª, 3ª...) debajo, a
  máquina de escribir y en blanco. Un golpe de estática de 0.3 s al aparecer y otro al irse. Unos
  2.5 s y entra sola a la noche.
- **6 AM:** negro con "5 AM" grande, también a máquina de escribir y en blanco; el 5 sube como un
  rodillo y entra el 6 en 0.8 s. **El texto no cambia de color**: lo único que se mueve es la hora.
  Suenan las campanadas del despertador, que **ya traen el grito de los niños al final**: el
  confeti cae en los últimos 4 s del audio (se mide su largo de verdad con `AudioManager.length()`)
  y la pantalla acaba con él. Solo si no estuviera grabado el despertador se pide aparte el
  `ninos_yay`. El confeti son triangulitos de colores que caen durante 4 s (`scenes/win_screen/confetti_fall.gd`, dibujado por código). Al acabar, el recorte de
  esa noche.
- **Game over:** un segundo de estática fuerte y, al aclararse, la cámara vacía del lugar de donde
  salió quien te atrapó, en blanco y negro y con grano; encima "GAME OVER" y la causa a máquina.
  Clic en cualquier lado vuelve al menú, el botón repite la noche. El mapa de profe a cámara está
  en `Extras.ORIGIN_CAMERAS` (la CAM 10 no tiene `vacia`: usa `cam10_salio`).
- **El HUD va en VT323**, como todo lo que sale de una pantalla o un aparato, y con el reparto de
  los juegos originales: **la hora grande arriba a la derecha** (86 px), "NOCHE N" debajo y más
  chica (34 px), el contador de tickets debajo (24 px) y la **energía abajo a la izquierda**
  (40 px). Los tamaños están en `night.tscn`; la fuente la pone `night.gd` en `_style_hud()`.
- **Esquina del HUD:** el reloj, la noche y el contador de tickets van en un `VBoxContainer`
  (`Hud/TopRight`) anclado arriba a la derecha, no en posiciones fijas: se apilan solos y no se
  pueden encimar entre ellos aunque les cambie el texto. La columna arranca pasada la banda del
  banner de avisos, que va centrado arriba.
- **Pantallas de carga:** entre el menú, las noches y los periódicos. Negro con estática leve y una
  frase del lore al azar de `data/loading_lines.gd`. Se entra con `LoadingScreen.go_to(árbol, ruta)`.
- **Fin de noche:** 6 AM → recorte de periódico → **recibo de pago** → la hoja que dé esa noche,
  si da alguna → lo siguiente. Ganar una Custom Night no da recorte ni recibo: da la carta de
  despido y vuelve a Extras.

## Pantallas que son una imagen

La solicitud de empleo y el recibo de pago son una foto de 1920x1080 en `assets/art/screens/`, y lo
único que hace el código es escribir encima. **Dónde va cada texto no se adivina**: está medido
sobre las propias imágenes y vive en `data/pantallas_campos.json`, normalizado sobre 1920x1080, que
lee `data/screen_fields.gd` (`ScreenFields`). Cada campo trae su posición, su ancho, el tamaño de
letra medido a 1080p (se escala con el alto), el color, la fuente y lo chueco que va. Si cambia el
arte, se vuelven a medir los campos en el JSON y no se toca código.

- **Solicitud de empleo** (`solicitud_empleo.png`, `scenes/main_menu/name_entry.gd`): al empezar
  partida nueva. El nombre se escribe **directo sobre el renglón** de la hoja (campo
  `solicitud_nombre`, Special Elite), con cursor que parpadea y un "clac" de máquina por tecla;
  máximo 16 caracteres (`NightConfig.MAX_NAME_LENGTH`). El "clac" **alterna al azar entre
  `tecla_maquina_1..3`** (las que de verdad estén en `assets/audio/`, que se preguntan una sola vez
  al abrir la hoja) **sin repetir la misma dos veces seguidas**; si no hay ninguna, suena
  `tecla_maquina`, que siempre está porque lleva provisional por código. **No hay cajas ni botones.** Con Enter
  aparece la firma en `solicitud_firma`, el mismo nombre en Reenie Beanie y tinta azul #283a8c, que
  entra en 0.4 s; 1 s después arranca la partida. Esc vuelve al menú. Abajo, chiquito: "Escribe tu
  nombre · Enter para firmar · Esc para volver".
- **Recibo de pago** (`pago_noche.png`, `scenes/win_screen/payment_screen.gd`): después del
  recorte. Lleva el nombre (`pago_nombre`), la noche (`pago_noche`), las tareas ("X de Y",
  `pago_tareas`) y el importe alineado a la derecha (`pago_importe`). La nota a mano
  (`pago_nota_a_mano`, Reenie Beanie roja y chueca −6°) cambia según cómo le fue: todas las tareas
  → "¡Buen trabajo!", algunas → "Mañana te esperamos", ninguna → "¿Viniste a dormir?". Abajo,
  "clic para continuar". Los números se guardan con `PaymentScreen.setup()` **antes** de preparar
  la noche siguiente, porque preparar la siguiente los borra.

## Documentos

`assets/art/extras/documentos/recibo_noche5.png`, `recibo_noche6.png` y `carta_despido.png`
(1920x1080, la hoja completa). Se entregan así: el **recibo de la noche 5** al pasar la noche 5, el
**recibo de la noche 6** al pasar la 6, y la **carta de despido** al ganar una Custom Night, la que
sea. Clic para seguir. Verlos una vez los deja guardados en la pestaña **Documentos** de Extras. Lo único que dibuja el código encima es el nombre del jugador, con
Special Elite en el color #231e1e y unos 26 px a 1080p (se escala con el alto). Las posiciones y la
inclinación están medidas sobre las imágenes y viven en `data/documents.gd`: en los recibos la
esquina superior izquierda del texto va en x 0.387, y 0.230 con 2° de inclinación; en la carta, en
x 0.298, y 0.270 con −1.5°.

## Cámaras

| CAM | Lugar | Quién puede aparecer |
| --- | --- | --- |
| 1 | Pasillo norte (mira hacia el balcón) | Barcosa, Mamador, Juan.exe, Armando |
| 2 | Pasillo sur (mira hacia la coordinación y los baños) | Barcosa, Mamador, Ureña, Juan.exe, Armando |
| 3 | Cubículo 2 | Rochis |
| 4 | Cubículo 3 | Botarga del Come Trabas |
| 5 | Escalera al techo | Mago Eléctrico |
| 6 | Techo, pararrayos | Mago Eléctrico |
| 7 | Escalera a planta baja (junto a la coordinación) | Ambiente; Mamador y Armando al bajar o subir |
| 8 | Estacionamiento | Ambiente; Mamador se retira aquí |
| 9 | Cafetería sur | Ambiente; Armando se retira aquí |
| 10 | Salón B, sala de servicio | Barcosa |
| 11 | Salón E | Ureña |
| 12 | Baños | Ureña |
| 13 | Sala de juntas (frente al salón B) | Mamador, Juan.exe, Armando |

Hay dos escaleras. En el extremo sur del pasillo, junto a la coordinación, la escalera interior baja a la planta baja (más salones), desde donde se sale del edificio al estacionamiento y a la cafetería; en el grafo, escalera_pb conecta con pasillo_sur. En el extremo norte, junto al salón B, dos puertas de cristal dan a un balcón con muros de concreto a media altura y una escalera exterior que baja fuera del edificio; por ahora es solo escenografía (se ve al fondo de la CAM 1).

**Acecho:** antes de abandonar su lugar inicial, Ureña (CAM 12), el Mago Eléctrico (CAM 6) y, en la CAM 13, el último profe que quede en la sala de juntas pasan por una etapa `acecho`: una oportunidad de movimiento exitosa los pone en acecho (miran fijo a la cámara) y la siguiente los hace salir. Estados: `cam12_urena-acecho`, `cam06_audel-acecho`, `cam13_mamador-acecho`, `cam13_juan-acecho`, `cam13_armando-acecho`.

**Rutas de retiro y regreso por el sur:** Mamador, después de inspeccionar, baja por pasillo_sur → escalera_pb (CAM 7) → estacionamiento (CAM 8) y se queda ahí un rato; Armando, al alejarlo con la linterna, baja por escalera_pb → estacionamiento (CAM 8) → cafeteria (CAM 9). Para llegar a la cafetería hay que salir del edificio y cruzar el estacionamiento: en el grafo, escalera_pb conecta con estacionamiento, y estacionamiento con cafeteria. Desde la planta baja regresan subiendo por escalera_pb al pasillo_sur y al cristal. Mamador reserva el pasillo también al subir. Juan.exe regresa a la sala de juntas y Ureña a los baños. Estados extra: `cam07_mamador-escalera`, `cam07_armando-escalera`, `cam08_mamador`, `cam08_armando`, `cam08_mamador_armando`, `cam09_armando`.

**Imágenes con varios profes:** el estado de una cámara con profes es `camXX_` más los nombres de los presentes en este orden fijo: barcosa, mamador, urena, juan, armando (por ejemplo `cam02_mamador_urena`). Barcosa en la CAM 2 lleva su estado: `barcosa-corriendo` o `barcosa-golpeando`. Si en una cámara hay 3 o más profes, se muestra "SEÑAL SATURADA" con estática fuerte (sin imagen), salvo en la CAM 13, que tiene `cam13_mamador_juan_armando`. La CAM 7 solo muestra a quien esté en escalera_pb (no a quien esté en pasillo_sur). Si Barcosa corre (CAM 1 o CAM 2) y coincide con otro, se muestra solo a Barcosa. En la CAM 8 pueden coincidir Mamador (retirado junto al coche) y Armando (cruzando hacia la cafetería): `cam08_mamador_armando`.

**Oficina por capas:** los profes en las vistas de la oficina son recortes con fondo transparente
en `assets/art/office/layers/` (por ejemplo `centro_mamador.png`, `centro_urena.png`,
`derecha_rochis.png`), del mismo tamaño que la vista. Cada recorte es un nodo propio con su
material, porque en la vista central cada uno se comporta distinto frente al cono:

- **Solo con linterna:** Ureña, Juan.exe y Armando en el cristal. Fuera del cono no se dibujan.
- **Siempre visibles, aunque a oscuras:** Mamador inspeccionando, Barcosa golpeando y el Mago en
  la escalera. Fuera del cono se pintan al 35 % de brillo, dentro al 100 %.
- **El ojo de Armando:** si está en el cristal y el cono no le da, lo único que se ve de él es un
  punto naranja tenue que parpadea de vez en cuando donde tiene el ojo.
- **Siluetas tras el cristal:** si un profe está en la recepción o en el tramo de `pasillo_sur` que
  se ve desde la oficina, se dibuja al fondo con `layers/silueta_<id>.png`: fuera del cono, al 35 %
  de brillo y un poco desenfocada; dentro, nítida y a todo brillo. Hay cinco (Barcosa, Mamador,
  Ureña, Juan.exe y Armando) y **pueden verse varias a la vez**: cada una tiene su sitio y ninguna
  se encima con otra, comprobado con `tools/measure_office_layers.py`. Si falta el archivo de
  alguien, no se dibuja nada.
- **Capas desactivadas** (`OfficeLayers.DISABLED`): `derecha_rochis.png`, que es de la vista derecha
  vieja; y `centro_barcosa.png`, que solo salía cuando Barcosa aporreaba la puerta y ahora eso no se
  dibuja (está detrás de la cortina), además de estar colocada para la oficina vieja.

**Orden de dibujo de la vista central:** fondo → **siluetas** → **cortina** → profes pegados al
cristal → etiquetas de presencia. Las siluetas van debajo de la cortina a propósito: con la lámina
abajo, Barcosa al otro lado de la puerta queda tapado; los que están pegados al cristal, no.

Dónde cae cada profe dentro de su recorte, y dónde tiene Armando el ojo, está en
`data/office_layers.gd`. No se adivina: lo mide `tools/measure_office_layers.py` sobre los propios
PNG (el recuadro de los píxeles opacos, y el píxel naranja más brillante de `centro_armando`). Si
cambia el arte, se vuelve a correr.

**Cortina de la puerta:** la caja del rodillo **ya viene pintada en las cuatro fotos de la vista
central**, así que el código no la dibuja (`DRAW_ROLLER_BOX` fuera) y **ya no hay oclusores**: no
queda nada delante de la puerta que tape la lámina.

La lámina es su propia capa, `assets/art/office/cortina_capa.png`, del tamaño de la vista y ya
colocada en su sitio (ocupa x 407, y 250, 150 x 271 sobre la imagen de 1375x768). Al cerrar la
chapa se va revelando de arriba hacia abajo en **0.6 s**, con el sonido `puerta_cortina`; al abrir,
a la inversa. Al terminar de bajar, la vista central cambia a las fotos `*_cerrada` (la oscura y la
iluminada) y la capa deja de dibujarse, porque a partir de ahí la cortina la trae el fondo.
Mientras baja, la capa **respeta el cono de la linterna igual que el fondo**: fuera del cono se ve
apagada, dentro a todo brillo. Por eso el cono abarca también la zona `entrance_door`, que es el
fondo del pasillo. En la CAM 2, si la puerta está cerrada, el código encima sobre la imagen del estado actual el recorte de `cam02_cortina` en el rectángulo normalizado x 0.729, y 0.223, w 0.1245, h 0.752 (definido en `data/camera_overlays.gd`, que se mide sobre la imagen y no se adivina). Las imágenes `cam02_barcosa-golpeando` ya traen la cortina abajo y no llevan el recorte encima. En la CAM 2, Mamador se pinta a la izquierda de la puerta, frente al cristal del sillón, para no quedar tapado por la cortina.

**Cámaras de ambiente (7, 8, 9):** ninguna ruta de ida pasa por ahí; solo las usan Mamador y Armando al retirarse (ver Rutas de retiro). Además, de vez en cuando muestran sucesos raros sin consecuencias (una sombra, una luz que parpadea), que sirven de atmósfera y de pistas para una secuela.

**Sala de juntas (`sala_juntas`, CAM 13):** el salón del lado oeste frente al salón B, con una mesa ovalada tipo consejo directivo y una pantalla de proyección en un costado. Conecta con pasillo_norte.

Sin cámara: recepción (se ve desde la oficina), sala de servidores (antes cubículo 1, zona de tareas; id `sala_servidores`) y tres salones (puntos ciegos).

## Personajes

- **Barcosa (rol Foxy):** se esconde en la sala de servicio del salón B y sube de etapa
  **por tiempo sin que lo revises**, no por el dado de la IA: hay que dejarlo sin mirar
  `NightConfig.barcosa_stage_time()` segundos seguidos para que avance uno, y **verlo por la
  CAM 10 pone la cuenta a cero**. Son 45 s por etapa con el nivel de la noche 2 y 15 s con el de la
  6, interpolando por nivel (así vale también para la Custom Night, con un piso de 8 s).
  Revisarlo cada 30 s lo deja clavado hasta la noche 4.
  Al salir corre por CAM 1 hasta la puerta y **tarda en llegar** `NightConfig.barcosa_run_time()`:
  6 s en la noche 2 y 3 s en la 6. Desde que sale y hasta que llega **suena `barcosa_corre` en
  bucle** (pasos acercándose), para poder reaccionar sin estar en las cámaras. Solo se detiene
  cerrando la puerta; golpea y habla 5 s, luego regresa. Puerta abierta = jumpscare.
  En la oficina se le ve **de silueta mientras corre por `pasillo_sur`** hacia la puerta. Cuando ya
  está aporreando con la chapa cerrada **no se dibuja nada**: está detrás de la cortina. Lo único
  que se nota es que **la lámina tiembla 2.5 px durante 0.15 s con cada golpe** (señal
  `door_knocked` → `office.shake_curtain()`), y lo que grita (ver **Líneas sueltas de profe**).
- **Mamador (rol Freddy):** empieza en la sala de juntas. Ruta CAM 13 → 1 → 2 → cristal; reserva el pasillo antes de entrar a pasillo_norte. Al llegar revisa solo dos cosas: la ventana de la IA abierta en la PC y la puerta cerrada. Si ve alguna, game over "delito federal" (llegan los militares). Si no, dice su frase y se va. Tiene sonido propio de aviso.
- **Ureña (rol Chica):** lento. Ruta CAM 12 → 11 (o salón sin cámara) → 2 → cristal. Se aleja con destellos de linterna (ver **Destellos en el cristal**).
  - **Llamada de Ureña (comedia):** cada noche que Ureña está activo, puede llamar entre las 2 y las 4 AM (60 %; en noches 5 y 6 hasta dos llamadas). La llamada no bloquea el juego: Ureña habla en altavoz y sus textos salen en un recuadro pequeño en una esquina, mientras el jugador sigue usando cámaras, puerta y linterna. Saluda con el nombre del jugador, lo felicita por sus tareas y le hace 1 o 2 insinuaciones (banco en `data/urena_questions.gd`). Cada una tiene 3 respuestas barajadas, elegibles con las teclas 1, 2 y 3 o con clic, y 6 s para elegir: la correcta esquiva con educación (no pasa nada); `sigue_el_juego` quita 5 % de energía y deja la foto en el escritorio; `grosera` quita 5 % sin foto; sin respuesta cuenta como `sigue_el_juego`. Se puede colgar en cualquier momento (o no contestar), pero Ureña se ofende: deja la foto y su nivel sube +5 durante una hora de juego. Ya no hay game over por no contestar. Se despide según cómo le fue. Los demás profes siguen moviéndose.
- **Rochis (rol Bonnie):** en CAM 3 pasa de sentado a medio levantado a de pie. Mientras se levanta hay que reproducir el audio "es impresionante" hasta que se vuelva a sentar. Reproducirlo cuando ya está sentado lo molesta y acelera su avance. Si llega a estar de pie, entra a la oficina, dice el nombre del jugador y es game over.
- **Mago Eléctrico (rol Balloon Boy; antes Audel Electrix):** en pantalla y diálogos se llama "Mago Eléctrico"; en código, ids, estados y archivos se sigue usando `audel` (por ejemplo `cam06_audel-acecho`, `centro_audel.png`) para no romper nada. vive en el techo (CAM 6), baja por la escalera (CAM 5). Si se baja el breaker mientras está en la escalera, regresa al techo. Si entra, hace un "cortaso": la linterna deja de funcionar y se pierde parte de la energía. No mata directamente.
  - **Susto del cortaso (sin muerte):** cuando el Mago entra a la oficina, la pantalla se va a negro, sale `jumpscare_audel_susto` 0.5 s con un chispazo y una risa, y después la linterna queda inservible. Con la linterna muerta **el pasillo se queda a oscuras**: no hay cono, no se ve quién está en el cristal y no se le pueden contar destellos a nadie. Eso es parte del castigo.
  - **Muerte por apagón:** cuando la energía llega a 0 % todo se apaga y empieza una
    secuencia de cuatro tiempos, en `blackout_death.gd`: 3 a 12 s al azar de oscuridad total;
    a lo lejos en el pasillo, al fondo del cristal, se encienden y se apagan **un par de ojos**
    al ritmo de la cajita musical, uno por pulso (los de su JSON), como la cara de Freddy en
    FNAF 1: chiquitos, blanco azulados y con un brillo muy leve, y **no se ve nada más**. La
    cajita de la botarga se calla, que a oscuras solo se oye esta. No
    suena la canción entera: es **un tramo al azar**, que entra por un pulso de la **primera
    mitad** y dura entre **8 y 20 s**, acabando también en un pulso, con un fundido de 0.4 s
    (`MusicBox.random_segment()`, y los números en `blackout_death.gd`). Las chispas siguen los
    pulsos **de ese tramo**, no los del principio de la canción. La cajita de la CAM 4 y el aviso
    lejano no cambian. Al acabar el tramo, los ojos se apagan y hay **silencio total de 2 a 5 s**; luego
    se oyen **tres pasos que se acercan** y, al terminar, `jumpscare_audel` con la animación de
    siempre. La causa del game over es "Mago Eléctrico". Pasa en todas las noches, aunque el Mago
    esté en nivel 0, porque el apagón es suyo. **Si dan las 6 AM en cualquier punto de la
    secuencia, el jugador se salva** y todo se calla.
  - **Descarga del pararrayos:** mientras el Mago Eléctrico está en el techo (CAM 6), de vez en cuando provoca una descarga que desconecta algunos patch cords en la sala de servidores. Las cámaras afectadas muestran "SIN SEÑAL" hasta que el jugador entra a la sala de servidores (vista derecha de la oficina) y reconecta cada cable en su puerto según la hoja de etiquetado pegada en el rack (por ejemplo, CAM 03 → PP-07 → SW1 Gi0/7). Mientras está en la sala, no vigila la oficina.
- **Come Trabas (rol Puppet; antes era Santi, un alumno de Sistemas):** un ritual cuyo responsable es un misterio (se reserva para una secuela) encerró el alma de Santi dentro de la botarga de la mascota de la universidad. La botarga está sentada en una silla del cubículo 3 (CAM 4) con una llave de cuerda en la espalda; mientras tiene cuerda, toca una canción de cajita musical sin nombre (`assets/audio/cajita_musical.ogg` cuando exista) y sigue desplomada. La cuerda se descarga con el tiempo; se le da cuerda manteniendo un botón en la CAM 4, con un indicador circular. En cero, la botarga levanta la cabeza, se levanta y va por el jugador: jumpscare de la botarga y game over con causa "Come Trabas". Estados visibles en CAM 4: desplomada, cabeza levantándose, silla vacía. Las Trabas (criaturas que salían de su boca) quedan fuera de esta entrega y se reservan para una segunda; el nombre del personaje se mantiene. De quién es esa canción de cajita musical es un secreto para la segunda entrega: no se menciona en ningún texto del juego, solo se oye.
- **Juan.exe (rol Bonnie clásico):** profe sencillo, sin mecánica especial. Empieza en la sala de juntas; ruta CAM 13 → 1 → 2 → cristal. En el cristal solo se ve con la linterna y se aleja con 4 destellos, igual que Ureña; si no, game over "Juan.exe". No usa la reserva del pasillo.

**Susto en el cristal** (Ureña, Juan.exe y Armando, en `glass_stalker.gd`): cada uno lleva un
"susto" de 0 a 1 que **no se ve**. Con la linterna encendida sube, y al apagarla baja, pero mucho
más despacio, así que da igual mantenerla puesta o darle parpadeos rápidos: lo que cuenta es la luz
acumulada, no acertar ningún ritmo. Al llenarse se va, con su aviso y el sonido `se_aleja`. Como la
linterna no se apunta, les sube a todos los que estén en el cristal a la vez. Si no se llena antes
de que se le acabe la paciencia, entra y es game over.

Los tiempos están en `autoload/night_config.gd` para poder ajustarlos sin tocar la mecánica:
`FLASH_FILL_TIME` (1.75 s de luz para ahuyentarlo), `FLASH_DECAY_TIME` (5 s en bajar de lleno a
cero) y lo que aguanta en el cristal, que se interpola entre `GLASS_TIME_FIRST_NIGHT` (9 s) y
`GLASS_TIME_LAST_NIGHT` (5.5 s). Eso deja unos **7.25 s de margen de reacción en la noche 1 y 3.75 s
en la 6**; `NightConfig.glass_margin(noche)` lo calcula y el panel de pruebas lo enseña.
- **Armando Prompts (rol Chica clásico + Lolbit):** profe que se cree genio, presume títulos inventados y todo lo automatiza con IA. Misma ruta y misma mecánica de linterna que Juan.exe. Además, desde la noche 4, cada vez que el jugador pulsa "Resolver tarea" del asistente Claudio hay probabilidad de que su cara tome toda la pantalla de la PC con una frase al azar; hay que escribir "APÁGATE" en 6 s. Si no, borra el progreso de la tarea actual y quita 5 % de energía. Frases: "HOLA, SOY ARMANDO PROMPTS, INGENIERO EN PROMPTS CERTIFICADO POR MÍ MISMO.", "LE PEDÍ A CLAUDIO QUE HICIERA TU TAREA. TAMBIÉN LE PEDÍ QUE TE CORRIERA.", "ESTE MENSAJE FUE GENERADO CON IA. YO NI LO LEÍ.", "MI TESIS LA HIZO CLAUDIO. MI BODA TAMBIÉN.", "AUTOMATICÉ MIS SENTIMIENTOS. AHORA SUFRO 40% MÁS RÁPIDO.", "¿PENSAR? NAH, ESO ES DE BOOMERS."
- **Claudio (asistente IA de la PC):** parodia de un asistente de IA. Logo propio: una chispa o asterisco naranja terracota con lentes tipo Clark Kent (que evoque la referencia sin calcar ningún logo real). Ventana con fondo crema y acentos naranja. Personalidad exageradamente educada: empieza cada respuesta con "¡Excelente pregunta!" y pide disculpas por todo.

## Alucinaciones

Desde la noche 2, de vez en cuando aparece **un solo cuadro durante 0.1 a 0.2 s** con un golpe
grave, y se va. No hacen nada: ni matan, ni quitan energía, ni hay nada que contestar; están solo
para que el jugador dude de lo que vio. Son raras, se hacen más seguidas en las noches altas y
**nunca sale una antes de 90 s** desde la anterior. Los números y los cuadros están en
`data/hallucinations.gd`; la capa es `scenes/night/hallucination_overlay.gd`.

| Cuadro | Qué se ve |
| --- | --- |
| `foto_esposa` | La foto de la esposa difunta de Rochis, recortada de la capa de la CAM 3 y a pantalla completa, mirando de frente. |
| `es_impresionante` | "ES IMPRESIONANTE" en rojo sobre el monitor. Solo sale con la PC abierta, que es cuando se ve la pantalla; si está bajada, se elige otro. |
| `botarga` | La botarga sentada en la silla de la oficina: su propio jumpscare muy oscurecido, para que se adivine la silueta. |
| `expediente` | Un expediente cualquiera con el nombre del jugador escrito donde va el del profe. El valor del campo NOMBRE empieza en x 0.072, y 0.253 y llega a x 0.296, con alto 0.033, sobre una hoja girada −2.5°: el parche (color del papel #d6c49e) y el nombre se giran ese mismo ángulo apoyados en esa esquina. El nombre va en Special Elite a 30 px en 1080p, color #282019. |

## Jumpscares

Las imágenes están en `assets/art/jumpscares/`: `jumpscare_<id>.png` y `jumpscare_<id>_a.png` para barcosa, urena, rochis, juan, armando, cometrabas y audel, más `audel_susto` y `mamador_militares`.

La animación de cada muerte es la misma: la variante `_a` durante 0.12 s, corte a la imagen final con un zoom de 1.0 a 1.15 en 0.5 s, temblor fuerte, un destello blanco de un cuadro y un grito; después estática y la pantalla de game over con su causa.

**El grito va siempre y a 0 dB**, encima de la estática: nunca se oye solo el siseo. Lo elige
`Sounds.scream_for(slug)`: el grito propio del profe (`grito_<id>`) si está grabado, si no uno de
`grito_base_1..3` al azar, y si tampoco están, `grito`, que lleva provisional por código.

Mamador no salta: su game over es la **pantalla de WASTED**, al estilo GTA
(`scenes/ui/wasted_screen.gd`). Ya no lleva luces de policía.

| Cuándo | Qué pasa |
| --- | --- |
| −0.8 s | **La irrupción**: pantalla en negro, `mamador_brecha` (la puerta derribada y los gritos del operativo) y un flash blanco de un cuadro. Solo la lleva Mamador: se pide con el parámetro `breach` de `WastedScreen.play()` |
| 0.0 s | `jumpscare_mamador_militares` a pantalla completa, con un zoom de 1.0 a 1.08 que no para en toda la secuencia |
| 0.4 s | La imagen se va a blanco y negro en 0.8 s y baja un poco de brillo; suena `wasted` |
| 1.2 s | Entra una franja negra (alfa 0.55) de lado a lado, centrada, de alto 16 % de la pantalla, con fade de 0.3 s |
| 1.2 s | Encima, "WASTED" en `assets/fonts/pricedown.otf`, rojo #C21E1E con contorno negro, escalando de 1.15 a 1.0 en 0.25 s |
| 2.2 s | Debajo de la franja, el texto de abajo en la misma fuente, blanco con contorno, al 40 % del tamaño de WASTED |
| 5.2 s | Pasa a la pantalla de game over normal, con su causa |

**El texto de abajo es un parámetro**, así que la pantalla se reutiliza: el game over de Mamador
pone "DELITO FEDERAL" y la tarea de la baraja pondrá "LUDOPATÍA". Si falta la fuente se cae a
Oswald en negritas (`Fonts.display()`), y si falta `wasted.ogg`, a un provisional por código.

La galería de Jumpscares de Extras **reproduce de verdad**: clic en una ficha y sale su salto, y
la de Mamador lanza esta misma pantalla de WASTED.

## Reglas para que las mecánicas no choquen

1. El pasillo es de uno a la vez entre Barcosa y Mamador: si uno lo "reserva", el otro espera.
2. Mamador ignora la linterna, el breaker y las cámaras.
3. Cada amenaza tiene una contramedida distinta; ninguna se resuelve con la de otra.

## Tareas

Cada noche pide de 2 a 5 tareas (minijuegos de 20 a 60 s) para que le paguen al guardia. Casi todas se hacen en la PC; las del tablero de pastillas y el patch panel se hacen en la sala de servidores, dejando la oficina sin vigilar. La IA de la PC las resuelve o da pistas, pero su ventana abierta delata al jugador ante Mamador.

**Tickets durante la noche:** las tareas no están todas desde las 12. Llegan como tickets repartidos en la noche (el primero al inicio y los demás espaciados hasta las 5 AM, con algo de azar), con un aviso sonoro y un contador en la oficina. **Los tickets no vencen**: una vez que llega uno se queda en la lista hasta que el jugador lo termina, y se paga por cada tarea completada. Lo único que corre es el reloj de la noche.

**Pasos con espera:** casi todas las tareas tienen al menos un paso que tarda (copiar un respaldo, reiniciar un servicio, esperar respuestas de ping, propagar una configuración), con barra de progreso. La barra solo avanza mientras la PC está abierta; al bajarla se pausa. Ese es el dilema central: quedarse en la PC o vigilar. La duración de las esperas crece por noche.

Las tareas imitan herramientas reales de un coordinador de sistemas, con diseño original (sin logos ni nombres de marcas): una terminal estilo consola (comandos tipo `ipconfig`, `ping`, reinicio de servicios), un simulador de redes estilo diagrama de topología donde se conectan y configuran equipos, y el patch panel físico en la sala de servidores.

**La PC:** al hacer clic en el monitor, la vista se acerca a la pantalla y aparece un escritorio retro original enmarcado por el bisel del monitor, con íconos: Terminal, Simulador de red, Tareas y Asistente IA. La ventana del Asistente IA sigue abierta y trabajando aunque se baje la PC. Usar la PC gasta energía (cuenta como una barra de consumo).

## Niveles de IA por noche

| Noche | Barcosa | Mamador | Ureña | Rochis | Mago Eléctrico | Come Trabas | Juan.exe | Armando | Tareas |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 0 | 3 | 0 | 0 | 0 | Lenta | 2 | 0 | 2 |
| 2 | 3 | 5 | 0 | 0 | 0 | Lenta | 4 | 2 | 3 |
| 3 | 5 | 7 | 4 | 3 | 0 | Media | 6 | 4 | 3 |
| 4 | 8 | 9 | 7 | 6 | 5 | Media | 8 | 6 | 4 |
| 5 | 11 | 12 | 10 | 10 | 9 | Rápida | 10 | 9 | 4 |
| 6 | 15 | 16 | 15 | 15 | 14 | Muy rápida | 14 | 13 | 5 |

La mecánica de Claudio de Armando solo se activa desde la noche 4.

**Custom Night** (`scenes/extras/custom_night.gd`): cada nivel de 0 a 20, con **el retrato de cada
profe**, como en los juegos originales. Rejilla de 4 por 2: la cara arriba, el nombre en VT323
debajo y el nivel entre sus flechas, `<  12  >`. Sin panel, sin borde y sin sombra. Los siete que
no están elegidos se ven **en blanco y negro y oscurecidos** (el shader
`scenes/ui/greyscale.gdshader`, con `amount` en 1 y `darken` en 0.55); el elegido, **a color y a
todo brillo**, con sus flechas encendidas.

**De dónde sale la cara:** del expediente del profe, que trae pegada una foto tipo polaroid en
blanco y negro. Dónde cae esa foto **no se adivina**: lo mide
`tools/measure_dossier_faces.py` (busca el bloque de píxeles grises de la hoja) y vive en
`data/custom_night_faces.gd`; el retrato es el **cuadrado de arriba** de esa foto, que es donde
está la cabeza. Si a alguien le faltara el expediente, se cae a su jumpscare, que ya es un primer
plano y no necesita recorte.

**Cómo se mueve:** el cursor está en los retratos o en la lista de abajo. Arriba y abajo lo
mueven (pasado el último retrato se baja a la lista, y subiendo desde el primer renglón se vuelve
a los retratos); **izquierda y derecha siempre cambian el nivel** del profe elegido, que es lo que
dicen sus flechas. Con el mouse: pasar por encima elige, y picar una flecha mueve ese nivel aunque
el profe no esté elegido.

**Retos de Custom Night** (`data/custom_challenges.gd`): renglones de texto debajo de los retratos
que dejan los ocho niveles ya puestos, con su gracia escrita al lado. Ganar uno se guarda y el
renglón queda con una palomita. Tocar un nivel a mano deja de contar como reto.

| Reto | Niveles | Gracia |
| --- | --- | --- |
| Junta de academia | Mamador, Juan.exe y Armando en 20 | Los tres de la sala de juntas a la vez. |
| Puros nuevos | Juan.exe y Armando en 20 | Sin nadie que te distraiga. |
| Fuera de horario | Barcosa y Rochis en 20 | Barcosa corriendo y Rochis levantándose. |
| Apagón | Mago Eléctrico en 20 | Empieza con el 50 % de energía. |
| Todos en 20 | los ocho en 20 | Además vale la tercera estrella del menú. |

## Lore, periódicos y Extras

La historia de fondo no se explica en el juego: se va descubriendo en recortes de periódico. Al terminar cada noche, la pantalla de las 6 AM da paso a un recorte nuevo (como el periódico de FNAF), que se desbloquea y queda guardado en `user://save.cfg`. Las imágenes están en `assets/art/extras/periodico_0..6.png` (1920x1080, la página completa) y son
lo que se muestra; los textos de `data/newspapers.gd` (título, fecha, cuerpo) se conservan para la
plantilla dibujada, que solo se usa si falta una imagen.

| Recorte | Se desbloquea | Contenido |
| --- | --- | --- |
| 0 | Al empezar la noche 1 | Anuncio: la Coordinación de Sistemas busca alumno para guardia nocturna. "Excelente oportunidad de servicio social." |
| 1 | Al pasar la noche 1 | Desaparece Santi, alumno de Sistemas, durante el evento de bienvenida; la última vez lo vieron con la botarga de la mascota puesta. |
| 2 | Al pasar la noche 2 | Alumnos reportan que la botarga, guardada en el cubículo 3, toca sola una cancioncita de cajita musical por las noches. |
| 3 | Al pasar la noche 3 | Hallan velas, sal y un símbolo extraño en la sala de juntas; la universidad niega cualquier ritual. Nadie sabe quién convocó esa junta. |
| 4 | Al pasar la noche 4 | Renuncia el personal de limpieza nocturno: "dentro de la botarga se oyen voces, muchas voces". (Pista de las Trabas.) |
| 5 | Al pasar la noche 5 | Se filtra la lista de asistentes a la junta de esa noche: los nombres aparecen tachados. |
| 6 | Al pasar la noche 6 | La universidad clausura la coordinación. "El responsable sigue sin ser identificado." (Gancho para la secuela.) |

**Menú principal:** el fondo (`menu_fondo_0..3.png`) tiene toda la mitad izquierda en negro, y ahí
van el título y las opciones, **alineados a la izquierda y en VT323 blanco grande**. El título va
en **cuatro renglones**, como el logo de los juegos originales: "FIVE / NIGHTS / AT / ROCHA'S". La opción
elegida lleva `>>` al lado; se mueve con las flechas (o W/S) y con el mouse, y las bloqueadas salen
apagadas y el cursor se las salta. Debajo del título, las tres estrellas. Abajo a la izquierda, la
versión (`application/config/version` de project.godot). Abajo al centro, "Mantén Supr para borrar
el progreso": mantener Supr 1.5 s llena una barrita y entonces pregunta si de verdad, y solo al
confirmar se borra `save.cfg`.

**Extras** (opción del menú principal, se desbloquea al pasar la noche 5, como en los juegos
originales). La **columna de secciones** va a la izquierda en VT323 con `>>`, y **no pasa del 28 %
del ancho**; todo lo demás (el visor de expedientes con sus flechas y su contador, y las rejillas)
vive en el hueco de la derecha y nunca pisa la columna. Suena `extras_musica` en bucle, aquí y en
la Custom Night.
- **Expedientes:** `assets/art/extras/expediente_<id>.png` (1920x1080). Cada imagen ya es la escena
  completa, la carpeta y el plano, así que no se recorta nada: se ve entera en el hueco de la
  derecha y se pasa a
  la siguiente con las flechas de los lados, con clic (derecha avanza, izquierda retrocede) o con las
  teclas de dirección. Debajo, el nombre en pantalla, el rol y una línea. Se desbloquea la ficha de
  un profe la primera vez que te mata o al pasar la noche donde se activa.
- **Periódicos:** los recortes desbloqueados, para releerlos.
- **Documentos:** los recibos de pago y la carta de despido que ya te entregaron, con tu nombre
  escrito encima. Clic en uno para verlo a pantalla completa.
- **Jumpscares:** galería para reproducir los jumpscares ya vistos.
- **Custom Night** (si no está ya en el menú principal).
Lo bloqueado se muestra con su propia imagen muy oscurecida y desenfocada (shader
`scenes/ui/locked_art.gdshader`) y un "???" encima.

**Audio del menú principal:** música de fondo en bucle (`menu_musica`, bus Música, −14 dB) y un
hilo de estática (`estatica_camara`, −30 dB). Las dos se apagan solas al salir del menú
(`_exit_tree`), para que no se cuelen en la noche.

**Fondo de los menús (`scripts/ui/menu_backdrop.gd`):** de fondo va siempre
`assets/art/menu/menu_fondo_0.png`, con líneas de escaneo suaves y un poco de estática. Encima, el
**"tic"**, al estilo del menú de Sister Location: cada **5 a 10 s** al azar la imagen se desgarra y
aparece un profe por un instante.

Los cuadros del tic son `menu_tic_rochis.png`, `menu_tic_urena.png` y `menu_tic_mamador.png`, que
están **alineados con `menu_fondo_0`** —solo cambia el profe, así que el cambio se nota únicamente
en él—, más `menu_tic_ultra.png`, con los tres y los ojos negros. Sustituyen al golpe de
`menu_fondo_1..3`, que ya no se usa.

El tic dura unos **0.35 s** y va en cuatro tramos:

| Tramo | Qué se ve |
| --- | --- |
| 0.07 s | Todavía `menu_fondo_0`, pero desgarrado de arriba abajo: las franjas corridas de 10 a 40 px a los lados y los colores separados. **El golpe suena aquí** (`golpe_grave_menu`, el mismo `golpe_grave.ogg` a −4 dB), con el primer cuadro roto |
| 0.10 s | Entra el cuadro del profe y el desgarro se vuelve una banda que **baja** de arriba abajo |
| 0.15 s | **Congelado**: el profe quieto y sin desgarro, que es lo que asusta |
| 0.05 s | Uno o dos cuadros de estática a 0.5 de opacidad, que tapan la vuelta a `menu_fondo_0` |

**No repite el profe anterior**, y **uno de cada ocho** tics sale el ultra, con la misma secuencia
un 35 % más larga (medio segundo). El desgarro, la separación de color y el congelado los hace
`scenes/ui/menu_glitch.gdshader` sobre la propia imagen (franjas sorteadas con una semilla, ventana
de mordida con centro y alto): **no hay cuadros extra dibujados**. El panel de pruebas los fuerza
desde F1 → Pantallas, que deja el tic apuntado en `MenuBackdrop.pending_tic` y abre el menú.

**Estrellas del menú principal:** debajo del título, tres. Una al pasar la noche 5, otra al pasar la
6 y otra al ganar una Custom Night con los ocho profes en 20. Se dibujan por código (`StarRow`) y el
avance se guarda en `save.cfg` (`nights_cleared` y `custom_mastered`, porque `night_reached` se topa
en la última noche y no distingue entre pasar la 5 y pasar la 6).

## Hitos del prototipo

1. Reloj, energía, oficina placeholder, puerta, pantallas de 6 AM y game over.
2. Grafo de habitaciones, clase Animatronic y sistema de 13 cámaras con etiquetas de texto.
3. Barcosa completo.
4. PC con ventana de IA, una tarea de ejemplo y Mamador.
5. Come Trabas (la botarga), Ureña con linterna, Rochis con el audio, Mago Eléctrico con el breaker.
6. Configuración por noche, menú, selección de noche, Custom Night y guardado.
7. Periódicos entre noches y menú de Extras.
8. Resto de tareas y jumpscares.