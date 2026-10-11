# Guion de voces — Five Nights at Rocha's

Todas las líneas habladas que el juego usa hoy o va a usar, para grabarlas.
Por personaje, con el texto exacto, el archivo que el juego espera y cuándo suena.

## Cómo leer este documento

Cada línea lleva una marca de estado:

- **[EN EL JUEGO]** — el id ya existe en `data/sounds.gd`. Dejas el archivo con ese
  nombre exacto en `assets/audio/` y suena solo, sin tocar código.
- **[FALTA ENGANCHAR]** — la línea existe como texto en el juego, pero todavía no
  tiene id de sonido. Grabarla no basta: hay que añadir su entrada al catálogo.
- **[POR ESCRIBIR]** — el momento existe en el diseño pero nadie ha escrito el texto.

Formato: **.ogg**, mono, 44.1 kHz. Las rutas son relativas a `assets/audio/`.

Buses: las voces salen por **Voces**; los gritos y los sonidos de esfuerzo, por
**Efectos** (van mezclados con el golpe del jumpscare, no con el diálogo).

---

## 1. Llamadas de inicio de noche

La voz del guardia anterior, el que cubría el turno antes que tú y está acabando su
servicio social. Tono: amable, cansado, se va por las ramas y evita los temas feos.

Suena a los 3 s de empezar la noche: el teléfono timbra 10 s y, si lo contestas, se
reproduce entera con subtítulos abajo. Se puede silenciar en cualquier momento y no
bloquea el juego. **Si el archivo de una noche no existe, esa noche no hay llamada.**

| Noche | Archivo | Subtítulos | Estado |
| --- | --- | --- | --- |
| 1 | `llamadas/llamada_noche1.ogg` | `data/llamadas/llamada_noche1.txt` | **[EN EL JUEGO]** grabada |
| 2 | `llamadas/llamada_noche2.ogg` | `data/llamadas/llamada_noche2.txt` | **[POR ESCRIBIR]** |
| 3 | `llamadas/llamada_noche3.ogg` | `data/llamadas/llamada_noche3.txt` | **[POR ESCRIBIR]** |
| 4 | `llamadas/llamada_noche4.ogg` | `data/llamadas/llamada_noche4.txt` | **[POR ESCRIBIR]** |
| 5 | `llamadas/llamada_noche5.ogg` | `data/llamadas/llamada_noche5.txt` | **[POR ESCRIBIR]** |
| 6 | `llamadas/llamada_noche6.ogg` | `data/llamadas/llamada_noche6.txt` | **[POR ESCRIBIR]** |

Los subtítulos van en un `.txt` aparte, una línea por frase con el formato
`m:ss|texto`. Las líneas que empiezan con `#` se ignoran. Cada frase se queda en
pantalla hasta que entra la siguiente, así que solo hay que apuntar en qué segundo
empieza cada una.

El tiempo admite **centésimas** (`1:09.45`) y también vale un número de segundos a
secas (`90|...`). Y si recortas o alargas el silencio del principio, **no hace falta
reescribir nada**: pon una línea `@offset=2.5` (segundos, con decimales y con signo)
en cualquier sitio del archivo y se suma a todos los tiempos de golpe.

**El archivo de la llamada es solo voz.** El timbre y el clac de colgar los pone el
juego: `telefono_timbre.ogg` en bucle hasta que contestan, y `telefono_colgar.ogg`
al acabar la llamada o al silenciarla.

### Noche 1 — ya grabada (59 líneas, 5:36 de audio)

Transcripción completa, para doblajes o revisión:

