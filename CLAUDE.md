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
  scenes/minigames/    la maquinita de 8 bits (arcade_screen.gd y un script por nivel)
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
  - **Desenfoque de movimiento:** durante el barrido la imagen se corre en horizontal, creciendo
    hasta la mitad del giro y apagándose al llegar (`MAX_SWEEP_BLUR_PIXELS`, **70 px**). Va para
    **todo lo que se ve**, no solo para el fondo: `office.gd` recorre la vista entera y le pone el
    parámetro a cada material, así que se desenfocan también la foto iluminada, los recortes de los
    profes, las siluetas y la cortina (`blur_amount` en `office_view.gdshader` y `motion_blur` en
    `flashlight_reveal.gdshader`). El parallax del mouse lleva el mismo desenfoque pero **mucho más
    leve** (`MAX_PAN_BLUR_PIXELS`, 5 px) y solo cuando se mueve rápido: a `PAN_BLUR_FULL_SPEED`
    (900 px/s) ya está al tope. Los píxeles se cuentan siempre sobre una pantalla de 1920 de ancho
    (`OfficeLayers.REFERENCE_WIDTH`), para que se vea igual en cualquier resolución.
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
  (`scenes/office/flashlight_reveal.gdshader`), y el foco parpadea un poco. El haz sale del
  recuadro del pasillo crecido un poco por los lados y por arriba, pero **por abajo se estira hasta
  pasarse del contenido** (`BEAM_BOTTOM`): si acabara donde acaba el pasillo, su borde caería a
  media altura de la imagen y se vería como una raya horizontal cruzando la pantalla. Se mantiene
  con Ctrl o con el clic izquierdo sostenido sobre el cristal, y gasta energía mientras está
  encendida.

## Audio

Todo el sonido pasa por el autoload **AudioManager**: nadie carga un archivo a mano ni pone un
`AudioStreamPlayer` en una escena. Se le pide un sonido por su id del catálogo
(`data/sounds.gd`), que dice el archivo que espera en `assets/audio/`, el bus y el volumen.

**Nadie se arrastra de una pantalla a otra.** El AudioManager lleva un **registro de los bucles**
puestos (`play_loop` los apunta, `stop` los borra) y expone `stop_all_loops()`, que los calla
todos de golpe sin tocar los sonidos de una sola vez que estén en el aire. Cada pantalla lo llama
al montarse; **la noche y el menú principal van más lejos y arrancan con `stop_all()`**, porque un
grito o un despertador colgando se oye encima de su ambiente. Y cada pantalla calla lo suyo al
salir (`_exit_tree`): el 6 AM su despertador, el game over su estática. `AudioManager.active_ids()`
dice qué está sonando, con `*` en los bucles, y el panel de pruebas lo imprime (F1 → Audio →
«Escribir los que están sonando»).

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

**Dos efectos de la misma secuencia nunca suenan a la vez.** Un susto, un rescate o una
irrupción son **secuencias** (`Sounds.SEQUENCES`: `susto`, `rescate`, `momo`, `apagon`): el
siguiente **espera la señal `finished` del anterior**, no un tiempo apuntado a mano, y al empezar
una se calla lo que quede sonando de ella. Lo lleva el AudioManager con tres llamadas:

- `begin_sequence(nombre)` — arranca: calla sus sonidos y tira su cola.
- `play_in_sequence(nombre, id, al_acabar, desde)` — suena ya, o espera su turno si hay otro de la
  misma en el aire. `al_acabar` es un `Callable`, que es como la imagen se engancha al sonido (el
  negro de la irrupción de Mamador se levanta con el `finished` de su audio, no a los 0.8 s).
- `sequence_busy(nombre)` — ¿sigue sonando algo de ella? Lo pregunta quien tiene que aguantar una
  imagen: la oscuridad del apagón no pasa a la cajita musical hasta que se acaba `apagon_frase`.

Los gritos entran en la secuencia `susto` por su prefijo, sin listarlos uno a uno. Gracias a esto
el grito de un jumpscare ya no se pisa con la estática del game over, ni el golpe de WASTED con la
irrupción.

**Nada de síntesis de voz.** En el juego **no se usa `DisplayServer.tts_*` en ningún sitio**: una
voz robótica leyendo a un profe no suma. Todo lo hablado es grabación, y **lo que no esté grabado
sale solo como subtítulo**. Por eso **ninguna voz lleva provisional por código**: un pitido en vez
de una frase no dice nada, así que si falta el archivo el AudioManager avisa («sin sonido ni
provisional») y no suena nada.

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

**El catálogo** (117 ids; la lista de lo que falta está en `docs/audios_faltantes.md`, y el
inventario completo de pendientes y provisionales en `docs/pendientes.md`). Casi todos tienen
provisional por código; **las voces no**, por lo de arriba.

| id | archivo | bus | dB | bucle | cuándo suena |
| --- | --- | --- | --- | --- | --- |
| `ambiente_oficina` | `ambiente_oficina.ogg` | Ambiente | −14 | sí | toda la noche; se calla con el apagón |
| `ambiente_pasillo` | `ambiente_pasillo.ogg` | Ambiente | −20 | sí | toda la noche |
| `estatica_camara` | `estatica_camara.ogg` | Ambiente | −22 | sí | mientras el monitor está abierto |
| `menu_blip` | `menu_blip.ogg` | Efectos | −16 | sí | moverse por un menú y aceptar (lo mismo, más agudo) |
| `tic_boom_1..3`, `tic_golpe_metal`, `tic_vidrio`, `tic_raspon`, `tic_golpe_eco`, `tic_whoosh_golpe`, `tic_piano`, `tic_estatica` | `menu/<id>.ogg` | Efectos | −4 | no | el golpe del tic del menú: uno de los diez al azar en cada uno |
| `tic_rechinido` | `menu/tic_rechinido.ogg` | Efectos | −4 | no | **fuera del sorteo**: sonaba a puerta y en el menú no hay ninguna |
| `estatica_inquietante` | `estatica_inquietante.ogg` | Efectos | −14 | no | de fondo en el tic «ultra» del menú |
| `estatica_inquietante_gameover` | `estatica_inquietante.ogg` | Efectos | −16 | no | debajo de la estática del game over (mismo archivo) |
| `lejos_pasos_pasillo` | `lejos/lejos_pasos_pasillo.ogg` | Lejos | −6 | no | pasos recorriendo el pasillo, con los demás ambientales |
| `menu_musica_final` | `menu/menu_musica_final.ogg` | Música | −4 | sí | la música del menú principal, la única |
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
| `golpe_grave_1..3` | `golpe_grave_N.ogg` | Efectos | 0 | no | el cuadro de una alucinación: uno de los tres, sin repetir |
| `golpe_grave` | `golpe_grave.ogg` | Efectos | 0 | sí | el respaldo de los tres de arriba |
| `grito` | `grito.ogg` | Efectos | 0 | no | el jumpscare |
| `grito_<id>` | `gritos/grito_<id>.ogg` | Efectos | 0 | no | el grito de cada jumpscare; los siete están grabados |
| `mamador_brecha` | `mamador_brecha.ogg` | Efectos | 0 | no | la irrupción del operativo, antes del WASTED |
| `armando_windows_crash` | `armando_windows_crash.ogg` | Efectos | −2 | no | Armando toma la pantalla de la PC |
| `armando_glitch_bucle` | `armando_glitch_bucle.ogg` | Efectos | −18 | sí | de fondo, mientras dura esa toma |
| `apagon_frase` | `apagon_frase.ogg` | Voces | 0 | no | justo al quedarse la oficina sin energía |
| `menu_glitch_largo` | `menu_glitch_largo.ogg` | Efectos | −4 | no | el tic «ultra» del menú, el de los tres |
| `sonido_perturbador` | `extras/sonido_perturbador.ogg` | Efectos | −4 | no | el vistazo «de reojo» de las cámaras |
| `llamada_mencho` | `llamadas/llamada_mencho.ogg` | Voces | 0 | no | la llamada del Mencho, una por noche |
| `llamada_juguete` | `llamadas/llamada_juguete.ogg` | Voces | 0 | no | la otra llamada rara, desde la noche 2 |
| `descarga_pararrayos` | `descarga_pararrayos.ogg` | Efectos | −3 | no | la descarga que tumba los patch cords |
| `cortaso` | `cortaso.ogg` | Efectos | −2 | no | el Mago entrando a la oficina |
| `sergio_rescate` | `extras/sergio_rescate.ogg` | Música | −2 | no | el rescate de Sergio entero, 13.3 s |
| `aura` | `extras/aura.ogg` | Música | −6 | no | el tótem al pasar un nivel de la maquinita |
| `momo_cancion` | `extras/momo_cancion.ogg` | Música | 0 | no | el susto de Momo, 15.3 s, con su grito al final |
| `despertador` | `despertador.ogg` | Efectos | −8 | no | las campanadas de las 6 AM; **ya traen el grito de los niños al final** |
| `carta_toma`, `carta_pone` | `carta_<id>.ogg` | Efectos | −16 / −12 | no | agarrar y soltar una carta de la baraja decomisada |
| `es_impresionante` | `es_impresionante.ogg` | Voces | −2 | no | el botón de la CAM 3 |
| `rochis_extra_1..3` | `voces/rochis_extra_N.ogg` | Voces | −2 | no | **sin grabar**: más frases para ese mismo botón (ver abajo) |
| `urena_saludo`, `urena_linea1..7`, `urena_reaccion_*`, `urena_adios_*` | `voces/<id>.ogg` | Voces | 0 | no | la llamada de media noche de Ureña, línea por línea |
| `mamador_delito` | `voces/mamador_delito.ogg` | Voces | 0 | no | «¡Delito federal!», **antes** de la irrupción |
| `llamada_noche1`…`6` | `llamadas/llamada_nocheN.ogg` | Voces | 0 | no | la llamada con la que empieza esa noche |
| `telefono_colgar` | `telefono_colgar.ogg` | Efectos | −6 | no | al acabar o silenciar una llamada |
| `mamador_ok_1..3` | `voces/<id>.ogg` | Voces | 0 | no | ver **Líneas sueltas de profe** |

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

