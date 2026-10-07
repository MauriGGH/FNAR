# Juego de terror en la Coordinación de Sistemas

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
- Todo el arte es placeholder por ahora: rectángulos de color y etiquetas de texto (por ejemplo "CAM 3: Rochis sentado"). No inventes rutas a imágenes que no existen.
- Cambios pequeños y probables: una tarea a la vez. Al terminar, di cómo probarlo y sugiere un mensaje de commit.

## Estructura de carpetas

```
res://
  autoload/        game_manager.gd, power_manager.gd, night_config.gd, audio_manager.gd
  scenes/          main_menu, night, office, camera_system, pc_screen, game_over, win_screen
  scenes/tasks/    una escena por tarea (minijuego)
  scripts/characters/  animatronic.gd (clase base) y un script por profe
  data/            rooms.gd (grafo de habitaciones), nights.gd (niveles por noche)
  scenes/ui/           pantalla de carga y shaders compartidos (estática, scanlines, blanco y negro, bloqueado)
  scripts/ui/          ayudantes: fonts.gd, screen_fx.gd, art_gallery.gd, star_row.gd, menu_backdrop.gd
  assets/art/backgrounds, assets/art/characters, assets/audio
  assets/fonts/        VT323, Special Elite, Oswald y game_theme.tres
```

## Sistemas principales

- **GameManager (autoload):** noche actual, reloj de 12 a 6 AM (cada hora dura unos 75 s), nombre del jugador, victoria y game over con la causa.
- **PowerManager (autoload):** energía de 0 a 100 %. Gastan: puerta cerrada, linterna y cámaras abiertas. En 0 % todo se apaga. El breaker corta la corriente unos segundos; la chapa de la puerta está en un no-break y sigue funcionando.
- **Grafo de habitaciones:** cada lugar es un id con conexiones. Los profes avanzan por rutas definidas.
- **Animatronic (clase base):** nivel de IA 0 a 20, posición actual, ruta. Cada intervalo tiene una oportunidad de moverse: si `randi_range(1, 20) <= ai_level`, avanza. Cada profe hereda y sobrescribe solo lo que lo hace único.
- **Sistema de cámaras:** 13 cámaras. Cada estado de una cámara es una imagen completa ya renderizada con los profes integrados (como en FNAF), por ejemplo `cam04_desplomada`, `cam04_despertando`, `cam04_vacia`; las pocas combinaciones de varios profes en la misma cámara tienen su propia imagen. Algunos estados tienen una variante rara (el profe mirando de frente, muy cerca de la cámara) que aparece de vez en cuando en lugar de la normal. Cuando un profe entra o sale de la cámara que el jugador está viendo, la imagen se cubre de estática fuerte entre 0.5 y 1 s y al aclararse ya muestra el nuevo estado. Mientras no haya imágenes, se usan etiquetas de texto.
- **Oficina:** vista panorámica que gira con el mouse. Al frente, mampara de cristal hacia la recepción y el pasillo, con la puerta de entrada (chapa magnética) al fondo: de ahí vienen Barcosa, Mamador y Ureña. Al costado, mampara con un marco sin puerta hacia la franja de los cubículos y la escalera al techo: de ahí vienen Rochis, el Mago Eléctrico y la botarga del Come Trabas. Linterna hacia el pasillo, breaker, PC.

## Tipografías

Tres familias en `assets/fonts/`, pedidas siempre por `Fonts` (`scripts/ui/fonts.gd`), que las
cachea. El Theme global `assets/fonts/game_theme.tres` pone Oswald en todo; las otras dos van
como override donde toca.

| Fuente | Para qué | Licencia |
| --- | --- | --- |
| VT323 | lo que sale de una pantalla o un aparato: cámaras, PC, relojes, breaker, patch panel | OFL |
| Special Elite | lo escrito a máquina: documentos, periódicos, causa del game over, intro de noche, 6 AM | Apache 2.0 |
| Oswald (variable) | menús, botones y etiquetas | OFL |