| Entra | Línea |
| --- | --- |
| 0:00 | ¿Bueno? ¿Bueno, bueno? |
| 0:04 | Ah, qué bueno que contestas. |
| 0:08 | Quería grabarte un mensaje para que sepas cómo instalarte la primera noche. |
| 0:15 | Y bueno, yo cubría este turno antes que tú. |
| 0:18 | De hecho, estoy terminando mi última semana de servicio social. |
| 0:21 | Sé que puede ser un poco abrumador, pero no te preocupes, todo saldrá bien. |
| 0:26 | Vamos a centrarnos en que superes tu primera semana, ¿de acuerdo? |
| 0:35 | A ver, primero hay un saludo institucional que estoy obligado a leer. |
| 0:38 | Es algo legal, ¿sabes? |
| 0:44 | "La Coordinación de Sistemas no se hace responsable de daños a la propiedad, a las personas ni a los expedientes académicos. |
| 0:52 | En caso de desaparición, se presentará el reporte correspondiente en un plazo de 72 horas hábiles, |
| 0:59 | o tan pronto como el área se haya limpiado y se hayan reinstalado los sistemas." Bla, bla, bla. |
| 1:09 | Sé que puede sonar mal, pero en realidad no hay nada de qué preocuparse. |
| 1:15 | Los profes de aquí se portan un poco raros por la noche. |
| 1:18 | ¿Pero los culpo? |
| 1:20 | No, realmente no. |
| 1:24 | Si a ti te obligaran a darle la misma clase al mismo idiota todos los días durante meses, |
| 1:31 | probablemente también estarías un poco irritable por la noche, ¿sabes? |
| 1:38 | Así que ten en cuenta que los profes tienden a deambular un poco. |
| 1:42 | Se quedan en una especie de modo libre por la noche. |
| 1:48 | Algo sobre que... no sé, algo se les traba si se quedan apagados mucho tiempo. |
| 1:58 | En fin, no son los mismos desde aquella junta. |
| 2:04 | ¿Ya te contaron lo de la junta? |
| 2:07 | ¿No? |
| 2:08 | Bueno, mejor no te cuento. |
| 2:10 | El punto es que... |
| 2:12 | Olvídalo. |
| 2:16 | Y ahora, respecto a tu seguridad. |
| 2:18 | El único riesgo real para ti como guardia nocturno, si es que hay alguno, |
| 2:24 | es que estos profes, si te ven fuera de horario, probablemente no te reconozcan como alumno. |
| 2:32 | Probablemente te vean como... |
| 2:35 | No sé. No quiero saber. |
| 2:39 | Y como eso va en contra de las reglas de la universidad, probablemente intenten meterte a la junta. |
| 2:50 | Ahora, eso no sería tan malo... |
| 2:52 | Bueno, si las juntas no fueran como son. |
| 2:55 | Así que imagina tener que sentarte en una sala de juntas sin ventanas, con un proyector que no funciona |
| 3:03 | y un café que se acabó hace tres horas. Puede causar un poco de incomodidad. Y la muerte. |
| 3:12 | Je, je. |
| 3:13 | Pero bueno, el primer día debería ser pan comido. |
| 3:21 | Ah, sí, se me olvidaba lo importante. |
| 3:25 | La puerta tiene una cortina metálica que gasta mucha energía. |
| 3:28 | Ciérrala solo cuando haga falta. |
| 3:32 | Las cámaras están en el monitor. Úsalas seguido, pero también gastan. |
| 3:37 | Los tickets de la PC te los pagan. Los que se vencen, no. |
| 3:41 | O sea, tú trabaja, pero no te pases de listo. |
| 3:48 | Ahora sí, los profes. Desde aquella junta de academia no han vuelto a salir del edificio. |
| 3:57 | Si ves al profe Mamador en la cámara, ten cuidado. Solo viene a revisar que todo esté en orden. |
| 4:06 | Cuando llegue al cristal, que no vea la ventana de la asistente abierta ni la puerta cerrada. |
| 4:15 | Se lo toma muy en serio. |
| 4:19 | Demasiado. |
| 4:22 | Al profe Juan, alúmbralo con la linterna cuando esté en el cristal. Varias veces. Se va solo. |
| 4:27 | Ah, y si te llama en la noche para felicitarte por tu proyecto, no le sigas la plática. |
| 4:36 | Empieza muy amable y luego se pone muy cariñoso. ¿Me entiendes? |
| 4:45 | Y la botarga del cubículo 3... solo recuerda: dale cuerda en la cámara 4. Siempre. |
| 4:55 | No preguntes por qué. |
| 5:01 | Bueno, ya te dejo. Te hablo mañana. |
| 5:05 | Solo revisa las cámaras y ahorra energía. |
| 5:12 | Bien, de acuerdo. |
| 5:14 | Buenas noches. |

### Noches 2 a 6 — por escribir