La llamada de Ureña es otra cosa: conversación con respuestas, en la ventanita de la esquina y
**con sus grabaciones**, una por línea (`urena_saludo`, `urena_linea1..7`, `urena_reaccion_*`,
`urena_adios_*`). Cada insinuación lleva **su** id en el banco de `data/urena_questions.gd`, no su
posición en la lista, porque las líneas se barajan y se eligen sin repetir.

Las voces de la llamada van como **secuencia** (`Sounds.SEQ_VOICE`): una línea nueva **calla la
anterior** en vez de encimarse. En una conversación interrumpir se entiende; esperar turno dejaría
la voz corriendo detrás del texto. Y el saludo se **escribe** con el nombre del jugador y la cuenta
de tareas, pero se **oye** sin ninguno de los dos, porque una grabación no puede decir cómo te
llamas.

**La llamada rara de la noche:** un número equivocado que entra **todas las noches, una sola
vez**, a una hora al azar entre la 1 y las 5 AM (`NightCalls.mencho_hour()`). La **noche 1 es
siempre la del Mencho**, para que todos la oigan; **desde la noche 2 se sortea**
(`NightCalls.random_call()`) entre `llamada_mencho` y `llamada_juguete`, evitando la de la noche
anterior. El teléfono suena como siempre y, al contestar, se oye el audio —que ya trae su efecto
de teléfono— con un único subtítulo corto, «¿Bueno? ...». **No cuenta como la llamada de la noche** y no abre
la ventanita: se oye y ya. El teléfono es uno solo, así que si justo está sonando la de Ureña o la
del Phone Guy, el Mencho espera a que acaben; si se le hicieron las 5 AM esperando, entra en
cuanto el teléfono quede libre.

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
| `lejos_portazo`, `lejos_silla`, `lejos_pasos_arriba`, `lejos_risa`, `lejos_platos`, `lejos_pasos_pasillo` | Uno al azar cada 40 a 120 s | Ambiente de un edificio vacío |

Los archivos van en `assets/audio/lejos/<id>.ogg`. Mientras no estén, suenan los provisionales de
`tone_builder.gd`.

## Líneas sueltas de profe

Frases de una sola tirada que dicen los profes en la oficina, con su **subtítulo pequeño** abajo
(encima de los de la llamada, para que no se tapen). Los textos y los ids están en
`data/voice_lines.gd`; los archivos van en `assets/audio/voces/<id>.ogg`, por el bus Voces.

**Barcosa no habla.** Sus cuatro frases se siguen **leyendo** cuando aporrea la cortina, pero no
tienen id de sonido ni archivo: son subtítulo y nada más. Las de Mamador sí están grabadas.

| Cuándo | Ids | Voz | Qué dice |
| --- | --- | --- | --- |
| Barcosa empieza a aporrear la puerta (una al azar) | `barcosa_puerta_1/2/3` | **solo texto** | "¿Quién cerró? Tengo clase en este salón." · "Abra, joven. Nada más paso lista y me voy." · "Diez minutos. Le estoy pidiendo diez minutos." |
| Barcosa se rinde y se va | `barcosa_se_va` | **solo texto** | "Bueno, ya. Quedan todos con falta." |
| Mamador inspecciona y no encuentra nada (una al azar) | `mamador_ok_1/2/3` | grabada | "Sin novedad. Me retiro." · "Nada de inteligencia artificial. Así me gusta." · "Todo en orden. Sigan así." |

El profe las pide con la señal `said_line(id)` de `Animatronic`; el `night.gd` se la pasa al nodo
`Hud/VoiceLine`, que reproduce la grabación si existe y, si no, deja el subtítulo el tiempo que se
tarda en leerlo.

**El nombre del jugador no se dice nunca en voz**, porque no se puede grabar:

- El saludo de Ureña se **lee** con el nombre y la cuenta de tareas, y se **oye** sin ninguno de
  los dos: la voz dice «ya vi que andas muy trabajador» (`GREETING` y `GREETING_SPOKEN`).
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
recorre las 38 pantallas del juego —abriendo también las capas que viven dentro de la noche— y
guarda un PNG de cada una con `scripts/ui/screen_capture.gd`. Van a `user://capturas/`, que en
Linux es `~/.local/share/godot/app_userdata/Five Nights at Rocha\'s/capturas/`. La herramienta se
cuelga de la raíz del árbol, no de una escena, porque va cambiando de escena. Ojo: pasar por las
pantallas de documentos y periódicos los deja marcados como vistos en `save.cfg`.

**Despausa el árbol antes de cada pantalla**: la pausa de la noche y el propio panel lo dejan
pausado y cambiar de escena no lo despausa, así que sin eso todo lo que viniera después salía en
blanco (los fundidos de entrada del recibo y de los documentos no corren con el árbol parado).

Seis capturas son de comprobación y no de catálogo. **`18d_derecha_rochis`** y
**`18e_derecha_come_trabas`** mandan a cada uno por su propio camino, le paran el reloj y giran la
cabeza a la vista derecha, para ver sus capas sin que haya game over;
**`16b_patch_panel_con_cable`** deja un cable en la mano, a medio camino entre su puerto y el
switch, que es donde se ve el conector girado. Las otras tres: **`18a_siluetas_sin_linterna`** y **`18b_siluetas_con_linterna`** meten a dos profes en
`pasillo_sur` **por su propia ruta** (no pintan las siluetas a mano: usan `move_to_step()`, y de
ahí en adelante manda el juego) para ver que a oscuras no se ve nadie y que con la linterna
aparecen en penumbra; **`18c_giro_a_la_mitad`** deja el barrido clavado al 50 % con
`office.debug_hold_sweep()`, para poder mirar el desenfoque siempre en el mismo punto.

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
  y la pantalla acaba con él. El confeti son triangulitos de colores que caen durante 4 s (`scenes/win_screen/confetti_fall.gd`, dibujado por código). Al acabar, el recorte de
  esa noche.
- **Game over:** un segundo de estática fuerte —con `estatica_inquietante_gameover` sonando
  debajo a −16 dB— y, al aclararse, la cámara vacía del lugar de donde salió quien te atrapó, en blanco y negro y con grano; encima "GAME OVER" y la causa a máquina.
  Clic en cualquier lado vuelve al menú, el botón repite la noche. El mapa de profe a cámara está
  en `Extras.ORIGIN_CAMERAS` (la CAM 10 no tiene `vacia`: usa `cam10_salio`).
