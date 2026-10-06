# Juego de terror en la Coordinación de Sistemas

Juego de supervivencia estilo FNAF 2 hecho en Godot 4.7 con GDScript. El jugador es el guardia nocturno de un campus universitario y sobrevive de 12 AM a 6 AM en la oficina de la Coordinación de Sistemas, vigilando cámaras y defendiéndose de las almas de profesores ficticios.

El documento de diseño completo lo tiene el equipo; este archivo resume lo necesario para programar.

## Entorno

- Godot 4.7.2, renderizador Compatibilidad, proyecto 2D.
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
  assets/art/backgrounds, assets/art/characters, assets/audio
```

## Sistemas principales

- **GameManager (autoload):** noche actual, reloj de 12 a 6 AM (cada hora dura unos 75 s), nombre del jugador, victoria y game over con la causa.
- **PowerManager (autoload):** energía de 0 a 100 %. Gastan: puerta cerrada, linterna y cámaras abiertas. En 0 % todo se apaga. El breaker corta la corriente unos segundos; la chapa de la puerta está en un no-break y sigue funcionando.
- **Grafo de habitaciones:** cada lugar es un id con conexiones. Los profes avanzan por rutas definidas.
- **Animatronic (clase base):** nivel de IA 0 a 20, posición actual, ruta. Cada intervalo tiene una oportunidad de moverse: si `randi_range(1, 20) <= ai_level`, avanza. Cada profe hereda y sobrescribe solo lo que lo hace único.
- **Sistema de cámaras:** 12 cámaras. Cada estado de una cámara es una imagen completa ya renderizada con los profes integrados (como en FNAF), por ejemplo `cam04_desplomada`, `cam04_despertando`, `cam04_vacia`; las pocas combinaciones de varios profes en la misma cámara tienen su propia imagen. Algunos estados tienen una variante rara (el profe mirando de frente, muy cerca de la cámara) que aparece de vez en cuando en lugar de la normal. Cuando un profe entra o sale de la cámara que el jugador está viendo, la imagen se cubre de estática fuerte entre 0.5 y 1 s y al aclararse ya muestra el nuevo estado. Mientras no haya imágenes, se usan etiquetas de texto.
- **Oficina:** vista panorámica que gira con el mouse. Al frente, mampara de cristal hacia la recepción y el pasillo, con la puerta de entrada (chapa magnética) al fondo: de ahí vienen Barcosa, Mamador y Ureña. Al costado, mampara con un marco sin puerta hacia la franja de los cubículos y la escalera al techo: de ahí vienen Rochis, Audel y las Trabas. Linterna hacia el pasillo, breaker, PC.

## Cámaras

| CAM | Lugar | Quién puede aparecer |
| --- | --- | --- |
| 1 | Pasillo norte (mira hacia el balcón) | Barcosa |
| 2 | Pasillo sur (mira hacia la coordinación y los baños) | Barcosa, Mamador, Ureña |
| 3 | Cubículo 2 | Rochis |
| 4 | Cubículo 3 | Botarga del Come Trabas |
| 5 | Escalera al techo | Audel |
| 6 | Techo, pararrayos | Audel |
| 7 | Escalera a planta baja (junto a la coordinación) | Mamador |
| 8 | Estacionamiento | Mamador |
| 9 | Cafetería sur | Mamador |
| 10 | Salón B, sala de servicio | Barcosa |
| 11 | Salón E | Ureña |
| 12 | Baños | Ureña |

Hay dos escaleras. En el extremo sur del pasillo, junto a la coordinación, la escalera interior baja a la planta baja (más salones), desde donde se sale del edificio al estacionamiento y a la cafetería; en el grafo, escalera_pb conecta con pasillo_sur. En el extremo norte, junto al salón B, dos puertas de cristal dan a un balcón con muros de concreto a media altura y una escalera exterior que baja fuera del edificio; por ahora es solo escenografía (se ve al fondo de la CAM 1).

Sin cámara: recepción (se ve desde la oficina), sala de servidores (antes cubículo 1, zona de tareas; id `sala_servidores`) y cuatro salones (puntos ciegos).

## Personajes

- **Barcosa (rol Foxy):** se esconde en la sala de servicio del salón B. Si revisas CAM 10 seguido, se queda; si lo descuidas, se asoma, sale y corre por CAM 1 hasta la puerta. Solo se detiene cerrando la puerta; golpea y habla 5 s, luego regresa. Puerta abierta = jumpscare.
- **Mamador (rol Freddy):** ruta CAM 8 → 9 → 7 → 2 → cristal (sale del estacionamiento y la cafetería, entra al edificio por la planta baja y sube por la escalera junto a la coordinación). Al llegar revisa solo dos cosas: la ventana de la IA abierta en la PC y la puerta cerrada. Si ve alguna, game over "delito federal" (llegan los militares). Si no, dice su frase y se va. Tiene sonido propio de aviso.
- **Ureña (rol Chica):** lento. Ruta CAM 12 → 11 (o salón sin cámara) → 2 → cristal. Se aleja con destellos de linterna.
  - **Llamada de Ureña:** cada noche que Ureña está activo hay cierta probabilidad de que llame al teléfono de la oficina en algún momento entre las 2 y las 4 AM. El teléfono suena unos segundos; si no contestas a tiempo, game over (te mata). Si contestas, no es un examen: es comedia. Ureña llama meloso, saluda al jugador por su nombre y lo felicita por su trabajo mencionando cuántas tareas lleva, y luego suelta tres insinuaciones con doble sentido ofreciéndole "trabajitos extra". Cada una trae tres respuestas barajadas y 6 s para elegir: esquivar con educación (la buena), seguirle el juego o contestar grosero. Ureña reacciona a cada una con una de varias frases al azar. Esquivar no cuesta nada; seguirle el juego baja energía y deja una foto suya en el escritorio; contestar grosero baja energía pero no deja foto; quedarse callado cuenta como seguirle el juego. Nada de esto es game over. Al colgar se despide distinto según si el jugador le siguió el juego alguna vez. En una misma llamada no se repiten insinuaciones. El resto de los profes sigue moviéndose durante la llamada. El banco de insinuaciones, saludos, reacciones y despedidas está en `data/urena_questions.gd`.
- **Rochis (rol Bonnie):** en CAM 3 pasa de sentado a medio levantado a de pie. Mientras se levanta hay que reproducir el audio "es impresionante" hasta que se vuelva a sentar. Reproducirlo cuando ya está sentado lo molesta y acelera su avance. Si llega a estar de pie, entra a la oficina, dice el nombre del jugador y es game over.
- **Audel Electrix (rol Balloon Boy):** vive en el techo (CAM 6), baja por la escalera (CAM 5). Si se baja el breaker mientras está en la escalera, regresa al techo. Si entra, hace un "cortaso": la linterna deja de funcionar y se pierde parte de la energía. No mata directamente.
  - **Descarga del pararrayos:** mientras Audel está en el techo (CAM 6), de vez en cuando provoca una descarga que desconecta algunos patch cords en la sala de servidores. Las cámaras afectadas muestran "SIN SEÑAL" hasta que el jugador entra a la sala de servidores (vista derecha de la oficina) y reconecta cada cable en su puerto según la hoja de etiquetado pegada en el rack (por ejemplo, CAM 03 → PP-07 → SW1 Gi0/7). Mientras está en la sala, no vigila la oficina.
- **Come Trabas (rol Puppet; antes era el profe Santi):** el ritual de Cuéllar encerró el alma de Santi dentro de la botarga de la mascota de la universidad, y con ella a las Trabas, que viven dentro de la botarga. La botarga está sentada en una silla del cubículo 3 (CAM 4) con una llave de cuerda en la espalda; mientras tiene cuerda, toca el himno de la universidad (melodía original), sigue desplomada y las Trabas siguen adormecidas adentro. La cuerda se descarga con el tiempo; se le da cuerda manteniendo un botón en la CAM 4, con un indicador circular. En cero, la botarga levanta la cabeza, se levanta y las Trabas salen de su boca hacia la oficina: game over con causa "Come Trabas". Estados visibles en CAM 4: desplomada, cabeza levantándose, silla vacía.
- **Cuéllar (secreto, rol Golden Freddy):** desde la noche 4, aparición rara en la oficina o en una cámara. Si aparece en la oficina, el jugador tiene 3 s para subir las cámaras o muere.

## Reglas para que las mecánicas no choquen

1. El pasillo es de uno a la vez entre Barcosa y Mamador: si uno lo "reserva", el otro espera.
2. Mamador ignora la linterna, el breaker y las cámaras.
3. Cada amenaza tiene una contramedida distinta; ninguna se resuelve con la de otra.

## Tareas

Cada noche pide de 2 a 5 tareas (minijuegos de 20 a 60 s) para que le paguen al guardia. Casi todas se hacen en la PC; las del tablero de pastillas y el patch panel se hacen en la sala de servidores, dejando la oficina sin vigilar. La IA de la PC las resuelve o da pistas, pero su ventana abierta delata al jugador ante Mamador.

Las tareas imitan herramientas reales de un coordinador de sistemas, con diseño original (sin logos ni nombres de marcas): una terminal estilo consola (comandos tipo `ipconfig`, `ping`, reinicio de servicios), un simulador de redes estilo diagrama de topología donde se conectan y configuran equipos, y el patch panel físico en la sala de servidores.

**La PC:** al hacer clic en el monitor, la vista se acerca a la pantalla y aparece un escritorio retro original enmarcado por el bisel del monitor, con íconos: Terminal, Simulador de red, Tareas y Asistente IA. La ventana del Asistente IA sigue abierta y trabajando aunque se baje la PC. Usar la PC gasta energía (cuenta como una barra de consumo).

## Niveles de IA por noche

| Noche | Barcosa | Mamador | Ureña | Rochis | Audel | Come Trabas | Cuéllar | Tareas |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 0 | 3 | 0 | 0 | 0 | Lenta | 0 | 2 |
| 2 | 3 | 5 | 0 | 0 | 0 | Lenta | 0 | 3 |
| 3 | 5 | 7 | 4 | 3 | 0 | Media | 0 | 3 |
| 4 | 8 | 9 | 7 | 6 | 5 | Media | 1 | 4 |
| 5 | 11 | 12 | 10 | 10 | 9 | Rápida | 2 | 4 |
| 6 | 15 | 16 | 15 | 15 | 14 | Muy rápida | 3 | 5 |

Custom Night: cada nivel de 0 a 20.

## Hitos del prototipo

1. Reloj, energía, oficina placeholder, puerta, pantallas de 6 AM y game over.
2. Grafo de habitaciones, clase Animatronic y sistema de 12 cámaras con etiquetas de texto.
3. Barcosa completo.
4. PC con ventana de IA, una tarea de ejemplo y Mamador.
5. Come Trabas y las Trabas, Ureña con linterna, Rochis con el audio, Audel con el breaker.
6. Configuración por noche, menú, selección de noche, Custom Night y guardado.
7. Resto de tareas, Cuéllar y jumpscares.