Lo que cada una tendría que cubrir, según el diseño:

| Noche | De qué va |
| --- | --- |
| 2 | Entra Barcosa: hay que vigilar la CAM 10 y cerrar la puerta a tiempo. Primeras dudas sobre la junta. |
| 3 | Entran Ureña y Rochis: la linterna en el cristal y el audio de la CAM 3. Avisa de la llamada de Ureña. |
| 4 | Entra el Mago Eléctrico: el breaker y el patch panel. El guardia anterior ya suena nervioso. |
| 5 | Última noche del guardia anterior. Se despide y deja entender que no va a volver. |
| 6 | Sin llamada, o una grabación vieja de la coordinación. (Decisión pendiente.) |

---

## 2. Ureña — la llamada de media noche

Tono: meloso, confianzudo, baja la voz al final de cada frase. Llama entre las 2 y
las 4 AM. Hoy lo dice todo la **síntesis de voz de Godot**; estas grabaciones la
sustituirían. El jugador no habla: sus respuestas son solo texto en pantalla.

### Saludo  **[FALTA ENGANCHAR]**

**Ya está resuelto:** se graba la versión **sin nombre**. El nombre del jugador sale
solo en el subtítulo, que es lo que se lee.

| Qué | Texto | Archivo |
| --- | --- | --- |
| Lo que se **lee** | «¡Quihubo, [NOMBRE]! Ya llevas [N] tareas... qué aplicadito.» | — (lo escribe el juego) |
| Lo que se **graba** | «¡Quihubo! Ya llevas [N] tareas... qué aplicadito.» | `voces/urena_saludo.ogg` |

> Queda pendiente el `[N]`: el número de tareas tampoco se puede grabar. Lo más
> práctico es grabar «Ya llevas varias tareas» y dejar la cifra solo en el texto,
> igual que con el nombre. Dime si lo cambio en `GREETING_SPOKEN`.

### Insinuaciones  **[FALTA ENGANCHAR]**

Salen 1 o 2 por llamada, sin repetir en la misma noche. 6 s para contestar.

| # | Texto | Archivo |
| --- | --- | --- |
| 1 | «Ando buscando a alguien para unos trabajitos extra... en mi cubículo.» | `voces/urena_linea1.ogg` |
| 2 | «Te quiero convertir en mujer por una noche.» | `voces/urena_linea2.ogg` |
| 3 | «Te subo la calificación... ven a mi oficina a las 3 AM.» | `voces/urena_linea3.ogg` |
| 4 | «¿Me mandas una foto de cuerpo completo? Para el archivo.» | `voces/urena_linea4.ogg` |
| 5 | «Se me puso bien duro... el disco. ¿Me lo formateas?» | `voces/urena_linea5.ogg` |
| 6 | «¿Me haces una conexión punto a punto? Sin switch.» | `voces/urena_linea6.ogg` |
| 7 | «Tengo el cable bien largo... ¿me ayudas a ponchar el conector?» | `voces/urena_linea7.ogg` |

### Reacciones  **[FALTA ENGANCHAR]**

| Texto | Archivo | Cuándo |
| --- | --- | --- |
| «Ay, qué serio...» | `voces/urena_reaccion_esquiva.ogg` | El jugador se zafa con educación |
| «¡Así me gusta!» | `voces/urena_reaccion_sigue.ogg` | El jugador le sigue el juego |
| «Qué grosero eres...» | `voces/urena_reaccion_grosero.ogg` | El jugador le contesta mal |

### Despedidas  **[FALTA ENGANCHAR]**

| Texto | Archivo | Cuándo |
| --- | --- | --- |
| «Ay, qué serio... la oferta sigue en pie.» | `voces/urena_adios_esquivo.ogg` | Esquivó todas |
| «Te dejé un regalito en tu escritorio.» | `voces/urena_adios_foto.ogg` | Le siguió el juego alguna vez |
| «Me rompiste el corazón... y eso se paga.» | `voces/urena_adios_grosero.ogg` | Le contestó mal |
| «¿Me colgaste? ...Ahorita voy para allá.» | `voces/urena_adios_colgado.ogg` | Le colgaron o no contestaron. **Sale por el altavoz de la oficina, después del tono de ocupado** |