- **El HUD va en VT323**, como todo lo que sale de una pantalla o un aparato, y con el reparto de
  los juegos originales: **la hora grande arriba a la derecha** (86 px), "NOCHE N" debajo y más
  chica (34 px), y la **energía abajo a la izquierda** (40 px). Los tamaños están en `night.tscn`;
  la fuente la pone `night.gd` en `_style_hud()`.
- **En las pantallas acercadas el HUD se achica a la mitad** (`_set_hud_compact()`): con la PC, el
  tablero del breaker o la sala de servidores abiertos, el reloj baja a 43 px y la noche a 17, y la
  energía a 20, para no taparles nada —el reloj grande se comía la hoja de etiquetado del rack y el
  marco del monitor—. Al volver a la oficina vuelven a su tamaño.
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
  al abrir la hoja) **sin repetir la misma dos veces seguidas**; si no hubiera ninguna, la tecla se
  escribe sin sonido. **No hay cajas ni botones.** Con Enter
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
  se ve desde la oficina, se dibuja al fondo con `layers/silueta_<id>.png`. **A oscuras no se ve
  nada**, igual que con los profes pegados al cristal: fuera del cono su alfa es 0 y no se dibujan.
  Dentro del cono se ven **tal cual están pintadas**: ni brillo ni desenfoque
  (`SILHOUETTE_LIT_BRIGHTNESS` en 1.0 y `SILHOUETTE_BLUR_PIXELS` en 0). El arte ya viene con su
  penumbra y su distancia —están detrás del segundo cristal—, así que no hay nada que tratar. El
  shader conserva los dos mandos (`lit_brightness` e `inside_blur`) por si alguna capa los
  necesita. Hay cinco (Barcosa, Mamador,
  Ureña, Juan.exe y Armando) y **pueden verse varias a la vez**: cada una tiene su sitio y ninguna
  se encima con otra, comprobado con `tools/measure_office_layers.py`. Si falta el archivo de
  alguien, no se dibuja nada.
- **Capas de la vista derecha**, el paso hacia los cubículos: `derecha_rochis.png` cuando Rochis
  se asoma al marco y `derecha_come_trabas.png` cuando la botarga sale del cubículo 3 (ahí el
  fondo cambia además a `oficina_derecha_vacia.png`, que ya trae la silla vacía). **En la vista
  central no se dibuja ninguno de los dos**: desde ahí los tapan las persianas del cubículo, así
  que la zona `cubicles_side` ya no lleva ni capa ni etiqueta. Los dos van con el mismo parallax
  que la vista y debajo de la oscuridad, como las demás capas, y sus recuadros están medidos en
  `OfficeLayers.RIGHT_BOXES`. Mientras Rochis sigue en el cubículo no se ve nada de él en ninguna
  vista: lo único que se oye es `rochis_silla` al cambiar de etapa.
- **Capas desactivadas** (`OfficeLayers.DISABLED`): `centro_barcosa.png`, que solo salía cuando
  Barcosa aporreaba la puerta y ahora eso no se dibuja (está detrás de la cortina), además de
  estar colocada para la oficina vieja.

**Orden de dibujo de la vista central:** fondo → **siluetas** → **cortina** → profes pegados al
cristal → etiquetas de presencia. Las siluetas van debajo de la cortina a propósito: con la lámina
abajo, Barcosa al otro lado de la puerta queda tapado; los que están pegados al cristal, no.

Dónde cae cada profe dentro de su recorte, y dónde tiene Armando el ojo, está en
`data/office_layers.gd`. No se adivina: lo mide `tools/measure_office_layers.py` sobre los propios
PNG (el recuadro de los píxeles opacos, y el píxel naranja más brillante de `centro_armando`). Si
cambia el arte, se vuelve a correr.

**El teléfono cuando suena** (`scenes/office/phone_light.gd`): enciende el LED y la pantallita que
ya trae la foto y los sacude un poco con cada timbrazo. **Solo suma luz, nunca pinta encima.**
Antes también repintaba un pedazo de la foto corrido, para que el teléfono entero temblara; pero
esa foto es la del pasillo **a oscuras**, así que con la linterna encendida dejaba un cuadrado
negro alrededor del teléfono, tapando la foto iluminada.

**Cortina de la puerta:** la caja del rodillo **ya viene pintada en las cuatro fotos de la vista
central**, así que el código no la dibuja (`DRAW_ROLLER_BOX` fuera) y **ya no hay oclusores**: no
queda nada delante de la puerta que tape la lámina.

La lámina es su propia capa, `assets/art/office/cortina_capa.png`, del tamaño de la vista y ya
colocada en su sitio (ocupa x 407, y 250, 150 x 271 sobre la imagen de 1375x768). Al cerrar la
chapa se va revelando de arriba hacia abajo en **0.6 s**, con el sonido `puerta_cortina`; al abrir,
a la inversa. Al terminar de bajar, la vista central cambia a las fotos `*_cerrada` (la oscura y la
iluminada) y la capa deja de dibujarse, porque a partir de ahí la cortina la trae el fondo.

Mientras se mueve, la lámina tiene **sus dos fotos, igual que el fondo**:
`cortina_capa_oscura.png` fuera del cono de la linterna y `cortina_capa.png` dentro, del mismo
tamaño y en la misma posición. Las mezcla `scenes/office/shutter_reveal.gdshader`, que recibe la
oscura en `dark_texture` y usa las mismas UV para las dos, así que la lámina no se mueve ni un
píxel al pasar de una a otra. Antes era una sola foto, la iluminada, con el brillo bajado: se veía
alumbrada aunque el pasillo estuviera a oscuras. Por eso el cono abarca también la zona `entrance_door`, que es el
fondo del pasillo. En la CAM 2, si la puerta está cerrada, el código encima sobre la imagen del estado actual el recorte de `cam02_cortina` en el rectángulo normalizado x 0.729, y 0.223, w 0.1245, h 0.752 (definido en `data/camera_overlays.gd`, que se mide sobre la imagen y no se adivina). Las imágenes `cam02_barcosa-golpeando` ya traen la cortina abajo y no llevan el recorte encima. En la CAM 2, Mamador se pinta a la izquierda de la puerta, frente al cristal del sillón, para no quedar tapado por la cortina.

**El vistazo «de reojo»:** en **1 de cada 150 cambios de cámara**
(`AmbientEvents.GLIMPSE_ONE_IN`), la cámara a la que acabas de cambiar enseña durante **0.5 s** la
imagen de acecho de un profe al azar —la de otra cámara, da igual cuál— con el golpe de
`sonido_perturbador`, y vuelve sola a lo que tocaba. **No hace nada más**: ni mata, ni quita
energía, ni mueve a nadie. Es para que el jugador dude de lo que vio.

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
- **Mamador (rol Freddy):** empieza en la sala de juntas. Ruta CAM 13 → 1 → 2 → cristal; reserva el pasillo antes de entrar a pasillo_norte. Al llegar revisa **tres** cosas: la ventana de la IA abierta en la PC, la puerta cerrada y **la baraja de UNO afuera**. Con las dos primeras es game over "Delito federal" (llegan los militares); con la baraja, el mismo final pero con causa **"Ludopatía"** y el cartel de abajo "LUDOPATÍA" en vez de "DELITO FEDERAL". Si tienes las dos cosas afuera manda la baraja, porque ese cartel es el que vale la pena ver y el otro se consigue de sobra. Si no encuentra nada, dice su frase y se va. Tiene sonido propio de aviso.
- **Ureña (rol Chica):** lento. Ruta CAM 12 → 11 (o salón sin cámara) → 2 → cristal. Se aleja con destellos de linterna (ver **Destellos en el cristal**).
  - **Llamada de Ureña (comedia):** cada noche que Ureña está activo, puede llamar entre las 2 y las 4 AM (60 %; en noches 5 y 6 hasta dos llamadas). La llamada no bloquea el juego: Ureña habla en altavoz y sus textos salen en un recuadro pequeño en una esquina, mientras el jugador sigue usando cámaras, puerta y linterna. Saluda con el nombre del jugador, lo felicita por sus tareas y le hace 1 o 2 insinuaciones (banco en `data/urena_questions.gd`). Cada una tiene 3 respuestas barajadas, elegibles con las teclas 1, 2 y 3 o con clic, y 6 s para elegir: la correcta esquiva con educación (no pasa nada); `sigue_el_juego` quita 5 % de energía y deja la foto en el escritorio; `grosera` quita 5 % sin foto; sin respuesta cuenta como `sigue_el_juego`. Se puede colgar en cualquier momento (o no contestar), pero Ureña se ofende: deja la foto y su nivel sube +5 durante una hora de juego. Ya no hay game over por no contestar. Se despide según cómo le fue. Los demás profes siguen moviéndose.
