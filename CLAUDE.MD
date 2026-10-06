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
- **Sistema de cámaras:** 12 cámaras. Cada vista es un fondo vacío con capas de sprites de los profes presentes (por ahora, etiquetas de texto).
- **Oficina:** vista panorámica que gira con el mouse; puerta de entrada con chapa magnética, linterna hacia el pasillo, breaker, PC.

## Cámaras

| CAM | Lugar | Quién puede aparecer |
| --- | --- | --- |
| 1 | Pasillo norte | Barcosa |
| 2 | Pasillo sur, frente al cristal | Barcosa, Mamador, Ureña |
| 3 | Cubículo 2 | Rochis |
| 4 | Cubículo 3 | Caja musical de Santi |
| 5 | Escalera al techo | Audel |
| 6 | Techo, pararrayos | Audel |
| 7 | Escalera a planta baja | Mamador |
| 8 | Estacionamiento | Mamador |
| 9 | Cafetería sur | Mamador |
| 10 | Salón B, sala de servicio | Barcosa |
| 11 | Salón E | Ureña |
| 12 | Baños | Ureña |

Sin cámara: recepción (se ve desde la oficina), cubículo 1 (cuarto de redes, zona de tareas) y cuatro salones (puntos ciegos).

## Personajes

- **Barcosa (rol Foxy):** se esconde en la sala de servicio del salón B. Si revisas CAM 10 seguido, se queda; si lo descuidas, se asoma, sale y corre por CAM 1 hasta la puerta. Solo se detiene cerrando la puerta; golpea y habla 5 s, luego regresa. Puerta abierta = jumpscare.
- **Mamador (rol Freddy):** ruta CAM 8 → 9 → 7 → 2 → cristal. Al llegar revisa solo dos cosas: la ventana de la IA abierta en la PC y la puerta cerrada. Si ve alguna, game over "delito federal" (llegan los militares). Si no, dice su frase y se va. Tiene sonido propio de aviso.
- **Ureña (rol Chica):** lento. Ruta CAM 12 → 11 (o salón sin cámara) → 2 → cristal. Se aleja con destellos de linterna.
  - **Llamada de Ureña:** cada noche que Ureña está activo hay cierta probabilidad de que llame al teléfono de la oficina en algún momento entre las 2 y las 4 AM. El teléfono suena unos segundos; si no contestas a tiempo, game over (te mata). Si contestas, hace varias preguntas de opción múltiple, cada una con poco tiempo para responder. Cada respuesta mala o sin responder a tiempo: baja energía y aparece (o se queda) una foto de Ureña en la oficina; no es game over. El resto de los profes sigue moviéndose durante la llamada. Las preguntas vienen de un banco de preguntas en `data/urena_questions.gd` (el equipo las escribirá; por ahora usa 3 preguntas de ejemplo).
- **Rochis (rol Bonnie):** en CAM 3 pasa de sentado a medio levantado a de pie. Mientras se levanta hay que reproducir el audio "es impresionante" hasta que se vuelva a sentar. Reproducirlo cuando ya está sentado lo molesta y acelera su avance. Si llega a estar de pie, entra a la oficina, dice el nombre del jugador y es game over.
- **Audel Electrix (rol Balloon Boy):** vive en el techo (CAM 6), baja por la escalera (CAM 5). Si se baja el breaker mientras está en la escalera, regresa al techo. Si entra, hace un "cortaso": la linterna deja de funcionar y se pierde parte de la energía. No mata directamente.
- **Santi (rol Puppet):** su caja musical en CAM 4 se descarga con el tiempo; se le da cuerda manteniendo un botón en esa cámara. En cero, suena su canción y llama a las Trabas, que entran y matan al jugador.
- **Cuéllar (secreto, rol Golden Freddy):** desde la noche 4, aparición rara en la oficina o en una cámara. Si aparece en la oficina, el jugador tiene 3 s para subir las cámaras o muere.

## Reglas para que las mecánicas no choquen

1. El pasillo es de uno a la vez entre Barcosa y Mamador: si uno lo "reserva", el otro espera.
2. Mamador ignora la linterna, el breaker y las cámaras.
3. Cada amenaza tiene una contramedida distinta; ninguna se resuelve con la de otra.

## Tareas

Cada noche pide de 2 a 5 tareas (minijuegos de 20 a 60 s) para que le paguen al guardia. Casi todas se hacen en la PC; las del tablero de pastillas y el patch panel se hacen en el cubículo 1, dejando la oficina sin vigilar. La IA de la PC las resuelve o da pistas, pero su ventana abierta delata al jugador ante Mamador.

## Niveles de IA por noche

| Noche | Barcosa | Mamador | Ureña | Rochis | Audel | Santi | Cuéllar | Tareas |
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
5. Santi y las Trabas, Ureña con linterna, Rochis con el audio, Audel con el breaker.
6. Configuración por noche, menú, selección de noche, Custom Night y guardado.
7. Resto de tareas, Cuéllar y jumpscares.