## Transiciones y pantallas

- **Intro de noche:** negro con "12:00 AM" y "Noche N" a máquina, con un golpe de estática al
  aparecer y otro al irse. Unos 2.5 s y entra sola a la noche.
- **6 AM:** antes de la pantalla de pago, negro con "5 AM" grande; el 5 sube como un rodillo y
  entra el 6 en 1.5 s, el texto pasa de blanco a dorado, suena el despertador y luego la campana
  de la escuela con aplausos (provisionales por código, en `alarm_sound.gd` y `bell_sound.gd`).
  3 s quieto y recién entonces se ve cuánto te pagan.
- **Game over:** un segundo de estática fuerte y, al aclararse, la cámara vacía del lugar de donde
  salió quien te atrapó, en blanco y negro y con grano; encima "GAME OVER" y la causa a máquina.
  Clic en cualquier lado vuelve al menú, el botón repite la noche. El mapa de profe a cámara está
  en `Extras.ORIGIN_CAMERAS` (la CAM 10 no tiene `vacia`: usa `cam10_salio`).
- **Pantallas de carga:** entre el menú, las noches y los periódicos. Negro con estática leve y una
  frase del lore al azar de `data/loading_lines.gd`. Se entra con `LoadingScreen.go_to(árbol, ruta)`.
- **Fin de noche:** 6 AM → recorte de periódico → las hojas que entregue esa noche → lo siguiente.
  La noche 5 entrega el recibo; la 6, el recibo y la carta de despido, y de ahí al final.

## Documentos

`assets/art/extras/documentos/recibo_noche5.png`, `recibo_noche6.png` y `carta_despido.png`
(1920x1080, la hoja completa). Lo único que dibuja el código encima es el nombre del jugador, con
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

**Oficina por capas:** los profes en las vistas de la oficina son recortes con fondo transparente en `assets/art/office/layers/` (por ejemplo `centro_mamador.png`, `centro_urena.png`, `derecha_rochis.png`), del mismo tamaño que la vista. El código los encima según quién esté presente; los que solo se ven con linterna (Ureña, Juan.exe y Armando en el cristal) se revelan solo dentro del cono de luz.

**Cortina de la puerta:** la caja de la cortina metálica sobre la puerta siempre se ve, aunque la puerta esté abierta. En la CAM 2 viene pintada en las imágenes; en la oficina la dibuja `door_shutter.gd` recortándola de la foto con la puerta cerrada (`DRAW_ROLLER_BOX` en true), porque `oficina_centro` con la puerta abierta no la trae. Lo que está delante de la puerta en la oficina (el mueble de la recepción, los perfiles del cristal) tapa la lámina mientras baja y cuando está cerrada. Al cerrar la puerta, la cortina baja desde esa caja. En la CAM 2, si la puerta está cerrada, el código encima sobre la imagen del estado actual el recorte de `cam02_cortina` en el rectángulo normalizado x 0.729, y 0.223, w 0.1245, h 0.752 (definido en `data/camera_overlays.gd`, que se mide sobre la imagen y no se adivina). Las imágenes `cam02_barcosa-golpeando` ya traen la cortina abajo y no llevan el recorte encima. En la CAM 2, Mamador se pinta a la izquierda de la puerta, frente al cristal del sillón, para no quedar tapado por la cortina.

**Cámaras de ambiente (7, 8, 9):** ninguna ruta de ida pasa por ahí; solo las usan Mamador y Armando al retirarse (ver Rutas de retiro). Además, de vez en cuando muestran sucesos raros sin consecuencias (una sombra, una luz que parpadea), que sirven de atmósfera y de pistas para una secuela.

**Sala de juntas (`sala_juntas`, CAM 13):** el salón del lado oeste frente al salón B, con una mesa ovalada tipo consejo directivo y una pantalla de proyección en un costado. Conecta con pasillo_norte.