- **Rochis (rol Bonnie):** en CAM 3 pasa de sentado a medio levantado a de pie. Mientras se levanta hay que reproducir el audio "es impresionante" hasta que se vuelva a sentar.
  El botón suelta **una de sus frases al azar** (`Sounds.rochis_line()`): hoy siempre
  «es impresionante», y en cuanto existan `voces/rochis_extra_1..3.ogg` entran al sorteo con ella.
  Las que no tengan archivo no entran, así que no hay que tocar código para añadirlas. Reproducirlo cuando ya está sentado lo molesta y acelera su avance. Si llega a estar de pie, entra a la oficina, dice el nombre del jugador y es game over.
- **Mago Eléctrico (rol Balloon Boy; antes Audel Electrix):** en pantalla y diálogos se llama "Mago Eléctrico"; en código, ids, estados y archivos se sigue usando `audel` (por ejemplo `cam06_audel-acecho`, `centro_audel.png`) para no romper nada. vive en el techo (CAM 6), baja por la escalera (CAM 5). Si se baja el breaker mientras está en la escalera, regresa al techo. Si entra, hace un "cortaso": la linterna deja de funcionar y se pierde parte de la energía. No mata directamente.
  - **Susto del cortaso (sin muerte):** cuando el Mago entra a la oficina, la pantalla se va a negro, sale `jumpscare_audel_susto` 0.5 s con un chispazo y una risa, y después la linterna queda inservible. Con la linterna muerta **el pasillo se queda a oscuras**: no hay cono, no se ve quién está en el cristal y no se le pueden contar destellos a nadie. Eso es parte del castigo.
  - **Muerte por apagón:** cuando la energía llega a 0 % todo se apaga y empieza una
    secuencia de cuatro tiempos, en `blackout_death.gd`. Justo al apagarse todo, antes de la
    oscuridad, suena `apagon_frase`; después, 3 a 12 s al azar de oscuridad total, **que se
    estiran si hace falta hasta que la frase termine de decirse** (son 6.4 s y el azar puede dar
    3: son de la misma secuencia y no se enciman);
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
  - **Descarga del pararrayos:** mientras el Mago Eléctrico está en el techo (CAM 6), de vez en cuando provoca una descarga que desconecta algunos patch cords en la sala de servidores. Suena `descarga_pararrayos` al soltarla, y `cortaso` cuando entra a la oficina a dejarte sin linterna. Las cámaras afectadas muestran "SIN SEÑAL" hasta que el jugador entra a la sala de servidores (vista derecha de la oficina) y reconecta cada cable en su puerto según la hoja de etiquetado pegada en el rack (por ejemplo, CAM 03 → PP-07 → SW1 Gi0/7).
    **Los conectores enchufados y el de la mano no se dibujan igual.** De un puerto ocupado no se
    ve el conector, se ve **lo que le sobresale por detrás**: un culote corto del color del cable y
    muy oscurecido, con la funda detrás un poco más ancha y sin contactos dorados, y **derecho**,
    hacia abajo en el patch panel y hacia arriba en el switch. Eso lo dibuja el código. Antes los 24
    llevaban la imagen del RJ45 de frente y el rack parecía empapelado de calcomanías; y siguiendo
    la curva de su cable salían todos torcidos en ángulos distintos. Los anchos van en fracción del
    ancho del puerto y la funda no pasa de 0.90, porque los puertos del switch están a 0.0269 de
    paso con 0.0263 de ancho y con más se tocarían entre vecinos.
    **La imagen `assets/art/office/rj45.png` es solo para el conector suelto**, el que cuelga y se
    arrastra, que sí se ve entero: va girado hacia donde va su cable, a 1.2 veces el ancho del
    puerto y con el color multiplicado por 0.5, porque la foto viene de día y el rack está casi a
    oscuras. El PNG trae el conector **y su cable**, pero el cable lo dibuja el código, así que solo
    se usa el trozo del conector, de la punta a donde empieza la funda azul: ese recorte se **mide**
    con `tools/measure_office_layers.py` (`PLUG_BODY` en `patch_panel_view.gd`). Mientras está en la sala, no vigila la oficina.
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
- **Armando Prompts (rol Chica clásico + Lolbit):** profe que se cree genio, presume títulos inventados y todo lo automatiza con IA. Misma ruta y misma mecánica de linterna que Juan.exe. Además, desde la noche 4, cada vez que el jugador pulsa "Resolver tarea" del asistente Claudio hay probabilidad de que su cara tome toda la pantalla de la PC con una frase al azar; hay que escribir "APÁGATE" en 6 s. **Armando no habla**: su frase es solo texto en pantalla. Al
aparecer suena `armando_windows_crash` y, debajo, `armando_glitch_bucle` en bucle a −18 dB mientras
dura la toma; los dos se callan al escribir APÁGATE o al acabarse el tiempo. Si no, borra el progreso de la tarea actual y quita 5 % de energía. Frases: "HOLA, SOY ARMANDO PROMPTS, INGENIERO EN PROMPTS CERTIFICADO POR MÍ MISMO.", "LE PEDÍ A CLAUDIO QUE HICIERA TU TAREA. TAMBIÉN LE PEDÍ QUE TE CORRIERA.", "ESTE MENSAJE FUE GENERADO CON IA. YO NI LO LEÍ.", "MI TESIS LA HIZO CLAUDIO. MI BODA TAMBIÉN.", "AUTOMATICÉ MIS SENTIMIENTOS. AHORA SUFRO 40% MÁS RÁPIDO.", "¿PENSAR? NAH, ESO ES DE BOOMERS."
- **Claudio (asistente IA de la PC):** parodia de un asistente de IA. Logo propio: una chispa o asterisco naranja terracota con lentes tipo Clark Kent (que evoque la referencia sin calcar ningún logo real). Ventana con fondo crema y acentos naranja. Personalidad exageradamente educada: empieza cada respuesta con "¡Excelente pregunta!" y pide disculpas por todo.

## Alucinaciones

Desde la noche 2, de vez en cuando aparece **un solo cuadro durante 0.1 a 0.2 s** con un golpe
grave —uno de `golpe_grave_1..3` al azar, nunca el mismo dos veces seguidas
(`Sounds.low_hit()`)—, y se va. No hacen nada: ni matan, ni quitan energía, ni hay nada que contestar; están solo
para que el jugador dude de lo que vio. Son raras, se hacen más seguidas en las noches altas y
**nunca sale una antes de 90 s** desde la anterior. Los números y los cuadros están en
`data/hallucinations.gd`; la capa es `scenes/night/hallucination_overlay.gd`.