---

## 3. Rochis

Tono: profesor mayor, pausado, satisfecho de sí mismo. Cuando se levanta, va en serio.

| Texto | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| «Es impresionante» | `es_impresionante.ogg` | Botón "REPRODUCIR AUDIO" de la CAM 3, para que se vuelva a sentar | **[EN EL JUEGO]** |

> **El nombre del jugador ya no se dice en voz.** No hay nada que grabar: al entrar,
> su nombre sale **escrito en rojo y grande encima del jumpscare**. Si en algún
> momento quieres un gruñido o un «...» antes del salto, ese sí se podría grabar.

| Grito | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Jumpscare de Rochis | `grito.ogg` (común) | Al saltar | **[EN EL JUEGO]**, compartido |
| Jumpscare propio de Rochis | `voces/grito_rochis.ogg` | Al saltar | **[FALTA ENGANCHAR]** |

---

## 4. Barcosa

Tono: enfadado, a gritos, golpeando. Lo que dice no se entiende del todo.

| Qué | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Golpe en la cortina (sin voz) | `golpes_cortina.ogg` | Uno por segundo, los 5 s que aporrea la puerta | **[EN EL JUEGO]** |
| Grito del jumpscare | `voces/grito_barcosa.ogg` | Si te pilla con la puerta abierta | **[FALTA ENGANCHAR]** |

### Lo que dice en la puerta  **[EN EL JUEGO]**

Al empezar a aporrear suelta **una de las tres, al azar**. Al rendirse, siempre la
misma. Mientras no estén grabadas las dice la voz sintética y el texto sale igual
como subtítulo pequeño.

| Texto | Archivo | Cuándo |
| --- | --- | --- |
| «¿Quién cerró? Tengo clase en este salón.» | `voces/barcosa_puerta_1.ogg` | Empieza a golpear |
| «Abra, joven. Nada más paso lista y me voy.» | `voces/barcosa_puerta_2.ogg` | Empieza a golpear |
| «Diez minutos. Le estoy pidiendo diez minutos.» | `voces/barcosa_puerta_3.ogg` | Empieza a golpear |
| «Bueno, ya. Quedan todos con falta.» | `voces/barcosa_se_va.ogg` | Se rinde y vuelve al salón B |

---

## 5. Mamador

Tono: autoridad administrativa, seco, sin levantar la voz. Da más miedo por lo
tranquilo que está.

### Cuando no encuentra nada  **[EN EL JUEGO]**

Una de las tres, al azar, al terminar de inspeccionar desde el cristal.

| Texto | Archivo |
| --- | --- |
| «Sin novedad. Me retiro.» | `voces/mamador_ok_1.ogg` |
| «Nada de inteligencia artificial. Así me gusta.» | `voces/mamador_ok_2.ogg` |
| «Todo en orden. Sigan así.» | `voces/mamador_ok_3.ogg` |

### El resto

| Texto | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| «¡Delito federal!» | `voces/mamador_delito.ogg` | Llega al cristal y te ve la ventana de Claudio abierta o la puerta cerrada. Es el game over de los militares | **[FALTA ENGANCHAR]** |
| Pasos lentos y llavero | `voces/mamador_aviso.ogg` | Su sonido propio de aviso, mientras baja por el pasillo | **[FALTA ENGANCHAR]** |

> Mamador **no tiene jumpscare**: su game over es la pantalla de los militares. No
> hace falta grito, pero sí sirve ambiente de sirenas y radio de policía.

---

## 6. Mago Eléctrico

Tono: risa corta y burlona, nada de frases. Es el que te fastidia, no el que te mata.

| Qué | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Risa del cortaso | `voces/mago_risa.ogg` | Entra a la oficina, chispazo y pantalla en negro 0.5 s. Después la linterna queda muerta | **[FALTA ENGANCHAR]** |
| Grito del jumpscare del apagón | `voces/grito_mago.ogg` | Al final de la secuencia del apagón, tras los tres pasos | **[FALTA ENGANCHAR]** |

---

## 7. Juan.exe

Tono: plano, como si leyera. No tiene mecánica propia y hoy no dice nada.