Sin cámara: recepción (se ve desde la oficina), sala de servidores (antes cubículo 1, zona de tareas; id `sala_servidores`) y tres salones (puntos ciegos).

## Personajes

- **Barcosa (rol Foxy):** se esconde en la sala de servicio del salón B. Si revisas CAM 10 seguido, se queda; si lo descuidas, se asoma, sale y corre por CAM 1 hasta la puerta. Solo se detiene cerrando la puerta; golpea y habla 5 s, luego regresa. Puerta abierta = jumpscare.
- **Mamador (rol Freddy):** empieza en la sala de juntas. Ruta CAM 13 → 1 → 2 → cristal; reserva el pasillo antes de entrar a pasillo_norte. Al llegar revisa solo dos cosas: la ventana de la IA abierta en la PC y la puerta cerrada. Si ve alguna, game over "delito federal" (llegan los militares). Si no, dice su frase y se va. Tiene sonido propio de aviso.
- **Ureña (rol Chica):** lento. Ruta CAM 12 → 11 (o salón sin cámara) → 2 → cristal. Se aleja con destellos de linterna.
  - **Llamada de Ureña (comedia):** cada noche que Ureña está activo, puede llamar entre las 2 y las 4 AM (60 %; en noches 5 y 6 hasta dos llamadas). La llamada no bloquea el juego: Ureña habla en altavoz y sus textos salen en un recuadro pequeño en una esquina, mientras el jugador sigue usando cámaras, puerta y linterna. Saluda con el nombre del jugador, lo felicita por sus tareas y le hace 1 o 2 insinuaciones (banco en `data/urena_questions.gd`). Cada una tiene 3 respuestas barajadas, elegibles con las teclas 1, 2 y 3 o con clic, y 6 s para elegir: la correcta esquiva con educación (no pasa nada); `sigue_el_juego` quita 5 % de energía y deja la foto en el escritorio; `grosera` quita 5 % sin foto; sin respuesta cuenta como `sigue_el_juego`. Se puede colgar en cualquier momento (o no contestar), pero Ureña se ofende: deja la foto y su nivel sube +5 durante una hora de juego. Ya no hay game over por no contestar. Se despide según cómo le fue. Los demás profes siguen moviéndose.
- **Rochis (rol Bonnie):** en CAM 3 pasa de sentado a medio levantado a de pie. Mientras se levanta hay que reproducir el audio "es impresionante" hasta que se vuelva a sentar. Reproducirlo cuando ya está sentado lo molesta y acelera su avance. Si llega a estar de pie, entra a la oficina, dice el nombre del jugador y es game over.
- **Mago Eléctrico (rol Balloon Boy; antes Audel Electrix):** en pantalla y diálogos se llama "Mago Eléctrico"; en código, ids, estados y archivos se sigue usando `audel` (por ejemplo `cam06_audel-acecho`, `centro_audel.png`) para no romper nada. vive en el techo (CAM 6), baja por la escalera (CAM 5). Si se baja el breaker mientras está en la escalera, regresa al techo. Si entra, hace un "cortaso": la linterna deja de funcionar y se pierde parte de la energía. No mata directamente.
  - **Susto del cortaso (sin muerte):** cuando el Mago entra a la oficina, la pantalla se va a negro, sale `jumpscare_audel_susto` 0.5 s con un chispazo y una risa, y después la linterna queda inservible como ya funciona el cortaso.
  - **Muerte por apagón:** cuando la energía llega a 0 % todo se apaga. Tras 3 a 12 s al azar en oscuridad total aparecen dos chispas azules a lo lejos durante 2 s, acompañadas de la misma canción de cajita musical que toca la botarga, y luego `jumpscare_audel` con la animación de siempre. La causa del game over es "Mago Eléctrico". Pasa en todas las noches, aunque el Mago esté en nivel 0, porque el apagón es suyo. Si dan las 6 AM antes del salto, el jugador sobrevive.
  - **Descarga del pararrayos:** mientras el Mago Eléctrico está en el techo (CAM 6), de vez en cuando provoca una descarga que desconecta algunos patch cords en la sala de servidores. Las cámaras afectadas muestran "SIN SEÑAL" hasta que el jugador entra a la sala de servidores (vista derecha de la oficina) y reconecta cada cable en su puerto según la hoja de etiquetado pegada en el rack (por ejemplo, CAM 03 → PP-07 → SW1 Gi0/7). Mientras está en la sala, no vigila la oficina.