| Cuadro | Qué se ve |
| --- | --- |
| `foto_esposa` | La foto de la esposa difunta de Rochis, recortada de la capa de la CAM 3 y a pantalla completa, mirando de frente. |
| `es_impresionante` | "ES IMPRESIONANTE" en rojo sobre el monitor. Solo sale con la PC abierta, que es cuando se ve la pantalla; si está bajada, se elige otro. |
| `botarga` | La botarga sentada en la silla de la oficina: su propio jumpscare muy oscurecido, para que se adivine la silueta. |
| `expediente` | Un expediente cualquiera con el nombre del jugador escrito donde va el del profe. El valor del campo NOMBRE empieza en x 0.072, y 0.253 y llega a x 0.296, con alto 0.033, sobre una hoja girada −2.5°: el parche (color del papel #d6c49e) y el nombre se giran ese mismo ángulo apoyados en esa esquina. El nombre va en Special Elite a 30 px en 1080p, color #282019. |

## Sergio y el tótem

El rescate: si te van a matar y traes el tótem —o si tienes suerte en las noches altas—, Sergio
baja y te salva. **Ya está programado.** Los números de diseño están todos en `data/sergio.gd`, y
las medidas que salen del arte se midieron sobre los propios PNG, no se adivinaron.

**El tótem se ve en la oficina.** Mientras lo traes encima está **de pie sobre el escritorio**, en
la vista central, entre la tabla de las hojas y el teléfono; y además su ícono sigue en la esquina
del HUD, que es lo único que se ve desde las otras vistas o con la PC abierta. Las dos cosas las
enciende la misma señal, `GameManager.totem_changed`.

No hace falta arte nueva: es el mismo recorte `totem_virgen_icono.png`, colgado del `Content` de la
vista central, así que **se mueve con el mismo parallax**, se desenfoca con el giro y se apaga con
el apagón sin tratarlo aparte. El sitio y el tamaño están **medidos sobre
`oficina_centro_oscura.jpeg`** y viven en `data/sergio.gd`: apoya en x 0.518, y 0.880 y mide 0.091
de alto (70 px de la foto, poco más que una de las tazas). **La y no puede bajar de ahí**: la vista
se dibuja al 112 %, de la foto solo se ve de 0.054 a 0.946 de alto, y más abajo lo taparía la barra
de cámaras.

El recorte viene a pleno brillo y la oficina está a oscuras, así que se baja con
`TOTEM_DESK_LIGHT`, que también está medido: deja su halo dorado (230 de 255) en 30, el mismo
brillo que tienen las tazas y el teléfono en esa foto, con un tinte frío como la luz del monitor.
Para que ese `modulate` llegue, `office_view.gdshader` se trae el del nodo desde el `vertex` (al
escribir `COLOR` en el `fragment` se perdía); las fotos van en blanco, así que a ellas no les
cambia nada.

**El arte** está en `assets/art/extras/sergio/`: `centro_sergio.png` (1375x768, la capa de la vista
central), `sergio_silueta.png` (176x297), `totem_virgen.png` (401x622) y
`totem_virgen_icono.png` (100x155). Su figura mide **170x291 px en las dos imágenes**, y de ahí
sale que la silueta pueda bajar a la misma escala y encajar al píxel.

### Cómo se consigue el tótem

**Solo se puede tener uno**, y **se guarda en `save.cfg`** (`has_totem`), porque se gana entre
noches: si no sobreviviera al cambio de pantalla, el de la maquinita se perdería antes de usarse.
Al gastarlo en un rescate se borra del guardado.

- **Al azar:** en las noches **4 a 6**, cuando vas a morir hay un **25 %** de que Sergio te
  rescate aunque no traigas nada (`Sergio.RANDOM_FROM_NIGHT`, `RANDOM_CHANCE`).
- **La maquinita:** ver **La maquinita (minijuegos estilo FNAF)**, abajo.

### El rescate, paso por paso

El choque está en `GameManager.trigger_game_over()`: **antes de matar** se le pregunta a Sergio, y
si entra, no hay game over y la noche sigue. Vale para cualquier profe **menos Mamador**, cuyo
final es la pantalla de WASTED y no se interrumpe. Mientras corre, `is_rescuing` evita que otro
profe mate, el reloj se detiene y los profes se quedan quietos.

**Todo el rescate va pegado a una sola pista**, `extras/sergio_rescate.ogg` (18.8 s), que lleva
dentro el suspenso, el aire del haz y el aura del tótem. La escena se cuelga de sus tiempos
(`Sergio.RESCUE_BEAM_AT` 6 s y `RESCUE_TOTEM_AT` 14 s) y **acaba cuando acaba el audio**: ahí
sigue la noche. Antes eran tres sonidos sueltos (`rosa_suspenso`, `rosa_aire` y `aura`) que se
encimaban entre ellos; esos ids ya no se usan aquí y `aura` se quedó solo para la maquinita.

1. **El susto congelado** (`scenes/night/sergio_rescue.gd`): el **primer cuadro** del jumpscare que
   iba a matarte —su variante `_a`— quieto y en blanco y negro, hasta el segundo **6**.
2. **La bajada** (`scenes/office/sergio_arrival.gd`, en la vista central, que se fuerza): el susto
   se desvanece, suena `rosa_aire` y un **haz de luz blanca** baja sobre la recepción (44 tiras con
   su degradado, para que no se vean escalones). Dentro del haz, `sergio_silueta.png` aparece por
   encima del borde y **desciende flotando 1.5 s** con un vaivén que se va calmando, hasta el sitio
   exacto donde está Sergio en la capa; al llegar, **se funde en 0.3 s** con `centro_sergio.png`,
   que se queda mientras corre el tótem.
3. **El tótem**, a los **14 s**, como el de Minecraft y con filtro nearest: aparece chiquito al centro, **crece con
   un rebote** hasta el **45 % del alto** (0.35 s), **tiembla 1.2 s**, y **gira sobre su eje
   vertical** (la escala X de 1 a −1 y de vuelta, **dos veces**) mientras se encoge y sale volando
   hacia arriba (0.9 s). Todo el rato suelta **70 partículas cuadradas** verdes y amarillas que
   salen del centro y caen.
4. **Lo que queda:** Sergio se desvanece (0.6 s) mientras suena la cola de la música; al acabarse
   el audio, el profe que iba a matarte **vuelve al principio
   de su ruta** (`Animatronic.go_home()`, que Barcosa y los del cristal sobrescriben para soltar el
   pasillo y poner su susto a cero), **pierdes el tótem**, **recuperas 10 % de energía** y
   **Sergio no vuelve esa noche**.

### En el panel de pruebas

F1 → Eventos: **"Probar Momo"**, **"Dar tótem"**, **"Probar rescate de Sergio"** (monta la escena
con el primer profe que pueda matar) y **"Abrir minijuego (nivel 1)"**, **"(nivel 2)"** y **"(nivel 3)"**. Como la
maquinita es una pantalla completa, al salir de ella **la noche vuelve a empezar**: es un botón de
pruebas, no un atajo del juego.

## La maquinita (minijuegos estilo FNAF)

Los minijuegos de 8 bits, como los de Sister Location y FNAF 3: cuentan en pixel art lo que le
pasó a Santi, y pasarlos es lo que te da el tótem. Todo lo de diseño está en `data/arcade.gd` y
las medidas salen de los tres fondos, que son de **160x90**.

**Cuándo sale:** entre noches. Desde la noche 1, al pasar una noche hay un **30 %**
(`Arcade.CHANCE`) de que, **después del 6 AM y antes del periódico**, entre la maquinita; **si ya
traes el tótem, no sale**, porque es justo lo que viene a darte. Cada vez que sale juegas el
**siguiente** nivel —1, 2, 3— y a partir de ahí salen al azar; el que toca se guarda en `save.cfg`
(`arcade_level`). **Perder no hace avanzar**: `advance_arcade_level()` se llama al terminar el
final del altar, no al empezar, así que la próxima vez te toca **el mismo nivel** hasta pasarlo.

### Las reglas que comparten los tres

- **Tres vidas**, dibujadas como corazones de píxeles arriba a la izquierda. El contador del
  objetivo va **arriba al centro** ("VASOS 7/15") y el reloj **arriba a la derecha**, en rojo
  cuando quedan menos de 20 s.
- **150 s por nivel** (`Arcade.TIME_LIMITS`). Hubo un rato en que el 2 necesitó 210, pero eso era
  un síntoma, no el problema: lo que no dejaba acabarlo eran los globos que reventaban en cada
  viaje. Arreglado eso se pasa de sobra.
- **Al cobrar un golpe**: parpadeo, **1 s de invencibilidad** (para que un roce no cueste dos
  vidas) y una vida menos, con su sonido `arcade_golpe`.
- **Con 0 vidas o sin tiempo**: "GAME OVER" en la fuente de 3x5 a triple tamaño
  (`arcade_over.gd`), estática, la tele se apaga y sigue el periódico **sin tótem**.
- **Los niveles tienen scroll horizontal**: miden de cuatro a cinco pantallas
  (`Arcade.WORLD_SCREENS`) y la cámara va centrada en Santi. El fondo es una sola foto de 160x90,
  así que **se repite** a lo largo del mundo; las mesas de cada repetición sirven de plataforma.
  `ArcadeLevel._paint()` dibuja en **coordenadas del mundo**: la cámara ya está puesta.
- Lo que el arte no tiene —el piso de arriba, las escaleras, los huecos, las piñatas, los
  ventiladores, las macetas, las sillas— lo dibuja el código con rectángulos, en los colores del
  propio fondo. Los sprites de `assets/art/minijuego/sprites/` se usan tal cual.

**La física, de una vez para los tres** (`WALK_SPEED` 56, `JUMP_SPEED` 112, `GRAVITY` 260): el
salto sube **24 px** y alcanza **40 px** de largo. De ahí salen las reglas de la geometría —ningún
hueco pasa de 18 px, ningún escalón sube más de 12— y por eso los peldaños **se encabalgan**: con
peldaños estrechos y sueltos, un salto a toda velocidad se pasaba de largo y no había manera de
subir.

### Nivel 1, "La posada" (plataformas)

Cinco pantallas, **dos pisos**: el patio de abajo —con las tres mesas de la foto como escalón— y un
entarimado arriba al que se sube por **escaleras de tres peldaños**. Hay que juntar **15 vasitos**
repartidos entre los dos pisos y, con los quince, tomar el termo del final; ahí aparece el hombre de
traje, la pantalla se queda quieta un segundo y Santi ya es la botarga, igual que antes.

- **Los huecos del piso** (cinco) te tiran: una vida y **reapareces en la última plataforma en la
  que estabas a salvo** (`_safe_at`, que se apunta en cada aterrizaje firme). Van **debajo del
  entarimado**, nunca en su punta, para que bajarse de una tabla no sea una caída segura.
- **Tres alumnos borrachos** patrullan de un lado a otro, cada uno en un tramo **entre dos escaleras
  y sin huecos debajo**: patrullar al pie de una escalera era injusto (cada vez que bajas de un
  peldaño caes encima de uno) y sobre un hueco se les veía caminar por el aire. Su alcance en
  vertical es corto (`HIT_RANGE`, 10 px) justo para que subirse a un peldaño sirva de algo.
- **Dos piñatas** se columpian **a la altura de la cabeza del que va por el patio de abajo**: ahí
  está la gracia de pasar por debajo en el mal momento. Se esquivan esperando o saltándolas; desde
  el piso de arriba no alcanzan.
- **Charcos de ponche**: al pisarlos, el agarre se va al suelo un segundo (`SLIP_GRIP` contra
  `NORMAL_GRIP`) y Santi sigue de largo.

### Nivel 2, "La bienvenida" (entregas con persecución)

**Cuatro pantallas, el más corto de los tres a propósito.** Se recoge un globo en el puesto de la
izquierda y se lleva a uno de los **ocho alumnos**; **solo se puede cargar uno**, así que cada
entrega son dos viajes. El alumno desaparece al recibirlo.

Ese "dos viajes por entrega" es lo que manda en la medida del nivel: con los alumnos repartidos por
cinco pantallas salían **99 s de caminata perfecta**, que no caben en los 150 s del reloj en cuanto
fallas una vez. Por eso van juntos, de x 96 a x 474: **75 s** de caminata limpia, y la partida sale
en unos dos minutos con los rodeos.

- **Los ventiladores del techo** (tres) revientan el globo si saltas debajo. No quitan vida: te
  hacen volver por otro. Van **entre alumno y alumno**, nunca encima de uno, y **el primer tramo
  saliendo del puesto va limpio**: acorralarte donde entregas, o en la única salida, no te dejaba
  más opción que reventar el globo. Con seis aspas el nivel era ir y venir sin avanzar nunca.
- **Desde la cuarta entrega** el hombre de traje aparece por el borde que ella deja atrás y la
  persigue, más rápido con cada entrega. Si la toca, una vida y vuelve al borde.
- **Nunca corre más que ella** (50 contra 56) y, sobre todo, **en el aire no la toca**: saltarle por
  encima es la salida, porque cada vuelta al puesto es pasarle por delante. La regla es esa, sin
  umbrales de altura: con cualquier margen en píxeles te pillaba en el despegue o en el aterrizaje.
  Además lleva **0.3 s de gracia al aterrizar** (`LAND_GRACE`) y él **se queda 2.5 s en el borde**
  tras pillarla (`SUIT_RECOVER`): sin lo primero te cazaba al caer al otro lado, y sin lo segundo
  volvía derecho a por ti y te quitaba las tres vidas en el mismo metro cuadrado, porque al puesto
  hay que volver siempre.
- **El salto hay que elegirlo**, y ahí está el nudo del nivel: el arco mide 48 px, así que saltarle
  por encima **pegado a un ventilador te mete el arco entero debajo del aspa** y el globo revienta
  igual. Lo que funciona es retroceder —él te sigue— hasta que los dos estéis en claro y brincarle
  ahí. Por eso las aspas son tres y no seis, y por eso el primer tramo va limpio.

### Nivel 3, "La junta" (sigilo)

Cinco pantallas de pasillo, en tres partes seguidas.

**A, seguirlo** (unos 60 s): el de traje camina despacio y cada tanto se para y voltea, avisando con
los **ojos rojos 0.6 s antes**. Si al voltear te ve **en movimiento** a menos de 40 px, una vida.
Te salva **quedarte quieto**, o estar detrás de una maceta, una columna o un marco de puerta
(`L3_COVER`). Si te quedas **más de una pantalla atrás durante 3 s**, sale "LO PERDISTE" y también
cuesta una vida; mientras tanto **él te espera**, que si no se iría solo.

**B, la oscuridad** (desde `L3_DARK_FROM`): se va la luz y solo se ve un círculo alrededor de Santi
—recortado fila por fila sobre el negro— y la **veladora** del fondo parpadeando. Hay huecos que
solo se ven de cerca, y en medio la **botarga tirada** con su "AYÚDANOS".

**C, el escape**: la puerta de la sala se cierra, un segundo de rojo y el de traje viene **rápido**.
Hay que volver por el pasillo **saltando las sillas tiradas**, que son lo que te puede costar la
carrera: él va a 52 y tú a 56, así que solo te alcanza si tropiezas. La música **sube de tono**
(`ESCAPE_PITCH`, 1.35), que es lo único que cambia de tempo en todo el juego. Si te alcanza no es un
rasguño: **se pierde la vida entera y se repite la parte C** desde el principio —ese es el
checkpoint—; si era la última, se acabó. Llegando al final del pasillo entra el final del altar.

### El final y la comprobación

**El final** (`arcade_ending.gd`) no cambia: negro con el haz de luz, el altar al centro, Sergio de
silueta a un lado y Santi al otro, y **"TOMA. TE VA A HACER FALTA."** escribiéndose letra por letra.
Suena `aura` y **te queda el tótem**.

**El sonido es chiptune generado por código** (`ToneBuilder`, ondas cuadradas): `arcade_nivel1`
alegre, `arcade_nivel2` la misma melodía **desafinada**, y `arcade_nivel3` **sin melodía, solo un
zumbido grave**; más `arcade_salto`, `arcade_recoge`, `arcade_golpe`, `arcade_bip` (el arranque) y
`arcade_cajita`.

**El texto de dentro del lienzo no es VT323**: es `data/arcade_font.gd`, una fuente de **3x5
píxeles** dibujada por código. A 10 px el rasterizador suaviza VT323 y, al ampliar el lienzo siete
veces, ese suavizado se vuelve manchas grises ilegibles.

**Que se pueden pasar está comprobado con un bot**: un script de pruebas lee el estado del nivel y
manda teclas con `Input.parse_input_event`, como una persona. Es lo que destapó que las escaleras
no llegaban a ninguna tabla y que un vasito estaba dentro de un hueco. En el panel de pruebas,
F1 → Eventos tiene **"Abrir minijuego (nivel 1/2/3)"** y **"Nivel 3 parte C"**, que entra directo
a la persecución.

## Momo

El susto que **no mata**. Sale al girar a la **vista izquierda**, desde la **noche 2**, **una vez
por noche como mucho** y con un **6 %** cada vez que la cabeza llega ahí (`data/momo.gd`). No entra
si ya hay otro susto en curso (un jumpscare, el apagón, un rescate de Sergio). El arte es
`assets/art/extras/momo/momo_izquierda.png` (1375x768, la misma composición que la vista izquierda
pero a oscuras, con luz de luna) y `momo_screamer.png`.

**El juego se para por completo** mientras dura: el reloj, la IA de los profes, el consumo de
energía y los controles —no se gira, no se abre nada, no se pausa—. El ambiente y la llamada que
estuviera sonando **se quedan congelados donde van**, no se cortan
(`AudioManager.set_paused_except()`), y al acabar siguen. Lo único que se oye es
`extras/momo_cancion.ogg` (15.3 s).

| Momento | Qué pasa |
| --- | --- |
| 0.0 s | **Parpadeo de luz**: dos o tres cortes a negro de 80 ms. En el último, ya a oscuras, la vista izquierda cambia a la foto de Momo |
| 0.0 → 15.3 s | Suena su canción. La vista **se va acercando a él**, de 1.0 a 1.06, con el pivote en su cara (x 0.62, y 0.45). **El parallax del mouse sigue funcionando**: es lo que mantiene la sensación de estar ahí |
| 12.10 s | **El screamer** a pantalla completa sobre negro, creciendo del 60 % al 120 % del alto en 0.3 s, con temblor fuerte y parpadeo. Se queda **1.2 s** y se corta: un golpe corto asusta más que uno que se queda mirándote |
| 13.3 s | Corte a negro de 0.3 s, con la canción yéndose en ese fundido, y vuelve la vista izquierda de siempre. **No mata, no quita energía y no mueve a nadie**: la noche sigue exactamente donde estaba |

El reparto es el de siempre: `scenes/night/momo_event.gd` lleva lo que va a pantalla completa (el
parpadeo, el screamer, el negro) y le pide a la oficina lo suyo por señales —`set_momo_active()`
pone su foto como una capa más del `Content` de la vista izquierda, así que se mueve con el mismo
parallax sin tocar nada, y `set_momo_zoom()` la acerca—. El `night.gd` es quien tira el dado (con
la señal `view_changed` de la oficina) y quien para y suelta el juego. Para que no se pueda tocar
nada sin matar el parallax, la oficina tiene `set_locked()`, que bloquea el giro, los clics y la
linterna pero **deja el recorrido del mouse vivo**.

Se prueba desde F1 → Eventos → **"Probar Momo"**.

## Jumpscares

Las imágenes están en `assets/art/jumpscares/`: `jumpscare_<id>.png` y `jumpscare_<id>_a.png` para barcosa, urena, rochis, juan, armando, cometrabas y audel, más `audel_susto` y `mamador_militares`.

La animación de cada muerte es la misma: la variante `_a` durante 0.12 s, corte a la imagen final con un zoom de 1.0 a 1.15 en 0.5 s, temblor fuerte, un destello blanco de un cuadro y un grito; después estática y la pantalla de game over con su causa.

**El grito va siempre y a 0 dB**, encima de la estática: nunca se oye solo el siseo. Lo elige
`Sounds.scream_for(slug)`: el grito propio del profe (`grito_<id>`) si está grabado y, si no,
`grito`, que lleva provisional por código. **Los siete propios ya están grabados** (`gritos/grito_<id>.ogg`); el de Ureña es una risa, y es lo que
se oye en su jumpscare.

Mamador no salta: su game over es la **pantalla de WASTED**, al estilo GTA
(`scenes/ui/wasted_screen.gd`). Ya no lleva luces de policía.

| Cuándo | Qué pasa |
| --- | --- |
| antes | **Lo que grita y la irrupción**: pantalla en negro, `mamador_delito` («¡Delito federal!», 0.9 s), después `mamador_brecha` (la puerta derribada y los gritos del operativo, 3.8 s) y un flash blanco de un cuadro. **Dura lo que duren los dos**, uno detrás de otro: van en la misma secuencia, así que la irrupción espera a la frase y el golpe de WASTED espera a la irrupción. Solo lo lleva Mamador: se pide con el parámetro `breach` de `WastedScreen.play()` |
| 0.0 s | `jumpscare_mamador_militares` a pantalla completa, con un zoom de 1.0 a 1.08 que no para en toda la secuencia |
| 0.4 s | La imagen se va a blanco y negro en 0.8 s y baja un poco de brillo |
| 1.2 s | Entra una franja negra (alfa 0.55) de lado a lado, centrada, de alto 16 % de la pantalla, con fade de 0.3 s |
| 1.2 s | Encima, "WASTED" en `assets/fonts/pricedown.otf`, rojo #C21E1E con contorno negro, escalando de 1.15 a 1.0 en 0.25 s, **y con él el golpe de `wasted`**: nunca cae encima de la irrupción |
| 2.2 s | Debajo de la franja, el texto de abajo en la misma fuente, blanco con contorno, al 40 % del tamaño de WASTED |
| 5.2 s | Pasa a la pantalla de game over normal, con su causa |

**El texto de abajo es un parámetro**, así que la pantalla se reutiliza: lo elige
`JumpscareOverlay.mamador_text(causa)`, que pone "DELITO FEDERAL" con la ventana de Claudio o la
puerta cerrada y "LUDOPATÍA" con la baraja afuera. Si falta la fuente se cae a
Oswald en negritas (`Fonts.display()`), y si falta `wasted.ogg`, a un provisional por código.

La galería de Jumpscares de Extras **reproduce de verdad**: clic en una ficha y sale su salto, y
la de Mamador lanza esta misma pantalla de WASTED.

## Reglas para que las mecánicas no choquen

1. El pasillo es de uno a la vez entre Barcosa y Mamador: si uno lo "reserva", el otro espera.
2. Mamador ignora la linterna, el breaker y las cámaras.
3. Cada amenaza tiene una contramedida distinta; ninguna se resuelve con la de otra.

## Tareas

Cada noche pide de 2 a 5 tareas (minijuegos de 20 a 60 s) para que le paguen al guardia. Casi todas se hacen en la PC; las del tablero de pastillas y el patch panel se hacen en la sala de servidores, dejando la oficina sin vigilar, y **la baraja de UNO se hace en el propio escritorio** (ver abajo). La IA de la PC las resuelve o da pistas, pero su ventana abierta delata al jugador ante Mamador.

**Tickets durante la noche:** las tareas no están todas desde las 12. Llegan como tickets repartidos en la noche (el primero al inicio y los demás espaciados hasta las 5 AM, con algo de azar).

**El aviso de un ticket es sutil**, como todo en los juegos originales: un "ping" (`ticket_nuevo`)
y nada de texto en pantalla. Lo demás depende de dónde esté el jugador:

- **Con la PC cerrada:** un **sobrecito parpadea tres veces** encima de la pantalla del monitor de
  la oficina (`scenes/office/ticket_envelope.gd`, dibujado por código). Si estabas mirando para
  allá lo ves; si no, te queda el ping.
- **Con la PC abierta:** una **notificación de sistema** dentro del escritorio, en la esquina de
  abajo a la derecha, en VT323: "1 ticket nuevo", y se va en 3 s.

### La baraja de UNO (tarea del escritorio)

Guiño a la vez que un profe nos sacó del salón por andar acomodando una baraja. Llega **como un
ticket más desde la noche 2, una de cada tres noches**
(`Tasks.UNO_ONE_IN`): cuando cae, **le quita el sitio a otra tarea** en vez de sumar una más, así
que la noche sigue pidiendo las mismas. No está en `Tasks.BANK` sino aparte, en `Tasks.UNO_TASK`,
justo para que no se sortee como las demás.

Al llegar su ticket aparece **una baraja junto al teclado**, a la derecha, en la vista central
(`scenes/office/uno_deck_spot.gd`, dibujada por código). Picarla acerca la vista al **encuadre del
escritorio** —la zona `desk`, no la baraja: acercarse a ella sola sería ampliarla dieciocho
veces— y abre la mesa (`scenes/office/uno_desk.gd`). Se sale como de las otras pantallas
acercadas: clic fuera, Esc o clic derecho.

**La tarea:** 24 cartas revueltas (rojo, amarillo, verde y azul, del 0 al 5) que se arrastran a
cuatro montones por color, **en orden del 0 al 5**: el montón del rojo con tres cartas solo acepta
el rojo 3. Soltar una donde no va la **regresa sola** a su sitio, sin castigo. **No hay barra de
espera**: lo que tarda es acomodarlas.

**Las cartas se dibujan por código** (`scripts/ui/uno_card.gd`), al estilo de las de UNO —marco
blanco, óvalo blanco inclinado, número grande al centro y dos chiquitos en las esquinas— pero
**sin el logo ni la palabra de la marca**. El número grande va **del color de la carta sobre el
óvalo** y los chiquitos en **blanco sobre el color**, para que cada uno se lea contra su fondo. Los
colores, las medidas y la repartición están en `data/uno_deck.gd`.

**El riesgo:** mientras la baraja esté **afuera** —y lo sigue estando aunque cierres la pantalla
con Esc, porque los montones se quedan a medias sobre la mesa— cuenta como algo prohibido para
Mamador, igual que la ventana de Claudio. Si llega al cristal y la ve: su irrupción de siempre y la
pantalla de WASTED con "LUDOPATÍA". El botón **"Guardar baraja"** la recoge: las sueltas vuelven a
la caja, **lo ya acomodado se queda** y deja de ser un problema. Ese es el precio de la tarea: para
estar a salvo hay que parar de jugar. Al completarla desaparece del escritorio y **se paga como
cualquier ticket**.

El estado vive en `GameManager.uno_deck` (`scripts/tasks/uno_deck_model.gd`) y no en la pantalla,
porque lo miran tres sitios: la mesa, la tarjeta de la PC y Mamador desde el cristal
(`uno_deck.is_out`, al lado de `is_ai_window_open`). En el panel de pruebas, F1 → Eventos →
**"Dar ticket de UNO"**, **"Dejarla a una carta del final"** y **"Probar LUDOPATÍA"**.

**El contador de tickets ya no está en el HUD de la oficina.** Se consulta dentro de la PC, que es
donde se trabaja: en la **barra de abajo del escritorio**, a la derecha ("TICKETS 1/3"), y en la
**ventana de Tareas**, junto a las pagadas. **Los tickets no vencen**: una vez que llega uno se queda en la lista hasta que el jugador lo termina, y se paga por cada tarea completada. Lo único que corre es el reloj de la noche.

**Pasos con espera:** casi todas las tareas tienen al menos un paso que tarda (copiar un respaldo, reiniciar un servicio, esperar respuestas de ping, propagar una configuración), con barra de progreso. La barra solo avanza mientras la PC está abierta; al bajarla se pausa. Ese es el dilema central: quedarse en la PC o vigilar. La duración de las esperas crece por noche.

Las tareas imitan herramientas reales de un coordinador de sistemas, con diseño original (sin logos ni nombres de marcas): una terminal estilo consola (comandos tipo `ipconfig`, `ping`, reinicio de servicios), un simulador de redes estilo diagrama de topología donde se conectan y configuran equipos, y el patch panel físico en la sala de servidores.

**La PC:** al hacer clic en el monitor, la vista se acerca a la pantalla y aparece un escritorio retro original enmarcado por el bisel del monitor, con íconos: Terminal, Simulador de red, Tareas y Asistente IA.

**Salir de una pantalla acercada** (la PC, el tablero del breaker, la sala de servidores) es
siempre igual y **ya no hay botones**: un **clic izquierdo fuera de la zona activa** regresa a la
oficina, y **Esc** (o clic derecho) sigue sirviendo. La zona activa es la que cada pantalla
declara en su `active_rect()`: el hueco del escritorio en la PC —el bisel es del tamaño de la
ventana, así que lo de "fuera" es su marco de plástico—, la placa del tablero en el breaker y el
rack con su hoja de etiquetado en la sala. Lo único que queda es una pista chiquita y gris abajo
al centro, **"clic fuera o Esc para salir"**, que sale **una sola vez por noche y por pantalla**
(`scripts/ui/exit_hint.gd`, que `night.gd` reinicia en cada noche) y se desvanece sola.

**Ese clic no hace nada en la oficina.** Las tres pantallas se comen el evento, pero la linterna
no se prende por eventos sino preguntando por el botón del mouse cada cuadro, así que al volver a
la oficina **se ignora el botón hasta que se suelte** (`office.set_interactive()` levanta la
bandera `_swallow_click`). Sin eso, el mismo clic con el que sales de la PC te prendía la linterna. La ventana del Asistente IA sigue abierta y trabajando aunque se baje la PC. Usar la PC gasta energía (cuenta como una barra de consumo).

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

| Recorte | Fecha | Se desbloquea | Contenido |
| --- | --- | --- | --- |
| 0 | 12 de agosto | Al empezar la noche 1 | Anuncio: la Coordinación de Sistemas busca alumno para guardia nocturna. "Excelente oportunidad de servicio social." |
| 1 | **16 de diciembre** | Al pasar la noche 1 | Encuentran un termo verde-limón con restos de tequila en la basura, tras la posada de la coordinación. Señalan a Santiago, que lo niega: "mi termo era verde-naranja". |
| 2 | 19 de agosto | Al pasar la noche 2 | Desaparece Santi, alumno de Sistemas, durante el evento de bienvenida; lo vieron por última vez quitándose la botarga detrás del edificio. |
| 3 | 26 de agosto | Al pasar la noche 3 | Escuchan una cajita musical sonando sola en la coordinación vacía, pasada la medianoche. |
| 4 | 2 de septiembre | Al pasar la noche 4 | Hallan velas, sal y un símbolo dibujado en la mesa de la sala de juntas; la universidad habla de una broma. Nadie sabe quién convocó esa junta. |
| 5 | 9 de septiembre | Al pasar la noche 5 | Se filtra la lista de la junta extraordinaria: los ocho nombres aparecen tachados con tinta roja. |
| 6 | 16 de septiembre | Al pasar la noche 6 | La universidad clausura la coordinación. "El responsable sigue sin aparecer." (Gancho para la secuela.) |

**El orden no es el cronológico:** el recorte 1 es de la posada de **diciembre**, de un semestre
antes que todo lo demás, porque es el primer hilo del que se tira. Las fechas y los titulares son
los que traen pintadas las imágenes; los textos de `data/newspapers.gd` solo se usan en la
plantilla de respaldo, si faltara una imagen.

**Se desbloquean por número de noche, no por contenido** (`index_for_cleared_night`), así que
reordenar o reescribir los recortes **no rompe una partida guardada**: quien tenía desbloqueado el
3 sigue teniéndolo, con el contenido que lleve ahora.

El recorte de la renuncia del personal de limpieza ya no existe; su pista se quedó como rumor en
las pantallas de carga (`data/loading_lines.gd`): *"Dicen que dentro de la botarga se oyen voces.
Muchas voces."*

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

**Audio del menú principal:** **una sola pista**, `assets/audio/menu/menu_musica_final.ogg`
(64 s, con el bucle marcado en el import), en bucle por el bus Música **a −4 dB, a la par de los
tics**, que son los efectos que suenan con ella, más un hilo de estática (`estatica_camara`,
−30 dB) encima. Ya trae **el dron de voces mezclado dentro**, así que
no lleva capas aparte: antes eran tres pistas a la vez y dos opciones para comparar (A y B), y
tanto las capas como el selector se quitaron.

Entra con un **fundido de 0.5 s** y **no se reinicia al volver**: al salir del menú se apunta por
dónde iba (`main_menu.gd`, en una variable `static`, que sobrevive al cambio de escena) y al
entrar se retoma desde ahí. Las opciones son una capa de la misma pantalla, así que ni se tocan; de
Extras se vuelve y la música sigue donde se quedó. Los tics van encima, igual que antes.

La música del menú no es esa pista: **«Halloween Atmosphere 2024» de Sascha Ende (ende.app),
CC BY 4.0** es `extras_musica.ogg`, la de Extras y la Custom Night. Su crédito va escrito en
Extras (`Extras.MUSIC_CREDIT`), que es donde se puede leer con calma, y la licencia pide que se
quede ahí.

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
| 0.07 s | Todavía `menu_fondo_0`, pero desgarrado de arriba abajo: las franjas corridas de 10 a 40 px a los lados y los colores separados. **El golpe suena aquí**, con el primer cuadro roto |
| 0.10 s | Entra el cuadro del profe y el desgarro se vuelve una banda que **baja** de arriba abajo |
| 0.15 s | **Congelado**: el profe quieto y sin desgarro, que es lo que asusta |
| 0.05 s | Uno o dos cuadros de estática a 0.5 de opacidad, que tapan la vuelta a `menu_fondo_0` |

**El golpe del tic es uno de diez**, en `assets/audio/menu/`: `tic_boom_1..3`,
`tic_golpe_metal`, `tic_vidrio`, `tic_raspon`, `tic_golpe_eco`,
`tic_whoosh_golpe`, `tic_piano` y `tic_estatica`, todos a −4 dB. `tic_rechinido`
está fuera del sorteo: sonaba a una puerta abriéndose y en el menú no hay
ninguna. Su archivo y su id siguen ahí, y el panel de pruebas lo puede soltar. Se sortea uno en cada tic **sin
repetir ninguno de los dos últimos** (`Sounds.menu_tic()`), así que no se le agarra el ritmo. El
del "ultra" es aparte: `menu_glitch_largo`, **uno de los tres booms** (`Sounds.menu_boom()`) y
`estatica_inquietante` de fondo a −14 dB. Todos se prueban desde F1 → Audio, sueltos o sorteados
como en el menú.

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