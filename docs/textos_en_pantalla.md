# Textos en pantalla durante la noche

Inventario de **todo lo que se lee durante una noche y en las pantallas acercadas**, sacado del
código el 27 de octubre de 2026, con lo que se hizo con cada uno.

La regla de la que sale esta limpieza, en una línea: **el juego no explica sus controles mientras
juegas**. Para eso están la llamada de la noche 1, el recuadro del tutorial (que sale una sola vez)
y la pantalla de Controles de la pausa. Lo que queda en pantalla es lo que el jugador **no puede
ver de otra manera**.

---

## 1. Lo que se quitó

### Pistas de control

| Texto | Dónde salía | Qué pasó |
| --- | --- | --- |
| `[sostén Ctrl o el clic sobre el cristal]` | oficina, al picar la linterna del escritorio | **fuera** (`office.gd`, `FLASHLIGHT_NOTICE`) |
| `Clic y mantén` | cámaras, bajo el botón DAR CUERDA de la CAM 4 | **fuera**; el título del botón se queda |
| `Clic para reproducir` | cámaras, bajo el botón REPRODUCIR AUDIO de la CAM 3 | **fuera**; el título del botón se queda |
| `clic o Escape para cerrar` | el visor de la foto que deja Ureña | **fuera**; se cierra con cualquier clic |

### Letreros de estado

| Texto | Dónde salía | Qué pasó |
| --- | --- | --- |
| `CHAPA ABIERTA` / `CHAPA CERRADA` | oficina, bajo la caja de la chapa | **fuera**. Ahora lo dice **el foco de la chapa**: verde abierta (ya viene en la foto), rojo latiendo cerrada (`scenes/office/lock_light.gd`). Y la cortina abajo se ve sola |
| `Mamador mirando por el cristal` | oficina, sobre el cristal | **fuera**: se le ve, tiene su recorte |
| `Barcosa golpeando la puerta` | oficina, sobre la puerta | **fuera**: la cortina tiembla con cada golpe y él grita (subtítulo) |
| `Mago Eléctrico bajando la escalera` | oficina, sobre la escalera | **fuera**: tiene su recorte |
| `<profe> pegado al cristal` | oficina, con la linterna encendida | **fuera**: tienen sus recortes |
| `[Rochis en el marco]` | oficina, vista derecha | ya se había quitado al llegar su capa |
| `LISTO` | tablero del breaker, renglón de estado | **fuera**. Los dos focos del tablero (ENERGIA y CORTE) ya dicen cómo está. Las dos cuentas atrás (`SIN CORRIENTE 2.4 s`, `ESPERA 7.1 s`) se quedan: son números de un aparato y no hay otra forma de verlos |

**Con esto se fue el mecanismo entero de etiquetas de presencia** (`PRESENCE_ZONES`,
`set_zone_presence()`, `zone_presence()` en los profes). Era el apaño de cuando no existían los
recortes; ahora están todos, así que si a alguien le faltara el suyo no se dibuja nada, que es
mejor que escribir su nombre.

### Avisos que narraban lo que ya se ve

| Texto | Dónde salía | Qué pasó |
| --- | --- | --- |
| `[una figura bajo el arbol]`, `[un coche con las luces prendidas]`, `[una silla bajada mirando a la camara]`, `[una sombra en la luz de la maquina]` | banda de avisos, con los sucesos de las CAM 8 y 9 | **a la consola** (`show_sound`). El suceso ya tiene su propia imagen y su parpadeo |
| `[algo se movió]`, `[ruido lejano]`, `[pasos en el hueco de la escalera]`, `[se prendió un coche solo]`, `[una silla se corrió sola]` y los demás de `AmbientEvents.NOTICES` | banda de avisos, en las cámaras de ambiente | **a la consola**. Son ruidos, y los ruidos no se leen |
| `[clic]` | sala de servidores, al acertar un puerto | **fuera**: ya está el destello y el sonido |
| `puerto incorrecto` | sala de servidores, al fallar | **fuera**: ya está la chispa |
| `[esta noche no tiene guion de llamada]` | banda de avisos | **a la consola**: era un recado para quien programa, no para el jugador |

---

## 2. Lo que se quedó, y por qué

| Texto | Dónde | Por qué |
| --- | --- | --- |
| hora, `NOCHE N`, `ENERGÍA N %` y sus barras | HUD de la oficina | es el HUD |
| `CAM 01 PASILLO NORTE` y los nombres del minimapa | monitor de cámaras | es lo que sale en un monitor |
| `SIN SEÑAL`, `SEÑAL SATURADA` | monitor de cámaras | lo mismo: un monitor sin señal lo dice |
| `DAR CUERDA`, `REPRODUCIR AUDIO` | botones de las CAM 4 y 3 | son botones de verdad, con su medidor |
| `Guardar baraja` | mesa de la baraja | botón de verdad |
| `Silenciar llamada` | teléfono | botón de verdad |
| subtítulos de las llamadas y de las frases de los profes | abajo al centro | son diálogo |
| todo lo de dentro de la PC | escritorio, terminal, simulador, tickets, Claudio | es una computadora: ahí sí hay texto |
| `PELIGRO`, `ALTA TENSION`, `ON`, `OFF`, `ENERGIA`, `CORTE`, `TABLERO PRINCIPAL` | tablero del breaker | está **serigrafiado en el tablero**, como en uno de verdad |
| `SIN CORRIENTE 2.4 s`, `ESPERA 7.1 s` | tablero del breaker | cuenta atrás de un aparato, con su barra |
| `ETIQUETADO CAMARAS` y su tabla | hoja pegada al rack | es una hoja de papel, y es la pista de la tarea |
| `MATERIAL DECOMISADO`, `9 de 24 acomodadas`, `ROJO 3/6` | mesa de la baraja | es el estado de la tarea; no se puede contar de un vistazo |
| `[la linterna no enciende]` | banda de avisos, tras el cortaso | no hay cómo verlo: la linterna simplemente no hace nada |
| `[Armando borró tu progreso]` | banda de avisos | el progreso borrado no se ve desde la oficina |
| `[Ureña se quedó esperando]` | banda de avisos, al colgarle | la ofensa le sube el nivel, y eso no se ve |
| `CAM 03 restablecida` | sala de servidores | desde el rack no se ve que la cámara volvió |
| `DELITO FEDERAL`, `LUDOPATÍA` | pantalla de WASTED | es el cartel, no una explicación |
| recuadro de controles de la noche 1 y la pantalla de Controles de la pausa | tutorial | es justo donde toca explicar |

---

## 3. La pista de salir

`clic fuera o Esc para salir` (`scripts/ui/exit_hint.gd`), en la PC, el tablero del breaker, la
sala de servidores y la mesa de la baraja.

- Antes salía **una vez por noche y por pantalla**; ahora **una sola vez en toda la partida**, por
  pantalla. Queda apuntado en `save.cfg` (`exit_hints_seen`), así que la segunda noche ya no sale.
- Más chica (de 18 a **14 px** medidos a 1080p) y más tenue (gris al **62 %** de opacidad).
- Se desvanece sola a los 1.4 s.

---

## 4. Lo que no es texto pero hacía el mismo trabajo

- **El brillo al pasar el mouse por una zona de clic** (`office_zone.gd`, un blanco al 10 %) **se
  queda**: no es un letrero, es lo que distingue un objeto que se puede tocar de uno que no, y sin
  él la oficina se vuelve un buscaminas.
- **El foco de la chapa** es nuevo: ver **Letreros de estado**, arriba.