- **Come Trabas (rol Puppet; antes era Santi, un alumno de Sistemas):** un ritual cuyo responsable es un misterio (se reserva para una secuela) encerró el alma de Santi dentro de la botarga de la mascota de la universidad. La botarga está sentada en una silla del cubículo 3 (CAM 4) con una llave de cuerda en la espalda; mientras tiene cuerda, toca una canción de cajita musical sin nombre (`assets/audio/cajita_musical.ogg` cuando exista) y sigue desplomada. La cuerda se descarga con el tiempo; se le da cuerda manteniendo un botón en la CAM 4, con un indicador circular. En cero, la botarga levanta la cabeza, se levanta y va por el jugador: jumpscare de la botarga y game over con causa "Come Trabas". Estados visibles en CAM 4: desplomada, cabeza levantándose, silla vacía. Las Trabas (criaturas que salían de su boca) quedan fuera de esta entrega y se reservan para una segunda; el nombre del personaje se mantiene. De quién es esa canción de cajita musical es un secreto para la segunda entrega: no se menciona en ningún texto del juego, solo se oye.
- **Juan.exe (rol Bonnie clásico):** profe sencillo, sin mecánica especial. Empieza en la sala de juntas; ruta CAM 13 → 1 → 2 → cristal. En el cristal solo se ve con la linterna y se aleja con 4 destellos, igual que Ureña en el pasillo; si no, game over "Juan.exe". No usa la reserva del pasillo.
- **Armando Prompts (rol Chica clásico + Lolbit):** profe que se cree genio, presume títulos inventados y todo lo automatiza con IA. Misma ruta y misma mecánica de linterna que Juan.exe. Además, desde la noche 4, cada vez que el jugador pulsa "Resolver tarea" del asistente Claudio hay probabilidad de que su cara tome toda la pantalla de la PC con una frase al azar; hay que escribir "APÁGATE" en 6 s. Si no, borra el progreso de la tarea actual y quita 5 % de energía. Frases: "HOLA, SOY ARMANDO PROMPTS, INGENIERO EN PROMPTS CERTIFICADO POR MÍ MISMO.", "LE PEDÍ A CLAUDIO QUE HICIERA TU TAREA. TAMBIÉN LE PEDÍ QUE TE CORRIERA.", "ESTE MENSAJE FUE GENERADO CON IA. YO NI LO LEÍ.", "MI TESIS LA HIZO CLAUDIO. MI BODA TAMBIÉN.", "AUTOMATICÉ MIS SENTIMIENTOS. AHORA SUFRO 40% MÁS RÁPIDO.", "¿PENSAR? NAH, ESO ES DE BOOMERS."
- **Claudio (asistente IA de la PC):** parodia de un asistente de IA. Logo propio: una chispa o asterisco naranja terracota con lentes tipo Clark Kent (que evoque la referencia sin calcar ningún logo real). Ventana con fondo crema y acentos naranja. Personalidad exageradamente educada: empieza cada respuesta con "¡Excelente pregunta!" y pide disculpas por todo.

## Jumpscares

Las imágenes están en `assets/art/jumpscares/`: `jumpscare_<id>.png` y `jumpscare_<id>_a.png` para barcosa, urena, rochis, juan, armando, cometrabas y audel, más `audel_susto` y `mamador_militares`.

La animación de cada muerte es la misma: la variante `_a` durante 0.12 s, corte a la imagen final con un zoom de 1.0 a 1.15 en 0.5 s, temblor fuerte, un destello blanco de un cuadro y un grito provisional; después estática y la pantalla de game over con su causa.