| Qué | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Respiración en el cristal | `voces/juan_respiracion.ogg` | Llega al cristal; hoy solo sale el aviso «[respiración en el cristal]» | **[FALTA ENGANCHAR]** |
| Grito del jumpscare | `voces/grito_juan.ogg` | Si no lo ahuyentas con la linterna a tiempo | **[FALTA ENGANCHAR]** |

---

## 8. Armando Prompts

Tono: locutor de curso de internet, seguridad absoluta, cero autocrítica.

Las seis frases ya salen escritas a pantalla completa en la PC desde la noche 4.
Grabadas darían mucho más. **[FALTA ENGANCHAR]**

| # | Texto | Archivo |
| --- | --- | --- |

| Otros | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Grito del jumpscare | `voces/grito_armando.ogg` | Si no lo ahuyentas en el cristal | **[FALTA ENGANCHAR]** |

---

## 9. Santi / la botarga del Come Trabas

Santi era un alumno de Sistemas. Un ritual encerró su alma dentro de la botarga de
la mascota. Tono: voz de chavo joven, ahogada, como desde dentro de un disfraz.

| Qué | Archivo | Cuándo | Estado |
| --- | --- | --- | --- |
| Canción de cajita musical | `cajita_musical.ogg` | En bucle mientras la botarga tenga cuerda. **No es voz**, pero es su sonido | **[EN EL JUEGO]** |
| Respiración o quejido al levantar la cabeza | `voces/santi_despierta.ogg` | La cuerda llega a cero y la botarga levanta la cabeza en la CAM 4 | **[POR ESCRIBIR]** |
| Grito del jumpscare | `voces/grito_cometrabas.ogg` | Cuando la botarga llega a la oficina | **[FALTA ENGANCHAR]** |
| «Voces, muchas voces» dentro de la botarga | `voces/santi_voces.ogg` | Pista de las Trabas, del recorte de la noche 4. Sin momento asignado todavía | **[POR ESCRIBIR]** |

> De quién es la canción de la cajita musical se guarda para la segunda entrega. No
> se menciona en ningún texto del juego, solo se oye.

---

## 10. Gritos y sonidos vocales, juntos

Hoy **todos los jumpscares comparten un mismo grito provisional** generado por
código. Lo mínimo imprescindible es grabar uno bueno; lo ideal, uno por personaje.

| Personaje | Archivo | Estado |
| --- | --- | --- |
| Común a todos (lo que se usa hoy) | `grito.ogg` | **[EN EL JUEGO]** |
| Barcosa | `voces/grito_barcosa.ogg` | **[FALTA ENGANCHAR]** |
| Ureña | `voces/grito_urena.ogg` | **[FALTA ENGANCHAR]** |
| Rochis | `voces/grito_rochis.ogg` | **[FALTA ENGANCHAR]** |
| Juan.exe | `voces/grito_juan.ogg` | **[FALTA ENGANCHAR]** |
| Armando Prompts | `voces/grito_armando.ogg` | **[FALTA ENGANCHAR]** |
| Come Trabas (botarga) | `voces/grito_cometrabas.ogg` | **[FALTA ENGANCHAR]** |
| Mago Eléctrico | `voces/grito_mago.ogg` | **[FALTA ENGANCHAR]** |
| Mamador | — | No salta: su game over es la pantalla de los militares |

---

## 11. Lo que no es voz pero se graba igual

Para que la lista de encargo quede completa, los sonidos no vocales que el juego ya
espera están en `data/sounds.gd`. Los que más se notan:

| id | Archivo | Qué es |
| --- | --- | --- |
| `ambiente_oficina` | `ambiente_oficina.ogg` | Zumbido de lámparas y ventilador, en bucle |
| `ambiente_pasillo` | `ambiente_pasillo.ogg` | Viento lejano y crujidos, en bucle |
| `telefono_timbre` | `telefono_timbre.ogg` | Timbre de teléfono de oficina |
| `puerta_cortina` | `puerta_cortina.ogg` | Cortina metálica al bajar y subir |
| `golpes_cortina` | `golpes_cortina.ogg` | Barcosa aporreando |
| `pasos_acercandose` | `pasos_acercandose.ogg` | Los tres pasos del apagón |

La lista completa, con buses y volúmenes, está en `CLAUDE.md`, sección **Audio**.