Mamador no salta: su game over muestra `mamador_militares` con un zoom lento, luces rojo y azul parpadeando encima y el texto "DELITO FEDERAL" grande al centro, y luego la causa.

La galería de Jumpscares de Extras reproduce estas mismas imágenes.

## Reglas para que las mecánicas no choquen

1. El pasillo es de uno a la vez entre Barcosa y Mamador: si uno lo "reserva", el otro espera.
2. Mamador ignora la linterna, el breaker y las cámaras.
3. Cada amenaza tiene una contramedida distinta; ninguna se resuelve con la de otra.

## Tareas

Cada noche pide de 2 a 5 tareas (minijuegos de 20 a 60 s) para que le paguen al guardia. Casi todas se hacen en la PC; las del tablero de pastillas y el patch panel se hacen en la sala de servidores, dejando la oficina sin vigilar. La IA de la PC las resuelve o da pistas, pero su ventana abierta delata al jugador ante Mamador.

**Tickets durante la noche:** las tareas no están todas desde las 12. Llegan como tickets repartidos en la noche (el primero al inicio y los demás espaciados hasta las 5 AM, con algo de azar), con un aviso sonoro y un contador en la oficina. Cada ticket tiene un plazo (más corto en noches altas); si vence, se pierde 5 % de energía y Mamador sube +3 su nivel durante una hora de juego. Un ticket vencido no cuenta para el pago.

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

Custom Night: cada nivel de 0 a 20.

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

**Extras** (botón del menú principal, se desbloquea al pasar la noche 5, como en los juegos originales):
- **Expedientes:** `assets/art/extras/expediente_<id>.png` (1920x1080). Cada imagen ya es la escena
  completa, la carpeta y el plano, así que no se recorta nada: se ve a pantalla completa y se pasa a
  la siguiente con las flechas de los lados, con clic (derecha avanza, izquierda retrocede) o con las
  teclas de dirección. Debajo, el nombre en pantalla, el rol y una línea. Se desbloquea la ficha de
  un profe la primera vez que te mata o al pasar la noche donde se activa.
- **Periódicos:** los recortes desbloqueados, para releerlos.
- **Jumpscares:** galería para reproducir los jumpscares ya vistos.
- **Custom Night** (si no está ya en el menú principal).
Lo bloqueado se muestra con su propia imagen muy oscurecida y desenfocada (shader
`scenes/ui/locked_art.gdshader`) y un "???" encima.

**Fondo de los menús:** `assets/art/menu/menu_fondo_0..3.png`. Normalmente se ve el 0; cada 4 a 9 s
al azar aparece el 1, el 2 o el 3 durante 0.1 a 0.25 s con un golpe de estática, como el Freddy del
menú de los juegos originales. Encima, líneas de escaneo suaves y un parpadeo leve.

**Estrellas del menú principal:** debajo del título, tres. Una al pasar la noche 5, otra al pasar la
6 y otra al ganar una Custom Night con los ocho profes en 20. Se dibujan por código (`StarRow`) y el
avance se guarda en `save.cfg` (`nights_cleared` y `custom_mastered`, porque `night_reached` se topa
en la última noche y no distingue entre pasar la 5 y pasar la 6).

## Hitos del prototipo

1. Reloj, energía, oficina placeholder, puerta, pantallas de 6 AM y game over.
2. Grafo de habitaciones, clase Animatronic y sistema de 12 cámaras con etiquetas de texto.
3. Barcosa completo.
4. PC con ventana de IA, una tarea de ejemplo y Mamador.
5. Come Trabas (la botarga), Ureña con linterna, Rochis con el audio, Mago Eléctrico con el breaker.
6. Configuración por noche, menú, selección de noche, Custom Night y guardado.
7. Periódicos entre noches y menú de Extras.
8. Resto de tareas y jumpscares.