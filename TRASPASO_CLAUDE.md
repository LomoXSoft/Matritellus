# Traspaso a Claude

Este documento recoge el trabajo hecho con Codex en `X:\MatritellusGPT` mientras la sesión de Claude está en pausa. El desarrollo durante esta etapa se hará exclusivamente en esta carpeta.

## Punto de partida

- El commit que apuntaba `HEAD` al abrir el registro era `92d852e` (`Matritellus 0.0.17`). Los trabajos anteriores y las tareas pendientes están descritos en [PROJECT_STATE.md](PROJECT_STATE.md). La organización del repo y las instrucciones para jugar y publicar están en [README.md](README.md).
- Para incorporar cambios al retomar el trabajo, revisar cada entrada junto con `git status --short` y `git diff` en esta carpeta. Las entradas indicarán si los cambios tienen commit y, cuando corresponda, el resultado de las pruebas.

## Registro

### 18 de noviembre de 2026 — Apertura del traspaso

- **Hecho.** Se estableció `X:\MatritellusGPT` como carpeta exclusiva de trabajo y se abrió este registro.
- **Archivos.** `TRASPASO_CLAUDE.md`.
- **Verificación.** Se comprobó la estructura del repositorio y se leyó su documentación de trabajo. Esta entrada es de documentación y no requiere ejecutar el juego.
- La primera mejora jugable se recoge en la entrada de boxeo siguiente.

### Boxeo de Fonsi

18 y 19 de noviembre de 2026. Implementado en `X:\MatritellusGPT` sobre el combate de la versión 0.0.17, con Godot `4.7.2.stable.official.ed1daf0bf`. El [dossier descomprimido](referencias/Boxeo-Wii-Sports-Matritellus/README.md) incluye sus [referencias](referencias/Boxeo-Wii-Sports-Matritellus/REFERENCIAS.md) y seis láminas. El ring, los personajes, el papel del marcador, los sonidos sintetizados y la cámara son los de Matritellus.

#### Dónde jugar y cómo se controla

Entra en el **V.I.P. de la calle de Santa Ana, 14**, habla con Fonsi en el mostrador y elige combatir. Puedes hacerlo durante el encargo del móvil de Josefa y como reto libre tras resolverlo. Cuando ganas y se desbloquea `box`, también puedes entrar desde **Pausa → Agenda → Minijuegos → Combate de boxeo**.

| Acción | Teclado y ratón por defecto | Mando Xbox / PlayStation | Táctil |
| --- | --- | --- | --- |
| Golpear con la derecha | Clic izquierdo, E o Espacio | X / □. También A / ✕ y B / ○ | Derecha |
| Golpear con la izquierda | Clic derecho o F | Y / △ | Izquierda |
| Golpear o cubrirse al cuerpo | Mantener Ctrl. Al soltar, vuelve a alto | Mantener LB / L1 | Tocar Alto ↕ o Cuerpo ↕ para alternar |
| Guardia | Mantener S o flecha abajo | Mantener el stick izquierdo hacia abajo | Mantener Guardia |
| Esquivar | A a la izquierda, D a la derecha | Stick izquierdo hacia un lado | Arrastrar hacia un lado el stick que aparece al tocar la mitad izquierda |

El stick necesita volver al centro para repetir. La altura del golpe queda fijada al aceptar la orden. El selector táctil vuelve a alto al empezar otro asalto o combate. F y Ctrl son reasignables desde los ajustes. Y también sirve para el claxon en conducción, donde la acción de boxeo está inactiva. Los alias de la mano derecha siguen los enlaces de interacción y freno de mano.

#### Mecánica y decisiones

- **Simulación.** `game._physics_process` llama a `boxing.tick` en cada paso de física. Los eventos se recogen antes del HUD y se consumen una vez por paso. El mismo lector de flancos usa las intensidades del stick de mando y del stick táctil. La IA usa su propio generador, cuya semilla se puede fijar con `--selftest`.
- **Entrada simultánea.** Primero se lee la altura. Entre órdenes válidas se elige esquiva antes que golpe, izquierda antes que derecha para esquivar, y mano primaria antes que secundaria para atacar. Una pulsación rechazada se descarta. Un impacto que aturde impide iniciar otra orden, pero el golpe ya aceptado llega a contacto mientras siga el asalto.
- **Tiempos.** Fonsi avisa durante 0,50 s o 0,80 s si carga el fuerte. Tu golpe tarda 0,10 s en llegar, tiene 0,05 s de contacto y 0,20 s de recuperación. La esquiva protege desde los 0,05 s incluidos hasta los 0,25 s excluidos. Puedes golpear durante los 0,25 s que tardas en enderezarte. El aviso distingue altura por postura y texto. Las ayudas cambian con el dispositivo y el idioma.
- **Daño.** Cada mano quita 6 de vida, o 1 si encuentra la guardia a esa altura. Fonsi quita 16 o 28 y su golpe hace un 20 % del daño si te cubres a la altura correcta. Si falla, queda abierto durante 0,95 s. El primer contacto limpio antes de que venza ese plazo quita 12 y consume la contra. Si Fonsi bloquea, el bonus sigue disponible. Las señales de aire, guantes, golpe limpio y contra se reproducen a velocidad normal.
- **Asaltos.** Gana el primero en llevarse dos. Cada asalto empieza a 100 de vida y 60 s. Un derribo lo cierra. La campana tiene prioridad sobre los contactos de ese paso y el empate a vida favorece al jugador. Dos golpes que llegan juntos se calculan con el mismo estado previo, se aplican ambos y un doble derribo concede un solo asalto al jugador. El descanso dura 3,4 s. El resultado final permanece 2,4 s antes del único callback.
- **Progreso.** `box_fights` cuenta todos los combates y `box_wins` solo victorias. `box_best` conserva el máximo de `100 × asaltos ganados − 40 × asaltos perdidos + vida restante si se gana`, con mínimo cero. `box_pc` guarda el día de la primera victoria para el límite de un Punto Cívico diario cuando ese sistema ya está activo. El primer triunfo del reto libre guarda el desbloqueo en el mismo cierre. En la misión y el reto libre se vuelve al mostrador. La Agenda devuelve al lugar de partida.

#### Archivos y comprobaciones

| Archivos | Trabajo realizado |
| --- | --- |
| `godot/scripts/boxing.gd` y `chara.gd` | Fases, contacto simultáneo, IA, posiciones de manos, guantes y reacciones, sonido de los cuatro resultados y limpieza al salir. |
| `godot/scripts/controls.gd` y `touch.gd` | Enlaces, glifos, compatibilidad de teclas reasignadas y cuatro botones táctiles. La guardia táctil tiene su propia acción para que el stick pueda soltar la dirección atrás sin soltar el botón de guardia. |
| `godot/scripts/game.gd`, `hud.gd` y `loc.gd` | Entrada y salida del ring, guardado del reto libre, ayudas por dispositivo, marcador y avisos en castellano e inglés. El objetivo de la calle y el mapa se recogen durante el combate. |
| `godot/scripts/selftest.gd` | Se migraron las antiguas preparaciones del boxeo y se añadió el filtro `boxeo`. Se movió un comentario preexistente de la prueba de muros que ocultaba el paréntesis de cierre e impedía cargar cualquier selftest. |
| `PROJECT_STATE.md`, este registro y `referencias/Boxeo-Wii-Sports-Matritellus/` | Resumen de la entrega y dossier recibido. |

La [muestra de guardado 0.0.17](tools/fixtures/boxeo_0_0_17.json) se creó con el código de combate anterior, ganando al Fonsi en el V.I.P. Contiene una victoria en un combate, récord de 300 y el desbloqueo de `box`. Se verificó que los 410 bytes coinciden con el archivo escrito por la versión antigua. El filtro con `guardado-anterior` carga una copia de esa muestra en una ranura de prueba, juega otra vez y verifica el historial.

La primera suite completa detectó la palabra «para» en la ayuda táctil. Se adaptó el texto a las normas manchegas de `guion/palabros.md`. El filtro de vocabulario de la siguiente ejecución aceptó toda la localización.

Los comandos corresponden a la raíz de esta copia. `tools/run_tests.py` usa el ejecutable del proyecto y añade `--headless --path godot --fixed-fps 60 -- --selftest` en las pruebas sin ventana.

| Ejecución | Resultado |
| --- | --- |
| Guardado previo con el combate 0.0.17 | [Una comprobación correcta](logs/selftest_boxing-baseline_20261118_204312.log). El preparador temporal escribió el original en `logs/` y la copia reproducible está en `tools/fixtures/`. |
| `python tools/run_tests.py boxeo guardado-anterior --headless` | [86 comprobaciones correctas](logs/selftest_boxeo_guardado-anterior_20261119_032920.log). Incluye las dos manos y alturas, Ctrl + F pulsados y soltados entre pasos de física, Ctrl + S ante un golpe al cuerpo, defensa cruzada, límites de esquiva y contra, botones y ejes del mando, multitáctil, campana, doble derribo en el asalto decisivo, datos guardados y las tres entradas al ring. |
| `python tools/run_tests.py boxeo shots --window` | [Tres comprobaciones correctas](logs/selftest_boxeo_shots_20261118_210321.log). Vistas renderizadas del [aviso alto en 16:9](godot/shots/fonsi_aviso_alto.png), la [guardia al cuerpo con ayudas táctiles en inglés en 20:9](godot/shots/fonsi_tactil_cuerpo.png) y la [ventana de contra](godot/shots/fonsi_esquiva_contra.png). |
| `python tools/run_tests.py boxeo manual --window` | Tres combates interactivos en Windows con teclado y ratón, todos 0–2. Se verificaron el mostrador, los avisos de altura, el marcador, el derribo, el siguiente asalto y el cierre. El [registro de la última partida](logs/selftest_boxeo_manual_20261119_032357.log) recoge dos derechas, una izquierda y tres impactos. La guardia, los golpes al cuerpo y el tiempo de la esquiva se comprobaron en las pruebas automatizadas. Tras la primera partida se ajustaron la visibilidad del objetivo y el número de voces simultáneas del público. |
| `python tools/run_tests.py --headless` | [855 comprobaciones correctas, cero fallos y cero errores de script](logs/selftest_full_20261119_031303.log), incluida la historia completa de Josefa y la revancha desde la Agenda. |

La suite completa sigue emitiendo diagnósticos de Godot sobre `brick_red` al cargar fachadas, un material nulo en el renderizador headless y recursos al cerrar. Los tres ya figuraban en el [registro del 17 de noviembre](logs/selftest_full_20261117_231129.log).

**Dispositivos pendientes.** Godot informó de cero mandos conectados y de pantalla sin capacidad táctil. Windows tenía perfiles Bluetooth de Xbox y DualSense y enumeró cero mandos activos en `Windows.Gaming.Input`. El filtro ejercitó botones y ejes de mando mediante `InputMap` y la ruta de `InputEventScreenTouch` y `InputEventScreenDrag`, incluidos un dedo en la guardia y otro en el stick. Quedan las pruebas en mando físico, dispositivo Android multitáctil y Linux o Steam Deck. Queda pendiente la escucha de los efectos de `Sfx` en altavoces o auriculares.

La base ya tenía ediciones del mundo, misiones y creador. La entrega de boxeo está en el árbol de trabajo de `main`, pendiente de commit y publicación.

### Riña del jamón de Henry

19 de noviembre de 2026, en `X:\MatritellusGPT`, con Godot `4.7.2.stable.official.ed1daf0bf`. La referencia de ritmo se tomó del [dossier](referencias/Bate-Dead-Rising-Matritellus/README.md) y sus cuatro láminas. Los seis archivos coinciden byte por byte con el ZIP recibido. El enlace al vídeo no se pudo reproducir directamente en esta sesión.

**Dónde y cómo jugar.** Acércate a La Cocina de Henry, en la calle de la Palma, con el primer encargo del menú de Josefa. Después, el grupo vuelve los jueves de 8 a 21 si se cumplen las condiciones del evento. En **Pausa → Agenda → Minijuegos → Recoger el jamón asao** puedes repetir para mejorar el récord. El menú devuelve al punto de origen. Se conservan los 60 segundos, la recompensa diaria, el encargo y la entrega.

| Gesto sobre Golpe | Contacto | Cuándo puedes repetir | Alcance |
| --- | --- | --- | --- |
| Soltar antes de 0,25 s | 0,40 s desde la pulsación | 0,70 s desde la pulsación | Hasta dos vecinos |
| Mantener al menos 0,25 s y soltar al ver «¡Bate listo!» | 0,22 s después de soltar | 0,50 s después del contacto | Hasta tres vecinos |

Se usa clic izquierdo, X en Xbox, cuadrado en PlayStation o el botón táctil **Golpe**. Se puede girar la cámara con un segundo dedo al cargar. La altura del sonido y la pose distinguen carga lista, golpe al aire e impacto. Las ayudas están en español e inglés. El frente es el del avatar en el instante del contacto. El filtro conserva el alcance estricto de 1,9 m, el umbral frontal de 0,25 y la excepción a menos de 0,6 m. Se ordena por distancia y se aplica una sola vez el daño de 25 por vecino. Cada impacto ordinario suma 5 puntos y uno que derriba suma 10 en total.

**Implementación.** `motin.gd` recibe en la riña los dos flancos de la acción existente `punch`. El reloj de física de la riña gobierna la preparación, el contacto y la recuperación. La pausa y el mapa congelan el reloj y soltar mientras están abiertos descarta la carga. La pérdida de foco, el cambio de dispositivo y la desconexión del mando también sueltan la preparación. El reloj agotado y una caída anterior al contacto cancelan el ataque. La revancha comienza con el bate en reposo. `chara.gd` comparte las poses base del bate con exploración. `motin.gd` presenta de perfil el bate de la riña y da más amplitud al cargado. El vecino que recibe el impacto se inclina y vuelve a erguirse durante sus 0,35 s de aturdimiento.

**Encuadre.** La primera comprobación dejó la lente detrás de la puerta y otra vista mostró el gorro de Henry por delante del avatar. En `game.gd` se corrigió la cámara sobre el hombro del bate. La posición buscada pasó de 3,4 a 3,8 m por detrás, de 0,9 a 1,35 m de desplazamiento lateral hacia la mano y de 2,15 a 2,55 m de altura. Se usa la colisión de la calle para acortar el recorrido antes del muro, con 0,7 m de margen, y se ocultan temporalmente las figuras entre la lente y el jugador. La pose cargada amplía el recorrido lateral de la mano un 22 %. Se mantuvieron los tiempos de juego y los límites de blancos del dossier.

**Archivos de esta entrega.** `godot/scripts/motin.gd`, `game.gd`, `chara.gd`, `touch.gd`, `loc.gd` y `selftest.gd`, además de [las reglas del encargo](guion/misiones_y_puntos_civicos.md), `PROJECT_STATE.md`, este registro y el dossier en `referencias/Bate-Dead-Rising-Matritellus/`. La acción de `controls.gd` ya tenía los enlaces necesarios.

**Comprobación interactiva.** Jugué los 60 segundos en la ventana de Windows. Un clic conectó con dos vecinos, sumó 10 puntos y el juego volvió con Henry al cerrar la ronda. El [registro manual](logs/selftest_motin_manual_20261119_100926.log) recoge los dos impactos y cero derribos. El barrido cargado se comprobó con entradas controladas y capturas. Godot detectó cero mandos y una pantalla sin capacidad táctil. Se probaron eventos de mando, pantalla táctil y arrastre por la ruta de entrada real del juego. Quedan pendientes el tacto de un mando físico, el multitáctil en móvil y la escucha directa de los efectos.

**Pruebas reproducibles.** Desde la raíz de esta copia:

| Comando | Resultado |
| --- | --- |
| `python tools/run_tests.py motin --headless` | [64 correctas](logs/selftest_motin_20261119_101925.log). Incluye toque, umbral exacto, aire, carga, selección y puntuación, cancelación, pausa, mapa, revancha, encargo de Josefa, jueves y Agenda. |
| `python tools/run_tests.py motin shots --window` | [65 correctas](logs/selftest_motin_shots_20261119_101708.log), incluida la lectura del aviso de carga en inglés. |
| `python tools/run_tests.py motin manual --window` | [18 correctas y ronda interactiva completada](logs/selftest_motin_manual_20261119_100926.log). |
| `python tools/run_tests.py bate --window` | [2 correctas](logs/selftest_bate_20261119_102034.log). En exploración, la animación empieza al pulsar, el vecino cae y el avatar guarda el bate. |
| `python tools/run_tests.py palabros --headless` | [3 correctas](logs/selftest_palabros_20261119_102134.log). |
| `python tools/run_tests.py boxeo guardado-anterior --headless` | [86 correctas](logs/selftest_boxeo_guardado-anterior_20261119_102213.log). Cubre las entradas táctiles compartidas y el estado anterior del juego. |

Las seis ejecuciones finales terminaron sin fallos de comprobación ni errores de script. Durante las pruebas siguió apareciendo el diagnóstico preexistente de fachadas sobre `brick_red`. Se ejecutaron los filtros afectados. La suite integral de 855 comprobaciones de la entrada anterior corresponde al boxeo y se ejecutó antes de esta entrega.

**Imágenes revisadas.** [Carga lista en inglés](godot/shots/motin_carga_lista.png), [contacto del barrido](godot/shots/motin_contacto_cargado.png), [giro entre vecinos](godot/shots/motin_giro_grupo.png), [cámara junto a la fachada](godot/shots/motin_fachada.png) y [derribo con el bate de exploración](godot/shots/bate_5_suelo.png). Las barras de vida se ocultan con el vecino que tapa la lente y también cuando quedan a menos de 1,5 m de ella. Trabajo en `main`, pendiente de commit y publicación.

### RALLY 9 en Galaxy Recress

19 de noviembre de 2026. Se incorporó el [dossier de carrera](referencias/Burnout-3-Rally-9/README.md) a esta copia de Matritellus. Se consultaron su recorrido comentado, las láminas y la animación de los dos encuadres. La reproducción directa del vídeo de BR4GG4 no estuvo disponible desde la sesión. El arte, los coches, la música y los efectos del juego proceden de Matritellus.

**Acceso.** Después de la reapertura del Galaxy Recress, entra en su horario habitual, de 15:00 a 02:00. Acércate al asiento rojo junto a la entrada y usa la interacción habitual. El punto de interacción se calcula con la misma transformación que coloca el asiento. Las máquinas contiguas siguen ofreciendo Tokken. La pausa permite volver al salón. La meta ofrece volver al asiento o empezar otra carrera.

**Circuito.** El Tunero compite contra tres rivales en dos vueltas de unos 503 m al Circuito del Azafrán. Cada vuelta exige ocho puertas consecutivas cruzadas hacia delante, dentro de la anchura de pista. Las rectas tienen 132 m y las curvas, 38 m de radio. El puesto se decide por orden de meta, con interpolación del instante de cruce dentro del paso de física. Antes de meta se compara el último control válido y el avance hasta el siguiente. La meta tiene prioridad sobre el accidente que coincida con ella.

| Acción | Teclado por defecto | Mando Xbox / PlayStation | Táctil |
| --- | --- | --- | --- |
| Jugar / confirmar | E o Intro en el menú de resultados | A / ✕ | Botón de interacción o tocar la fila de resultado |
| Acelerar / frenar | W / S | RT / LT o R2 / L2 | Gas / Freno |
| Dirección y aftertouch | A / D | Stick izquierdo | Stick flotante a la izquierda |
| Derrape | Espacio y dirección | B / ○ y dirección | Derrape y stick |
| Nitro dosificable | Mantener Mayús mientras aceleras | Mantener RB / R1 y acelerador | Mantener Nitro también da gas |
| Pausa | Esc o P | Start / Options | Ⅱ |

La configuración de teclas y los glifos se toman de Controls. En la pausa se pueden cambiar cámara continua, efectos reducidos y vibración. La escala y el antialiasing de la vista usan los ajustes gráficos activos. Al perder el foco se pausa y se liberan las acciones.

**Nitro y accidentes.** Salida con 50/100. Las cuatro capacidades son 100, 150, 225 y 300. El impulso gasta 32 unidades por segundo. Una esquiva sin roce da 15 una vez y un derrape real con apoyo y velocidad lateral da 8 por segundo. Los puntos de maniobra se llevan aparte. Un contacto relevante abre 1,2 s de atribución con ese rival. Un derribo rellena el nuevo nivel. En un accidente propio se puede dirigir lateralmente el coche durante 1 s. Un derribo en ese margen preserva el nivel y rellena el depósito. En caso contrario se pierde un nivel y queda como máximo el 25 % de la nueva capacidad. Se reaparece en el último tramo válido con 0,8 s de protección. El plano del rival dura 0,55 s y su enlace con la vista trasera, 0,20 s. Ambos congelan la carrera y su reloj mientras se anima una copia del coche. Antes de una curva se mantiene la vista trasera.

**Ajustes después de jugar.** La primera carrera de prueba terminó en 43,11 s con el rival más avanzado en la puerta 14 de 16. Se subieron las velocidades objetivo de los tres rivales de 18,2 / 19,5 / 20,9 a 20 / 22,4 / 23,6 m/s. En la siguiente llegada el rival más próximo estaba en la puerta 15. En la primera imagen del derribo otro coche tapaba al accidentado. Ahora el plano se toma desde su lado exterior, se muestra su nombre y se incluyen las ruedas en la copia visual. Los puntos quedaron sobre fondo oscuro para que se lean sobre el campo claro.

**Código.** `rally.gd` administra el intento y su mundo 3D aislado. La física del pueblo se detiene durante la partida. `rally_pista.gd` crea el trazado y calcula posiciones, `rally_hud.gd` dibuja el marcador y `rally_pruebas.gd` conduce y comprueba la carrera. `car.gd` usa el empuje de turbo habitual con un depósito gobernado por la recreativa. Para el derrape se consulta la señal de `derrape.gd`. Integración en `recress_sala.gd`, `recress.gd`, `game.gd`, `touch.gd`, `settings.gd`, `loc.gd` y `selftest.gd`. Todos son archivos de `godot/scripts/`.

**Evidencia visual.** [Asiento e interacción](godot/shots/rally9_asiento.png), [impulso y depósito](godot/shots/rally9_nitro.png), [plano del rival](godot/shots/rally9_derribo.png), [reincorporación](godot/shots/rally9_reincorporacion.png) y [meta](godot/shots/rally9_meta.png).

**Partidas y dispositivos.** El filtro de RALLY 9 recorre las dos vueltas con las entradas de conducción y la física de las cuatro ruedas. La [prueba de reglas](logs/selftest_rally_20261119_151327.log) pasó 31 comprobaciones. Se comprobó una victoria en 43,11 s, con los controles ordenados, una derrota por puesto y el regreso al asiento. En una [partida interactiva en Windows](logs/selftest_rally_manual_touch_20261119_152743.log) se entró desde el asiento con el ratón sobre el botón táctil emulado, se dosificó el nitro en la salida y se pulsó «Volver al salón» en la meta. Tras los primeros 12 s el conductor de prueba completó las dos vueltas. El resultado fue 4.º de cuatro en 54,31 s. La posición, el dinero, la hora, la alerta policial y la sala se comprobaron al volver. Se añadió el glifo de interacción al asiento y se separó la pausa táctil del contador de vueltas tras revisar la ventana.

Godot 4.7.2 en Windows informó de cero mandos conectados y de una pantalla sin capacidad táctil. La dirección simultánea con gatillo y nitro se probó con eventos de mando. El stick flotante y los botones se probaron con eventos multitáctiles en los nodos reales de la interfaz. La primera prueba interactiva de teclado no arrancó la recreativa desde el escritorio remoto. Las teclas físicas de Godot sí se ejercitaron por su mapa de entradas en la carrera automática. Quedan el tacto y la vibración de un mando conectado, el teclado en persona, un móvil multitáctil y Linux o Steam Deck.

Las regresiones del [Galaxy Recress](logs/selftest_recress_20261119_151447.log) y del [vocabulario](logs/selftest_palabros_20261119_151832.log) pasaron. Las pruebas del salón recorren la misión de reapertura, la entrada, los horarios y la recreativa contigua. Los registros de esta copia ya mostraban un diagnóstico de color `brick_red` en las casas y avisos de recursos al cerrar Godot.

### Salir del coche en la misión del puente

19 de noviembre de 2026. El jugador informó de que, con mando camino de la misión del puente, después de bajar seguía viendo «Bajar» y perdía la posibilidad de hablar o conducir otro coche. Al probar con el coche de Tía Paca junto a Alberto se reprodujeron dos fallos. Pulsar el botón mientras el coche aún iba demasiado rápido vaciaba el asiento antes de rechazar la salida. Al bajar ya detenido, el aviso conservaba la acción anterior hasta que se volvía a calcular el HUD. La [prueba antes del arreglo](logs/selftest_bajar_20261119_152106.log) también detectó dos problemas táctiles al mantener el pedal y «Bajar» mientras cambiaba la distribución de botones.

En `godot/scripts/game.gd` el juego comprueba primero si puede salir. Si el coche supera los 3 m/s o está en reparación conserva el asiento, sus ocupantes y el modo de conducción. Al salir se recuperan el personaje, sus colisiones y la selección de interacciones a pie. El aviso anterior se borra en la misma pulsación. En `godot/scripts/touch.gd` cada botón recuerda la acción que empezó y libera esa acción al cambiar de función o al levantar el dedo. Al cambiar de dispositivo se liberan únicamente los botones y el stick que estaban en uso.

Se añadió `python tools/run_tests.py bajar --headless` a `godot/scripts/selftest.gd`. Las [14 comprobaciones pasaron](logs/selftest_bajar_20261119_152704.log). Con el botón inferior de mando se intentó salir a 3,2 m/s, se salió tras parar, se mantuvo A durante el cambio a «Hablar», se abrió el diálogo de Alberto y se subió a otro coche tras la conversación. También se cubrieron la repetición de E, el paso del teclado al mando, dos dedos que siguen pulsando al bajar y el primer desplazamiento a pie. Se ejercitó la ruta de entrada de mando de Godot. Queda por reproducir en el mando físico del jugador el bloqueo prolongado descrito.

### Versión local 0.0.18

19 de noviembre de 2026. Se guardó el estado conjunto de la copia de trabajo, incluidos los cambios previos de mapa, casas y creador que figuran en PROJECT_STATE.md. La versión del juego se lee de `godot/project.godot`. Android lleva nombre 0.0.18 y código 18 en `godot/export_presets.cfg`. Los tres paquetes se generan con `tools/make_apk.py 0.0.18`, `tools/make_installer.py` y `tools/make_linux.py` y se conservan en [dist/v0.0.18](dist/v0.0.18/). Para abrir la copia de desarrollo en Windows se puede seguir usando [play.bat](play.bat).

El empaquetador comprobó la firma de Android. Se verificaron los CRC del APK y del contenido del instalador de Windows, el archivo de juego incluido en Linux y la coincidencia de siete scripts compilados entre las tres plataformas. Las [sumas SHA-256](dist/v0.0.18/SHA256SUMS.txt) identifican los tres ficheros comprobados. La etiqueta de Git de esta copia es `v0.0.18`. La [prueba completa de la primera compilación](logs/selftest_full_20261119_201317.log), ejecutada con `python tools/run_tests.py`, terminó con 880 comprobaciones correctas y cero fallos en 516 segundos. El registro también recoge avisos del motor al cerrar y del renderizador sin ventana. El [salón completo](logs/selftest_recress_20261119_201041.log) pasó sus 16 comprobaciones y el [vocabulario](logs/selftest_palabros_20261119_201241.log), sus tres.

Pruebas complementarias de los controles compartidos: [boxeo y guardado de 0.0.17, 86 correctas](logs/selftest_boxeo_guardado-anterior_20261119_153136.log), [bate de Henry, 64 correctas](logs/selftest_motin_20261119_153215.log), [derrape, 9 correctas](logs/selftest_derrape_20261119_153324.log). Las 14 comprobaciones del coche pasaron tanto [en ventana](logs/selftest_bajar_20261119_153411.log) como [sin ventana](logs/selftest_bajar_20261119_200915.log). La recreativa pasó 31 comprobaciones [con imagen](logs/selftest_rally_shots_20261119_153003.log) y [sin ventana](logs/selftest_rally_20261119_200958.log). La [vista táctil final](godot/shots/rally9_mandos.png) muestra el botón de pausa separado de la vuelta.

### Hit The VIP en el Galaxy Recress

Incorporado a la edición local 0.0.18 a petición del usuario. Esta revisión sustituye a la primera compilación local de la misma versión (commit `a03a12e`). Tras reabrir el salón, se juega en la última máquina de la fila de la canasta de baloncesto, al fondo. Lleva el rótulo «Hit The VIP» y muestra dos guantes animados con los colores del combate. Al acercarse aparece el botón de interacción configurado. En teclado es E por defecto, en mando A o ✕ y en táctil se toca el nombre del juego.

Se reutilizan el ring, Fonsi, las reglas, los controles y el marcador del combate libre. Tanto victoria como derrota devuelven al mismo sitio del salón, con la orientación y la cámara anteriores. Cuenta como un combate de boxeo y comparte el récord y el límite diario del Punto Cívico. La historia de Josefa y el desbloqueo por las vías anteriores conservan sus condiciones.

El mueble y su pantalla están en `godot/scripts/recress_sala.gd`, la selección por distancia en `recress.gd`, la entrada y el retorno en `game.gd` y el aviso en `loc.gd`. El filtro `python tools/run_tests.py hitvip --headless` de `selftest.gd` prueba la disponibilidad antes y después de la reapertura, los tres tipos de máquina, el aviso, una derrota y una victoria consecutivas, las estadísticas y el regreso. Se verificó la lectura del rótulo sobre fondo oscuro y la animación de guantes en la [vista final del mueble](godot/shots/hit_the_vip_mueble.png). Pasaron las nueve comprobaciones [sin ventana](logs/selftest_hitvip_20261119_204503.log) y [con imagen](logs/selftest_hitvip_shots_20261119_204943.log), las [86 de boxeo con guardado anterior](logs/selftest_boxeo_guardado-anterior_20261119_204542.log) y las [16 de la misión del Galaxy Recress](logs/selftest_recress_20261119_204621.log). El botón A se comprobó con eventos simulados de mando en Windows.

### Tanda de 20 mejoras jugables (20/11)

20 de noviembre de 2026. Implementadas las 20 mejoras solicitadas por el usuario en `X:\MatritellusGPT` sobre `main` e incorporadas a la edición local `0.0.18`:

- **Rendimiento carteles (Galaxy Recress):** `map_data.gd` evita recalcular Dijkstra en `set_route_target()` si el destino no cambió y `recress.gd` espacia la búsqueda de tienda más cercana (`_poster_t = 0.35`).
- **Rampas y saltos con coche:** planos inclinados lisos a ras de suelo en `sebastian.gd`, `plaza.gd`, `aceras_altas.gd`, `puente.gd`, `caridad.gd` y `cuartel.gd`; `car.gd` añade material de baja fricción, levanta 0,10 m los bajos del morro/trasera y lanza el coche en `_ramp_launch(dt)` al entrar rápido en cualquier rampa de `MapData.decks`.
- **Cinemática del alcalde a la salida del Recress:** `recress.gd` oculta al jugador y limpia vehículos aparcados, tráfico, policía y peatones en el tramo de calle; `game.gd` congela el tráfico durante `recress.cine`.
- **Tokken 9 — Salir:** botón «SALIR», atajo `ESC`/atrás, ratón visible en selección/pausa y botón táctil en `tokken.gd`.
- **Rally 9:** ruedas visuales montadas en `body.inner` para los 7 coches (sin culling en `parts.gd` ni desync en `car.gd`), hitboxes dinámicas por tamaño de coche, rubberbanding + reaparición con llama de nitro si un rival se descuelga `> 95 m`, y 3 vueltas (`rally.gd`, `rally_hud.gd`, `rally_pruebas.gd`).
- **Katakumba69 y máquinas de Tokken 9:** todas las cabinas en libre juegan contra la CPU; para retar a Katakumba69 hay que hablar con él dentro del Recress (con puntos de confianza y respetando su revelación a 100 de confianza).
- **Ajedrez humano y perros:** eliminada la rotación errónea de `PI` en `perro.glb` (`ajedrez_humano.gd` y `ruta.gd`); las piezas del jugador miran hacia la partida y las rivales hacia el jugador.
- **Rondas lúdicas de NPCs únicos:** ampliadas a 12 personajes únicos exteriores en `rondas.gd` con rutinas por personalidad (bares, pubs, comida, recreativos, salud, plazas) cuando están libres y sin misión.
- **Movimiento diagonal estable:** vector radial `Input.get_vector(..., 0.25)` en `game.gd` y zona muerta radial en `touch.gd`.
- **Misión del kebab (sospecha, furgoneta rápida y captura):** medidor continuo de sospecha en `hud.gd` + `sabotaje.gd`, velocidad de reparto subida (`PACE = 1.65`) con bocadillos flotantes de `*hablando en árabe inventado*`, y si el repartidor te pilla fuera de la furgoneta esta queda aparcada junto a él sin clonarse ni marcharse.
- **Frases de golpe divididas:** `hit_bat`, `hit_car` y `hit_both` en `loc.gd` (incluyendo «¡Ostia!» y cumpliendo `palabros.md`), cableadas en `game.gd` y `motin.gd`.
- **Policías y guardias civiles uniformados:** `officer_look()` en `game.gd` (uniforme y gorra azul para pitufos; clon de Ramírez con tricornio para guardias civiles) usado en `traffic.gd` y `police.gd`.
- **Taller (repintado y limpieza de búsqueda):** `Modelos.repaint()` y `car.repaint()` cambian el color a otro distinto y `_mended()` limpia `police.reset()`, congelando a la policía durante la reparación.
- **Entrar en interiores pulsando Acción:** `entradas.gd` y `game.gd` exigen pulsar interacción (`p_entrar`) igual que al salir.
- **Mapa grande (elegir/quitar misión):** panel interactivo y fotos clicables en `minimap.gd` + `game.gd` + `marcas.gd`; deseleccionar («Ninguna») oculta flecha 3D, baliza y ruta GPS.
- **Objetos 3D flotantes giratorios con brillo:** nuevo `godot/scripts/pickups.gd` (halo billboard aditivo + aro en suelo + malla 3D giratoria para bate, spray, carteles, jamón, móvil, kebab), integrado en `game.gd`, `pintadas.gd` y `recress.gd`.
- **Inventario estilo Animal Crossing:** nuevo `godot/scripts/inventario.gd` con dos pestañas (`Objetos` y `Objetos clave` no vendibles/tirables), tecla `I` / mando `Y`/`△` (`controls.gd`) y botón táctil «Mochila» (`touch.gd`).
- **Salir del juego con confirmación y ratón en menús:** opción Salir en menú principal y pausa con confirmación («¿Tás seguro? Mía que se estaba poniendo divertío.») en `game.gd`/`loc.gd` y soporte de ratón en `menu.gd`.

**Pruebas ejecutadas (todas con 0 fallos y 0 errores de script):**
- `python tools/run_tests.py mejoras --window`: **9 ok, 0 failed** ([log](logs/selftest_mejoras_20261120_150152.log)) + capturas revisadas (`mejora_mapa.png`, `mejora_pickups.png`, `mejora_inv_obj.png`, `mejora_inv_key.png`).
- `python tools/run_tests.py entradas --window`: **4 ok, 0 failed** ([log](logs/selftest_entradas_20261120_150247.log)).
- `python tools/run_tests.py rally shots --window`: **31 ok, 0 failed** ([log](logs/selftest_rally_shots_20261120_150401.log)) + capturas revisadas (`rally9_derribo.png`, `rally9_nitro.png`, `rally9_meta.png`, `rally9_reincorporacion.png`).
- `python tools/run_tests.py ajedrez --window`: **17 ok, 0 failed** ([log](logs/selftest_ajedrez_20261120_151618.log)) + capturas revisadas (`aj_inicio.png`, `aj_perro_salta.png`, `aj_perro_quieto.png`).
- `python tools/run_tests.py palabros --headless`: **3 ok, 0 failed** ([log](logs/selftest_palabros_20261120_151815.log)).
- `python tools/run_tests.py recress --headless` (**16 ok, 0 failed**), `tokken shots --window` (**11 ok, 0 failed**), `rondas --headless` (**1 ok, 0 failed**), `sabotaje --headless` (**45 ok, 0 failed**).

### Cámaras al conducir, Tomasa Malvora, fumadores y HUD dev (20/11)

20 de noviembre de 2026. Implementadas las 5 mejoras nuevas en `X:\MatritellusGPT` sobre `main` (commit `8262fd8`, con el director del tráiler `trailer.gd`; la canción, `trailer song/`, queda fuera del repositorio en `.gitignore`):

- **Sistema de cámara en coche (3 modos):** acción reasignable `cam_mode` (`V` en teclado, `cruceta ←` / `R3` en mando, botón táctil «Cámara» en `controls.gd` y `touch.gd`).
  - `0` Tercera persona (clásica).
  - `1` Primera persona (`car.gd:driver_pov()` + `set_driver_head_visible(false)` en el nodo `head` de `chara.gd:sit()`): vista desde encima de los hombros dentro del habitáculo con `cam.near = 0.05` y giro libre de cabeza con ratón/stick derecho.
  - `2` Cinemática tipo GTA (`game.gd:_pick_cine_spot()`): planos estratégicos en acera/esquina/ángulo bajo validados con raycast; salta automáticamente al siguiente punto si el coche se aleja `> 36 m`, si pasan `≥ 5 s` o si un edificio tapa la vista.
- **Slow-motion + cámara cinemática en saltos de coche:** `game.gd:_update_air_cine()` detecta saltos reales en el aire (`airborne()`, altura sobre el suelo/rampa), baja `Engine.time_scale` suavemente a `0,38` con plano cinemático lateral-bajo siguiendo el vuelo y restaura `1,00` al aterrizar (y al instante al pausar, bajar del coche o cambiar de fase).
- **Tomasa Malvora e interior de los chinos del Arroyuelo:**
  - Nuevo `godot/scripts/chinos_dentro.gd` en `(1800, 1400)`, conectado en `chinos.gd` y `entradas.gd` según el horario comercial del local.
  - Nuevo `godot/scripts/tomasa.gd`: Tomasa Malvora pasea cerca de los chinos mientras están abiertos; al hablar ofrece el recado (`Sí` / `No`: decir «No» la enfada y resta confianza; decir «Sí» hace que espere fuera). Dentro del local, **El chino** habla en infinitivo advirtiendo que no robes nada porque te vigila, y en el pasillo derecho gira el paquete de tabaco (`pickups.gd`, `auto = false`, cartel «Comprar · 6 €»). Al entregarlo a Tomasa termina la misión (`+10` confianza, `+3` PC, `10 €`), explica que sus hijos le vigilan el dinero pero que ella controla, y se enciende un cigarro. El paquete figura en `Objetos clave` de `inventario.gd`.
- **Tabaco en el 5 % de la población (no niños):** `game.gd:_neighbour_look()` asigna `"smoke": true` al 5 % de vecinos adultos y mayores (0 % niños); `chara.gd:_cigarette()` acopla un cigarro encendido con brasa emisiva y voluta ligera de humo en `neck`.
- **Opción de desarrollador para ocultar HUD:** fila «Botón ocultar HUD (ºª / Select)» en `Pausa → Desarrollador` (`game.gd:dev_hud_key`, `set_hud_hidden()`). Con el modo desarrollador y la opción activados, `ºª` en teclado y `Select` (`JOY_BUTTON_BACK`) en mando ocultan y muestran el HUD, flecha guía, baliza, FPS y controles táctiles sin bloquear los menús.

**Pruebas ejecutadas (todas con 0 fallos y 0 errores de script):**
- `python tools/run_tests.py mejoras2 --window`: **9 ok, 0 failed** ([log](logs/selftest_mejoras2_20261120_182926.log)) + capturas revisadas (`mejora2_cam_fp.png`, `mejora2_cam_cine.png`, `mejora2_air_slowmo.png`, `mejora2_chinos_tabaco.png`).
- `python tools/run_tests.py chinos --window`: **5 ok, 0 failed** ([log](logs/selftest_chinos_20261120_183050.log)).
- `python tools/run_tests.py palabros --headless`: **3 ok, 0 failed** ([log](logs/selftest_palabros_20261120_182640.log)).

### Publicación de la 0.0.18 en GitHub (20/11, Claude · Sistemas)

20 de noviembre de 2026. El usuario pidió publicar la 0.0.18 con todo lo pendiente y que las sesiones de Claude trabajen desde ahora en `X:\MatritellusGPT` (`X:\Matritellus` queda de copia de seguridad). Avisadas Edificios Especiales (Pretil), Texturas y Modelado y Worldbuilding; Creador y Recreativos están archivadas.

- **Prueba completa** (`python tools/run_tests.py`): 879 ok y 1 fallo en 568 s ([log](logs/selftest_full_20261120_231727.log)). El fallo era de la prueba: la copistería del Recress esperaba entrar solo con pisar la flecha y desde la tanda de 20 mejoras hay que pulsar Acción. `selftest.gd` llama ahora a `g.interact()` sobre la flecha, como ya hacía la del Recress. `python tools/run_tests.py recress --headless`: 16 ok ([log](logs/selftest_recress_20261120_232718.log)).
- **Commits:** `8262fd8` (la tanda de cámaras, Tomasa, fumadores, HUD dev y tráiler) y «Matritellus 0.0.18» con estas notas. La etiqueta local `v0.0.18`, que no se había subido, se movió a este último.
- **Paquetes** rehechos con `tools/make_apk.py 0.0.18`, `tools/make_installer.py` y `tools/make_linux.py`, copiados a `dist/v0.0.18/` con sus `SHA256SUMS.txt` nuevas, y subidos a la release: https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.18
- ~~**Pendiente:** la casa de Matías Pérez 16 sale como hueco hasta que Pretil la haga a mano (aviso de Texturas).~~ El aviso era un error. La casa sí está en la 0.0.18: la levanta `matias.gd`. Edificios Especiales lo comprobó con el paquete de Linux y en esta carpeta (prueba `matias`: 2 ok). Solo sale como hueco en las hojas de repaso de casas, que dibujan únicamente `casas.gd`. Más abajo está la entrada de Texturas del 20/11.

### Árbol de relaciones: Tomasa Malvora y el chino del Arroyuelo (20/11)

20 de noviembre de 2026, Worldbuilding (Claude). Cada personaje nuevo va al árbol de relaciones del guion (`guion/relaciones.html`, para el usuario; no es parte del juego). Tomasa Malvora y el chino llegaron con la 0.0.18 y no estaban.

- **Hecho.** Tres personas más: Tomasa Malvora, sus hijos (solo se les nombra) y el chino del Arroyuelo. Tres relaciones: la Tomasa y sus hijos, que le vigilan el dinero; la Tomasa y el chino, que no le vende directamente porque ella no entra; tú y la Tomasa, el recado del tabaco. Un cabo suelto nuevo: ni los hijos ni el chino tienen nombre.
- **Archivos.** `guion/relaciones.json`, `guion/relaciones.html` (hecho con `tools/make_relaciones.py`: 43 personas, 36 relaciones) y las fotos `guion/fotos/tomasa.png` y `guion/fotos/chino.png`. En `godot/scripts/selftest.gd`, el modo `--portraits` saca también a la Tomasa y al chino (sus caras están en `tomasa.gd`, porque solo salen con la tienda abierta). La opción nueva `--solo=tomasa,chino` hace solo esas fotos y deja las demás como estaban.
- **Verificación.** `python tools/run_tests.py portraits solo=tomasa,chino --window` escribió solo las dos fotos, revisadas a ojo (el ejecutor dice «NO RESULT» porque este modo no hace comprobaciones: guarda las fotos y sale). Se comprobó con un cálculo sobre las posiciones que ninguna línea del árbol pasa por encima de una cara junto a los nuevos.
- **Sin commit.**

### El color de la barandilla de una terraza en Covadonga (20/11)

20 de noviembre de 2026, Texturas (Claude). Edificios Especiales vio que la prueba registraba el error `Invalid hexadecimal notation character "r" in string "brick_red"`. Sale en `casas.gd:877` (`_unpack`), al que llaman `world._houses` y `recress._spec_of`.

- **Causa.** En la línea de `cov_6` (Calle de Covadonga, aprobada el 17/11), la pieza `ter` llevaba como color de la barandilla el nombre de un material, `brick_red`. Ese valor solo admite un código hexadecimal, así que la barandilla salía negra. No había ningún otro `ter`, `awn` o `c=` con un nombre en lugar de un código.
- **Hecho.** La barandilla es ahora `9a4e36`, un rojo ladrillo como el remate de la terraza en la foto del Catastro. No hace falta rehacer el mapa, porque la línea de la casa se lee al cargar el juego.
- **Archivos.** `godot/scripts/casas_calles.gd`: solo la línea de `cov_6`.
- **Verificación.** `python tools/run_tests.py casas "solo=cov_6"`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_cov_6_20261120_233933.log)). El aviso del hexadecimal ya no sale.
- **Corrección.** El pendiente de la entrada de la 0.0.18 sobre Matías Pérez 16 salió de un aviso mío equivocado. Está tachado y explicado allí.
- **Sin commit.**

### Matías Pérez 16 retocada con Street View (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Luis lo pidió el 17/11 («Nuevo proyecto. Matias Pérez 16», con una captura de Street View de noviembre de 2024). La casa se levantó a mano en `X:\Matritellus` y llegó a la 0.0.18. Al compararla en esta carpeta con Street View desde las mismas cámaras, salieron estas diferencias, ya corregidas:

- **El ladrillo.** Era el rojo oscuro y rugoso de `brick_wall_006`; en la foto es caravista salmón, de hiladas regulares y llaga clara. Ahora es `brick_wall_003@0.9`, para que cada ladrillo mida 25 cm.
- **Los sardineles.** Antes eran rosados y destacaban. Ahora tienen el tono del muro. El de cada ventana de arriba va justo sobre el hueco, sin hilada en medio, y la faja corrida está a 2,85 m.
- **Las persianas.** Quedaban detrás del cristal y no se veían. Ahora están bajadas hasta el alféizar, delante de la ventana, en color liso con sus lamas, como las de `casas.gd`. Las de arriba son blancas y la de abajo beige.
- **El resto.**
  - Las cortinas del portalón son crema con rosas grandes de gris malva, se juntan en el centro y el portalón lleva jambas de madera oscura.
  - La cortina de la puerta es más blanca.
  - La reja tiene nueve barrotes y travesaños solo arriba y abajo.
  - El zócalo gris sube a unos 45 cm.
  - El cable va a la altura de los alféizares, y en lugar de la caja gris hay dos cajitas blancas.
- **Archivos.** `godot/scripts/matias.gd` y, nuevos, `tools/matias/hojas.py` y `referencias/matias/LEEME.md`. No se tocó ningún archivo compartido.
- **Pruebas.**
  - `python tools/run_tests.py matias`: 2 ok, 0 fallos ([log](logs/selftest_matias_20261121_002706.log)).
  - Las vistas desde las cámaras de Street View se sacaron con `tools/merkocarry/vistas.py`. El ejecutor dice «NO RESULT» porque ese modo solo hace fotos.
  - Se probó también el paquete de Linux publicado (`--main-pack`), con la casa antigua: 2 ok, 357 piezas.
  - Esa última prueba coincidió un momento con un Godot de otra sesión. No volverá a pasar.
- **Hojas para Luis.** `guion/fotos/matias/01_street_view_y_juego.jpg` (Street View al lado del juego) y `02_en_el_juego.jpg`.
- **Aprobada** por Luis el 21/11: «Visto bueno». Sin commit: la publica Sistemas.

### Calle del Triunfo, tramo de las afueras: 16 naves (21/11)

21 de noviembre de 2026, Texturas (Claude). Es la siguiente calle del núcleo, a la orden del usuario («Visto bueno y siguiente»).

- **Hecho.** 16 naves y almacenes con su frente en el Triunfo (`tri_e147` … `tri_17`), descritos con las fotos del Catastro. Para cuatro, cuya foto del Catastro está hecha desde la Avenida de Europa, se usó Street View. Se dejan sin hacer el 35, el molino viejo de Reyes Católicos, el 11, el 27 y el 18. La razón de cada uno está en `PROJECT_STATE.md`, y lo que aún no se parece, en `guion/repaso_casas.md`.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd`: 16 entradas nuevas.
  - `godot/data/map.json`: horneado.
  - Las carpetas del Catastro `tools/casas/<ref>/` de estos edificios.
  - Las hojas `guion/fotos/tanda34/triunfo_4..6.jpg`.
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Se horneó dos veces, avisando a Edificios Especiales antes y después. Comparado con la copia de antes: 16 casas nuevas, ninguna quitada ni cambiada. Calles (656), nodos (6376), relieve, árboles (2956) y holguras de las calles siguen igual. Ninguna casa tiene partes por delante de su frente.
- **Pruebas.**
  - `python tools/run_tests.py casas "solo=tri_"`: el primer intento falló porque `tri_e151`, `tri_e145` y `tri_41` no llegaban a 12 piezas.
  - Con los postes, las juntas y el ladrillo desteñido que se ven en las fotos, `solo=tri_e151,tri_e145,tri_41` dio 4 ok, 0 fallos.
  - Tras los últimos retoques, `solo=tri_e151,tri_41,tri_e129,tri_t1` dio 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tri_e151_tri_41_tri_e129_tri_t1_20261121_004155.log)).
- **Pendiente.** El visto bueno del usuario a las hojas. Sin commit.

### El puente sin «todo hecho», el reloj en la hoja y el pitillo de la Tomasa (21/11, Claude · Sistemas)

21 de noviembre de 2026. Tres cambios que pidió el usuario.

- **El puente.** Desbloquearlo ya no lleva a la pantalla de «continuará» ni a sus estadísticas: «Ahora hay más misiones disponibles». El paso `tbc` sigue cerrando la historia hecha, pero no cuenta los 9 s ni funde a negro. El objetivo es `obj_free`, con texto nuevo: «Hay más gente en el pueblo que te necesita. Mira el mapa o la Agenda, o date un garbeo.».
  - `game.gd`: fuera `_tbc_t` y `_show_end`.
  - `missions.gd`: el paso `tbc` usa `obj_free`.
- **El reloj.** La hoja del calendario dice «LUNES · 12:07» en vez de «LUNES · MAÑANA»: «solo horas y minutos».
  - `game.gd`: `clock_text()` y `_tag()`.
  - La hoja solo sale sola cuando cambia el momento del día, no a cada minuto. `_tag()` deja `hud.day_key` (día y momento) y `hud.gd` compara eso en vez del texto.
  - `hud.show_day(s)` la saca un rato a propósito.
- **El pitillo.** La primera vez que le llevas el tabaco, la Tomasa pregunta «¿te echas un *pitillo* conmigo?».
  - Con «Venga, uno» o con «No, que yo no fumo» te lo fumas igual, con frases distintas: la culpa y el cáncer «al cincuenta por ciento».
  - Ese primero es el ejemplo de la mecánica. La cámara sube 16 m por encima de los tejados mirando al cielo. Pasan 6 horas en 5 s, con el cielo y el reloj cambiando, y la cámara vuelve.
  - Después te da tres: el objeto clave «Pitillo» ×3. En Mochila → Objetos clave se puede «Usar».
  - Solo se fuma a pie, sin misión ni encargo en marcha y sin que te busquen. Si no, un aviso dice por qué.
  - En los chinos del Arroyuelo, una vez hecho el recado, el estante del tabaco vende «Pitillos ×3 · 6 €». Son los únicos chinos del pueblo por ahora; el usuario dijo «en cualquier chino».
  - Archivos: `fumar.gd` (nuevo), `tomasa.gd` (`_offer_smoke`, `_smoke_with`, `_spawn_pitillos`, `buy_prompt`, `buy`), `inventario.gd` (el objeto, su botón Usar y su icono), `game.gd` (la fase `smoke`) y `loc.gd` (las frases).
  - Con una partida guardada entre el tabaco y los tres pitillos, `restore()` te los da.
- **Pruebas.**
  - `python tools/run_tests.py mejoras2 --headless`: 12 ok, 0 fallos. Incluye las tres nuevas: el pitillo con la Tomasa (6,00 h, la cámara arriba, 3 pitillos), comprar en los chinos y fumar desde la mochila.
  - `mejoras2 shots --window`: las fotos `pitillo_tomasa.png` y `pitillo_cielo.png` (el cielo a las 15:55, con la hoja).
  - Prueba completa (`python tools/run_tests.py`): 879 ok y 1 fallo en 480 s ([log](logs/selftest_full_20261121_012128.log)). Ahí pasan las del reloj y el final del puente. El fallo era un «tienes» en `fumar_busy`, que ahora dice «tiés». `palabros --headless`: 3 ok ([log](logs/selftest_palabros_20261121_012938.log)). La prueba incluía, sin commitear, el suelo y los matojos de Texturas.
- **Decidido sin preguntar.** El pitillo de la Tomasa es suyo: no gasta de los tres. Un paquete de los chinos trae tres por 6 €, el precio del tabaco del recado.

### Ermita del Cristo del Prado (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Luis lo pidió el 21/11: «Siguiente proyecto la Ermita del Cristo del Prado (junto a la residencia, en la misma manzana)».

- **Hecho.** `godot/scripts/cristoprado.gd`, sobre `obra.gd`. Incluye la ermita, su placita, la acera del Paseo con el ajedrezado, los olmos y los pilones, la franja con verja de la Calle del Cristo y el calvario del parque. El detalle y las medidas están en [referencias/cristoprado/LEEME.md](referencias/cristoprado/LEEME.md).
- **El horneado.**
  - El Catastro tiene la ermita y la Residencia como un solo edificio, `4587301VJ5648N`. `tools/bake_godot.py` deja de levantar las partes de la ermita (con los cambios de `tools/cristoprado/enganche.py`); la Residencia sigue genérica.
  - `godot/data/map.json` rehorneado con el OK de Sistemas y de Texturas, igual al ensayo.
  - Frente al mapa anterior: cambia la manzana de la ermita (su contorno y 25 muros que se quitan y 10 nuevos, todos a menos de 60 m), hay 2 árboles menos en la acera sur y aparece la clave `cristoprado`. Casas, calles y relieve, iguales.
  - Unos 155 contornos de otras manzanas se mueven 0,3 m como mucho, porque se simplifican de otra manera.
- **Archivos compartidos**, con los avisos dados: `map_data.gd`, `world.gd` y `selftest.gd` (modo `--cristoprado`, y `_cristoprado_checks` en la prueba completa, tras Matías Pérez). Los cambios salen de `tools/cristoprado/enganche_juego.py`.
- **Nuevos.**
  - `tools/cristoprado/`: `manzana.py`, `capturas.py`, `enganche.py`, `enganche_juego.py` y `hojas.py`.
  - `tools/ign/cristoprado.*`.
  - `referencias/cristoprado/LEEME.md`.
- **Pruebas.**
  - `python tools/run_tests.py cristoprado`: 2 ok, 0 fallos ([log](logs/selftest_cristoprado_20261121_013705.log)): 2171 piezas, 10 ventanas y puertas, los muros paran, el suelo ante las dos puertas está libre y nada pisa el asfalto.
  - La primera pasada falló: la verja de la cabecera pisaba la Calle del Cristo, que dobla la esquina. Ya está corregida.
  - Vistas desde las cámaras de Street View con `tools/merkocarry/vistas.py`. El ejecutor dice «NO RESULT» porque ese modo solo hace fotos.
- **Hojas para Luis.** `guion/fotos/cristoprado/01_street_view_y_juego.jpg` y `02_en_el_juego.jpg`.
- **Su corrección (21/11).** Sobre la vista desde la esquina del Paseo con la Calle del Cristo dijo: «The building it's pretty good, but i'm missing the little stone wall in red and the last portion of acera (in yellow). After these fixes we can continue with the rest of the apple». Hecho en `cristoprado.gd`, sin rehornear:
  - **El murete de piedra.** El enlosado claro sigue el suelo hasta el crucero y desde allí queda a nivel, mientras la calle baja. Su murete con albardilla sube así de bordillo a medio metro en la esquina y rodea la cabecera por la Calle del Cristo, con su chaflán donde la calle corta la esquina.
  - **El enlosado claro** tiene su suelo para pisar (`MapData.decks`). Los pilones están sobre el murete y el portón se abre a su nivel.
  - **La acera.** El ajedrezado es ahora una sola rejilla que rodea la esquina hasta el asfalto de las dos calles; antes allí salía el césped del parque del mapa. Los coches aparcan solo hasta x = 30.
  - **Pruebas.** `python tools/run_tests.py cristoprado`: 2 ok ([log](logs/selftest_cristoprado_20261121_021318.log)). Un primer intento falló porque un pilón pisaba la Calle del Cristo; ya está corregido. Otra pasada coincidió con un Godot de otra sesión.
- **Aprobada con esos arreglos.** Sin commit.

### Suelo de tierra y plantas secas en todo el pueblo (21/11)

21 de noviembre de 2026, Texturas (Claude). El usuario, al ver las hojas del Triunfo: el suelo de color plano «tiene poco y nada que ver con la realidad». Pidió algo más anaranjado o marrón, con algo de textura, y «plantas secas sueltas, para que no quede todo tan plano».

- **El suelo** (`godot/scripts/world.gd`):
  - El terreno era arena pálida (`e3cf95`). Ahora es pardo anaranjado (`EARTH = 0xc4905c`), sacado de la tierra al sol en las fotos del Catastro del Triunfo (tono unos 30°, `#cf9a5c`).
  - Lleva una textura nueva hecha en código, `"tierra"` en `_tex`: grano, manchas suaves más rojizas donde son más oscuras y chinas de 2×2.
  - Con un material propio, `_earth_mat()`, la textura se superpone a 5, 23 y 61 m para que no se note que se repite en un solar entero.
  - Los caminos de tierra pasan a `"tierra"` en `caa170`, más claros y apisonados. Los barbechos y los campos arados pasan a pardos (`c99c66`, `c39266`).
  - La textura `"earth"` de siempre no cambia: la siguen usando Calasanz y la Caridad.
- **Las plantas** (`godot/scripts/matojos.gd`, nuevo):
  - Son matas de hierba seca y algún matojo seco, en rodales, más espesas al pie de las tapias y en la orilla pasada la acera.
  - Solo crecen en el pueblo y hasta 64 m de la última manzana.
  - No salen:
    - en calles ni aceras;
    - dentro de las manzanas;
    - en césped, parques, viñas ni agua;
    - en los sitios hechos a mano: se miran los nodos que heredan de `obra.gd` o `petril.gd`, en su propio marco.
  - Además, un rayo hacia abajo tiene que dar en el terreno desnudo.
  - Se dibujan con MultiMesh por cuadros de 64 m, que no se ven a más de 120 m (`Parts._range`, así que les afecta la opción de distancia de dibujado). No dan sombra ni chocan.
  - Es un paso nuevo de la construcción del mundo, `["dry plants", _build_matojos]` entre `details` y `bounds`, que trabaja a trozos de 12 ms.
- **Caché.**
  - La primera vez se calculan unas 137.000 plantas en 4,7 s y se guardan en `user://matojos.cache` (6 MB).
  - Después se leen en 0,7 s. Hay que volver a calcularlas solo si cambian el mapa, los sitios hechos a mano o `VERSION` en `matojos.gd`.
  - Las pruebas usan la misma caché.
  - `--sin-matojos` las quita, para medir lo que cuestan.
- **Pruebas.**
  - `python tools/run_tests.py casas "solo=tri_47,tri_e151,tri_45,tri_17,tri_t1,tri_e129"`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tri_47_tri_e151_tri_45_tri_17_tri_t1_tri_e129_tim_20261121_011538.log)).
  - `python tools/run_tests.py suelos`: 1 ok, 0 fallos ([log](logs/selftest_suelos_20261121_011818.log)).
  - `bench --window`, con plantas: 127,8 fps, gpu 5,06 ms, 1362 llamadas de dibujo ([log](logs/selftest_bench_20261121_011227.log)). Con `sin-matojos`: 125,4 fps, gpu 5,16 ms, 1398 llamadas ([log](logs/selftest_bench_sin-matojos_20261121_011400.log)). Es la misma cifra con su ruido.
  - Vistas con `vistas=`: hay plantas en los solares y los caminos, y ninguna en la plaza.
- **Hojas.** `guion/fotos/suelo/suelo_1.jpg` (Catastro, antes y ahora en dos casas del Triunfo) y `suelo_2.jpg` (solar, matas de cerca, camino de tierra y las afueras desde arriba).
- **Sin probar en el móvil.** La primera vez que se abra, la carga tardará unos segundos más.
- **Aprobado** por el usuario el 21/11: «Mucho mejor. Visto bueno y siguiente». En el commit `ad86143` (Sistemas, 21/11, sin push).

### Calle de los Cipreses: 33 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). Es la siguiente calle del núcleo, a la orden del usuario («Visto bueno y siguiente»).

- **Hecho.** 33 casas con su frente en los Cipreses (`cip_*`), descritas con las fotos del Catastro y siete con Street View. Lo que queda fuera y por qué está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd`: 33 entradas nuevas.
  - `godot/data/map.json`: horneado.
  - Las carpetas del Catastro `tools/casas/<ref>/`.
  - Las hojas `guion/fotos/tanda34/cipreses_1..6.jpg`.
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Horneado sobre el mapa con el Cristo del Prado de Edificios Especiales, avisándole antes y después. Comparado con la copia de antes: 33 casas nuevas, ninguna quitada ni cambiada. Calles (656), nodos (6376), relieve, árboles (2954) y holguras siguen igual. Ninguna casa tiene partes por delante de su frente.
- **Pruebas.**
  - `python tools/run_tests.py casas "solo=cip_"`: el primer intento falló porque `cip_t60` no llegaba a 12 piezas.
  - Con las pilastras y el portón de su foto, `solo=cip_t60` dio 4 ok, 0 fallos.
  - Tras los once arreglos, `solo=cip_t58,…,cip_10` dio 4 ok, 0 fallos ([log](logs/selftest_casas_solo_cip_t58_cip_sb47_cip_x1_cip_34_cip_26_cip_39_cip__20261121_021512.log)).
- **Plantas secas.** El mapa ha cambiado, así que la caché de `matojos.gd` se rehace sola la próxima vez que arranque (unos 4,7 s).
- **Aprobada** por el usuario el 21/11: «Visto bueno y siguiente». En el commit `ad86143` (Sistemas, 21/11, sin push).

### Arreglo: errores de UV en el calvario (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Aviso de Sistemas tras el commit ad86143: al cargar salían 6 errores del motor («Condition "!first && !(format & Mesh::ARRAY_FORMAT_TEX_UV)"») desde `roof()` en `cristoprado.gd` `_calvario`.

- **Causa.** El remate del calvario usaba `roof()`, que pone UV, con el material `caliza`. Las demás piezas de ese material no llevan UV, y una misma malla no puede mezclar vértices con y sin UV.
- **Arreglo.** `_slope()` en `cristoprado.gd`: las cuatro caras inclinadas sin UV. `caliza` es triplanar y no las necesita. Se ve igual.
- **Prueba.** `python tools/run_tests.py cristoprado`: 2 ok, 0 fallos, y ningún error de UV en el log ([log](logs/selftest_cristoprado_20261121_083749.log)). Sin commit.

### Residencia de mayores del Cristo del Prado (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Después de aprobar la ermita, Luis dijo: «After these fixes we can continue with the rest of the apple». Es el resto de la manzana de la ermita.

- **Hecho.** `godot/scripts/residencia.gd`, sobre `obra.gd`:
  - **El bloque grande**, de tres plantas entre los dos brazos de la Calle del Cristo:
    - ladrillo salmón claro con paños altos de mampostería entre los huecos y zócalo de mampostería con las ventanas enrejadas del sótano;
    - rejas con copete abajo y balconcitos de hierro arriba;
    - alero de teja en inglete alrededor de la azotea con sus placas solares.
  - **Dos alturas**: la calle baja casi 3 m de la punta norte al Paseo, así que la parte sur está un escalón más baja, donde la marca el Catastro.
  - **La entrada principal**, a la Calle del Cristo: el gran medio punto acristalado con sus radios, las puertas de vidrio, la marquesina y la escalinata. La escalinata va dentro del porche porque el asfalto del mapa llega allí casi a la fachada.
  - **El cuerpo redondo** de dos plantas, contra la nave de la ermita.
  - **El ala baja**, sobre la placita y el brazo oeste: el porche de pies derechos de madera, los canecillos y las rejas.
  - **Las aceras** de baldosa clara.
- **Fuentes.**
  - El Catastro, `4587301VJ5648N`: las partes que no son la ermita.
  - La ortofoto `tools/ign/cristoprado.jpg`.
  - Street View: el brazo este y la punta norte en 2024, el brazo oeste y la placita en 2013. Están listados en `tools/residencia/capturas.py`.
- **El horneado.**
  - `tools/residencia/enganche.py`, aplicado a `tools/bake_godot.py`. Con `residencia.gd` en `READY := true` no se levanta nada del edificio 4587301, y sus cuatro contornos entran en los bloques. La clave del mapa es `residencia`.
  - Rehorneado con el OK de Sistemas y de Texturas, igual al ensayo. Frente al mapa anterior: casas (2246, también las `cip_*` de Texturas), calles, relieve y árboles, iguales. Desaparece el bloque genérico (35 muros y 4 tejados planos) y entra la clave.
- **Archivos compartidos**, con los avisos dados: `map_data.gd`; `world.gd`, con el paso tras la ermita (los matojos y el suelo de Texturas, sin tocar); `selftest.gd`, con el modo `--residencia`, y `_residencia_checks` en la prueba completa tras `_cristoprado_checks`. Los cambios salen de `tools/residencia/enganche_juego.py`.
- **Pruebas.**
  - `python tools/run_tests.py residencia`: 2 ok, 0 fallos ([log](logs/selftest_residencia_20261121_023744.log)).
  - Los dos primeros intentos fallaron porque el pie de la escalinata pisaba el asfalto. Ya está corregido.
- **Hojas para Luis.** `guion/fotos/residencia/01_street_view_y_juego.jpg` y `02_en_el_juego.jpg`.
- **Corrección del ala baja (21/11, mañana).**
  - Luis: «Really impressive. Just a couple of adjustments. Here in red the fachada is very different to the photo, also a door is missing», y mandó seis capturas de una foto 360 de Google Maps de hace seis años (C. del Cristo, 52). Las capturas no se guardan en el repositorio.
  - **La fachada a la placita, rehecha en `residencia.gd`**:
    - cuatro ventanas, un solo porche de dos vanos, cerrado por cancelas de hierro de suelo a viga, con el pie derecho de madera en medio, y una última ventana junto al cuerpo redondo;
    - dentro del porche, la puerta de madera de cuarterones, una ventana, la tabla de la Mayordomía con el azulejo del Cristo, dos faroles, el banco y las macetas;
    - el zócalo de granito claro, las columnas de cajones, la cornisa de ladrillo en dientes y los canecillos.
    - Antes el porche ocupaba toda la fachada.
  - **La puerta que faltaba** es la de la Residencia, en el muro del cuerpo redondo, entre el ala y la ermita. Lleva la cancela, la banda con el nombre, el montante con la cruz y el balcón de dos ventanas encima.
  - **La fachada del ala está 2,85 m más atrás que la línea del Catastro.**
    - Medido en la ortofoto: el alero queda 2,25 m dentro, igual de punta a punta. La cara oeste y la fachada de la ermita sí coinciden con el Catastro.
    - El césped de OpenStreetMap del mapa rodea el edificio por esa misma línea.
    - Así queda al aire el muro de la puerta. La franja que sobra se enlosa como la placita.
    - No hace falta horneado: el contorno del ala solo está en `residencia.gd`.
  - **Archivos**: `godot/scripts/residencia.gd`; `tools/residencia/hojas.py`, con la hoja 03, que pone las fotos 360 al lado del juego; `referencias/cristoprado/LEEME.md`, con la sección de la Residencia y las cámaras. Ningún archivo compartido.
  - **Pruebas**: `python tools/run_tests.py residencia`, 2 ok y 0 fallos ([log](logs/selftest_residencia_20261121_054845.log)).
    - El primer intento dejaba el suelo del porche medio metro por encima de la placita, y por debajo se veía el césped. Ya está corregido.
  - **Hojas**: `01_street_view_y_juego.jpg`, rehecha, y `03_ala_fotos_360.jpg`, nueva.
- **Aprobada** por Luis el 21/11 («Visto bueno»), con la corrección del ala. Sin commit.

### Modelados de la línea de la casa: el cajero, el interior del banco y la casa en seis estados (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Encargo de Luis pasado por Sistemas: «Que Pretil haga los modelados y tú los sistemas de juegos». Son tres cosas: los seis estados de la casa de la Calle de Alemania 5, un cajero modelado delante de cada banco y el interior visitable del Banco Cantabria.

- **Hecho: el cajero del Banco Cantabria** (`godot/scripts/bancosancho.gd`, `_cajero()`). Antes era un dibujo en la pared. Ahora es un cajero modelado en su marco rojo: la pantalla encendida («Bienvenido / Introduzca su tarjeta»), las teclas de los lados, la repisa del teclado, las ranuras de la tarjeta (con su luz verde), el recibo y los billetes, la visera roja con su luz y las pantallas laterales.
  - **Para Sistemas**: `G.world.bancosancho.cajero_spot` (dónde se pone el jugador, en el mapa, a 0,8 m de la pared), `cajero_face` (hacia dónde mira, como `out_h`) y `cajero_at` (la pantalla, en el mundo).
- **Hecho: el interior del Banco Cantabria** (`godot/scripts/banco_dentro.gd`, nuevo). Es un decorado aparte en (−1840, 1320), al que se entra por la flecha verde de la puerta de cristal, en horario del banco.
  - Una sucursal de pueblo, de 9 × 10 m, que no copia ninguna real: baldosa clara y paredes blancas con la banda roja del banco y su nombre al fondo.
  - A la izquierda, las sillas de espera, la mesa de folletos, el expositor y una planta.
  - Al fondo, el mostrador de caja tras su cristal, con dos puestos, los postes y la cinta roja de la cola, los archivadores y la puerta redonda de la cámara acorazada.
  - A la derecha, el rincón del encargado tras una mampara baja de cristal: su mesa con pantalla, papeles, teléfono y placa, su sillón, dos sillas para quien venga, el archivador y el calendario.
  - Sin personajes: al encargado lo pone Sistemas.
  - **Para Sistemas**: `G.world.bancosancho.banco`, con `manager_spot` y `manager_h` (dónde está el encargado y hacia dónde mira), `client_spot` y `client_h` (dónde se pone el jugador ante su mesa), `counter_front` (ante la caja) y `open` (lo mantiene `set_open`).
- **Hecho: las seis fachadas de la casa** (Calle de Alemania 5). Sistemas eligió el camino: seis fachadas como nodos aparte y solo una visible.
  - `godot/scripts/casa_fachada.gd` (nuevo): una fachada hecha a mano con el kit de `obra.gd`, según el estado.
    - 0, heredada: cal vieja desconchada hasta el adobe, puerta y portón de tablas grises, tejado con tramos caídos.
    - 1, arreglada: encalada, puerta y ventana verdes con reja, tejado entero, un farol y un geranio.
    - 2, primera ampliación: zócalo añil, huecos enmarcados en blanco (también el portón, ya de dos hojas).
    - 3, habitación a la izquierda: una ventanita con reja en ese extremo, un poyo junto a la puerta y otro farol.
    - 4, habitación a la derecha: otra ventana con reja, el portón pasa a ser puerta de garaje con marco de ladrillo y tejadillo, y aparece la cornisa de ladrillo bajo el alero.
    - 5, segunda planta: tres balcones con barandilla de hierro, la banda añil, la cornisa y una chimenea.
  - `godot/scripts/casa_fuera.gd` (nuevo): las seis juntas. Oculta las demás, les quita la colisión y da a las luces del pueblo solo los faroles de la visible.
  - **Para Sistemas**: `G.world.casa_fuera.set_state(n)` con n de 0 a 5; además `state`, `door`, `openings()` y `top()`.
  - La puerta de la calle no se mueve en ningún estado (a 2,14 m del extremo izquierdo, de 1,0 × 2,1): `HOME_DOOR`, la placa del Padrón, la flecha y la pintada de la peña siguen en su sitio.
  - El SPEC `alemania_5` se queda en `casas.gd`, porque `casa_dentro.gd` lo lee para situar la puerta.
- **Hecho: el interior de la casa en seis estados.**
  - `godot/scripts/casa_estado.gd` (nuevo): la casa por dentro tras cada obra (estados 1 a 5), cada una un interior entero.
    - 1, arreglada: la misma sala, con mesa y sillas, cortinas, una planta y lámpara.
    - 2, primera ampliación: la sala crece hacia la derecha (de 6 a 10 m), con cocina en la pared del fondo, comedor y aparador.
    - 3, habitación a la izquierda: un baño.
    - 4, habitación a la derecha: un salón con sofá, sillón, televisión y librería.
    - 5, segunda planta: una puerta al fondo, la escalera detrás y arriba un estudio con puertas a la terraza.
  - `godot/scripts/casa_dentro.gd` (de Sistemas, solo añadidos): la sala actual es el estado 0. `set_state(n)` oculta sus paredes y le quita la colisión, y muestra la casa del estado pedido.
  - La cama, el armario, la pintada sobre la cama, `bed_spot`, `wardrobe_spot`, `in_door` e `in_spawn` no cambian en ningún estado. Por eso la casa crece hacia la derecha y por puertas en las paredes.
  - La planta de arriba no está encima de la baja, sino más al fondo, subiendo su escalera: dos pisos no pueden compartir un punto del mapa (`MapData.decks`). Dentro del decorado no se nota.
  - **Para Sistemas**: `G.casa.set_state(n)`, `state`, `rooms()`, `room_at(pp)` (para la cámara de `entradas.gd`), y en el estado 5 `back_door` (ante la puerta del fondo, en la sala) y `back_spawn` (arriba, al final de la escalera). Se sube andando: no hace falta transporte.
- **Sin personajes** en ningún estado.
- **Azafrán escondido** (acuerdo con Sistemas): las flores de sitios especiales llevan `"id"` y `"hidden": true` en `G.flowers`. La del silo ya lo lleva (`"id": "silo"`).
- **Archivos**: `godot/scripts/bancosancho.gd` (el cajero, `BancoS`, `var banco`, y `banco.open` en `set_open`), `godot/scripts/banco_dentro.gd`, `godot/scripts/casa_fachada.gd`, `godot/scripts/casa_fuera.gd`, `tools/casa/hojas.py` y la clave del azafrán en `godot/scripts/silo_dentro.gd`.
  - Compartidos, con el aviso dado: `casas_calles.gd` (de Texturas: la línea `"alemania_5": ["obra"]`), `world.gd` (`CasaFueraS`, `var casa_fuera` y el paso «the house you inherit», tras el del silo), `casa_dentro.gd` (los añadidos de los estados) y `selftest.gd` (el modo `--casa`, y `_casa_fuera_checks()` y `_casa_dentro_checks()` en la prueba completa).
  - Nuevo también `godot/scripts/casa_estado.gd`.
  - Compartido, con el aviso dado a Sistemas: `entradas.gd`, una línea en `shops()` para `bancosancho.banco`.
- **Pruebas.** `python tools/run_tests.py bancosancho`: 5 ok, 0 fallos ([log](logs/selftest_bancosancho_20261121_133253.log)), ya con el interior del banco.
  - Antes daba 1 fallo ajeno al cajero: la prueba esperaba entrar en la copistería solo con pisar la flecha. Lo arregló Sistemas.
  - Después de esa prueba solo he bajado el brillo de los carteles del interior; no la he repetido.
  - La entrada al banco por la flecha no la he probado yo: la pasa Sistemas con `herencia`.
  - `python tools/run_tests.py casa`: 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_140527.log)), con fachadas e interior.
    - Un primer intento falló por el límite de mi propia comprobación: la puerta está a 1,54 m del punto `HOME_DOOR`, que es un sitio de la calle junto a ella, y pedía 1,5.
    - Otro no arrancó: había llamado `_shell` a una variable y ya existía una función con ese nombre en `casa_dentro.gd`.
  - `python tools/run_tests.py entradas`: 4 ok ([log](logs/selftest_entradas_20261121_141529.log)).
  - `python tools/run_tests.py padron`: 9 ok ([log](logs/selftest_padron_20261121_141814.log)): la placa con el nombre sigue sobre la puerta con la fachada hecha a mano.
  - `python tools/run_tests.py silo`: 6 ok ([log](logs/selftest_silo_20261121_134920.log)), con el azafrán ya marcado.
- **Hojas para Luis.** `guion/fotos/casa/01_fachadas.jpg` y `02_interiores.jpg` (`tools/casa/hojas.py`).
- **Fachadas aprobadas por Luis** («Las fachadas están increíbles»), con un cambio: faltaban plantas en la última.
  - Hecho en `casa_fachada.gd` (`_plants()`, `_climber()`, `_tuft()`, `_shrub()`), solo en el estado 5:
    - tres macetas de geranios colgadas por fuera de la barandilla de cada balcón, la del centro con una gitanilla que cae;
    - cuatro macetas colgadas en la pared, entre los balcones;
    - una fila de macetas al pie de la fachada, una sobre el poyo y dos macetones verdes;
    - tres macetas en cada alféizar en vez de una;
    - una buganvilla que sale de un macetón en el extremo derecho, sube hasta el alero y tiende un brazo sobre el garaje.
  - Ninguna planta es sólida ni cambia la puerta, los faroles o `openings()`.
  - En `selftest.gd`, una foto más en el modo `--casa`: `casa_5_plantas`.
  - `python tools/run_tests.py casa`: 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_142420.log)).
  - Hoja: `guion/fotos/casa/03_plantas.jpg`.
- **Capturas sueltas a petición de Luis**: `guion/fotos/casa/estados/fachada_N_*.jpg`, una por estado, de frente.
  - En `selftest.gd` (modo `--casa`), la vista de frente oculta a los vecinos y al jugador para que nadie tape la fachada; la vista desde la calle los deja.
  - `python tools/run_tests.py casa`: 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_142809.log)).
- **Segunda corrección de Luis a las fachadas**: «La cornisa de ladrillo añádela en la 4 y mantenla en la 5 mejor. Demasiadas flores en la 5. Quita la enredadera de la 5 y reduce un poco las flores».
  - La cornisa de ladrillo pasa de «desde el estado 2» a «desde el estado 4»: los estados 2 y 3 quedan con el alero de tejas sin más.
  - En el estado 5: fuera la buganvilla (`_climber()`, `_tuft()` y `_rnd()` borradas). Dos macetas colgadas por balcón en vez de tres y sin gitanilla, dos en la pared en vez de cuatro, una por alféizar en vez de tres, y cinco al pie de la fachada en vez de siete. Quedan el poyo con su maceta y los dos macetones verdes.
  - `python tools/run_tests.py casa`: 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_143252.log)).
  - Capturas y hojas rehechas (`guion/fotos/casa/`).
- **Tercera corrección de Luis**: «En las fotos que has pasado la cornisa de ladrillo del garaje aparece antes de la 4 y desaparece en la 4 y la 5. Quiero lo contrario».
  - Yo había entendido mal la anterior: Luis hablaba del marco de ladrillo con tejadillo del portón, no de la cornisa del alero.
  - Hecho en `casa_fachada.gd`: el portón de los estados 2 y 3 lleva marco blanco, como la puerta y la ventana; la puerta de garaje de los estados 4 y 5 lleva el marco de ladrillo con su tejadillo (antes llevaba el blanco).
  - Las dos macetas de la derecha y el macetón junto al garaje se apartan un poco para no pisar el ladrillo.
  - La cornisa del alero se queda como en la corrección anterior (desde el estado 4).
  - `python tools/run_tests.py casa`: 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_144321.log)).
  - Capturas y hojas rehechas.
- **Visto bueno de Luis a todo el encargo** (cajero, interior del banco, fachadas e interiores de la casa): «Quitando eso visto bueno a todo lo tuyo» y, minutos después, «Ahora sí, visto bueno».
  - Queda aprobado lo que muestran las últimas capturas enviadas: cornisa del alero desde el estado 4, ladrillo y tejadillo del garaje en los estados 4 y 5, y la fachada 5 sin enredadera.
  - Entre sus dos mensajes devolví la cornisa del alero al estado 2 (leí el primero como «eso no») y, al llegar el segundo, la restauré al estado 4 para que el juego coincida con las fotos aprobadas. Si Luis la quiere desde el estado 2 es una línea: `state >= 4` por `state >= 2` en `_front()`, donde dice «the eaves».
  - Prueba final: `python tools/run_tests.py casa`, 4 ok, 0 fallos ([log](logs/selftest_casa_20261121_145538.log)).
  - Sin commit: lo hace Sistemas con la 0.0.19.
- **Sin commit.**

### Silo del Tío Anaranjao (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Luis, tras aprobar el parque: «Pasamos al siguiente proyecto que es algo más complejo. […] el silo del tío colorao (que lo llamaremos silo del tío anaranjao). Aparte de la fachada quiero que se pueda visitar por dentro (hay varias fotos 360 por dentro), con sus muebles y utensilios de como vivía antes la gente bajo tierra en la mancha». Mandó el enlace de Google Maps y una captura del mapa. Las fotos no se guardan en el repositorio.

- **Hecho.** El Silo del Tío Colorao real (C. San Agustín 9), con el nombre de Luis. Detalle, planta y trampas en `referencias/silo/LEEME.md`.
  - **Fuera** (`godot/scripts/silo.gd`, sin horneado): la tapia blanca con albardilla de teja siguiendo la acera en curva, el portón claveteado, el cartel «SILO DEL TÍO ANARANJAO», cinco rejas, y dentro el patio de tierra con el caño visto desde arriba y dos chimeneas.
  - **Dentro** (`godot/scripts/silo_dentro.gd`, un decorado aparte en (1560, −1120) al que se entra por la flecha verde del portón): la bajada con escalones y rampa empedrada, el patio hundido, la cuadra, la leñera y dos viviendas. En total, nueve estancias con sus muebles y utensilios. Sin personajes.
- **La cámara.** Las estancias eran pequeñas y bajas, y la cámara de esquina quedaba pegada a la cabeza. La primera solución (quitar la tierra de encima y mirar desde arriba) no le gustó a Luis: ver la corrección de abajo.
- **Fuentes.** El recorrido virtual de 38 fotos 360 de 2019, las diez fotos del sitio, Street View de 2024 y la ortofoto. Herramientas nuevas en `tools/silo/` (`cerca360.py`, `tour360.py`, `baja360.py`, `hojas360.py`, `fotos.py`, `manzana.py`, `hojas.py`).
- **Archivos compartidos**, con el aviso dado a Sistemas y a Texturas:
  - `world.gd`: `SiloS`, `var silo` y el paso «the Silo del Tío Anaranjao» tras el parque del Paseo;
  - `entradas.gd`: `world.silo.dentro` en `shops()`, y `camera()` usa `place.room_at(pp)` si el decorado lo tiene (los demás decorados no cambian);
  - `selftest.gd`: el modo `--silo` y `_silo_checks()` en la prueba completa, tras `_paseo_checks`.
- **Pruebas.**
  - `python tools/run_tests.py silo`: 5 ok, 0 fallos ([log](logs/selftest_silo_20261121_125531.log)).
  - `python tools/run_tests.py entradas`: 4 ok, 0 fallos ([log](logs/selftest_entradas_20261121_125808.log)).
  - La prueba completa no se ha pasado.
  - El primer intento falló al entrar: sobre la flecha hay que pulsar el botón de acción. Ya está corregido en la prueba.
- **Hojas para Luis.** `guion/fotos/silo/01_fuera.jpg`, `02_bajada_patio_y_cuadra.jpg`, `03_primera_casa.jpg` y `04_segunda_casa.jpg`: las fotos reales al lado del juego.
- **Aprobado** por Luis el 21/11, con tres cambios ya hechos.
  - Sus palabras: «Visto bueno pero no me gusta que parezca que está al aire libre, podrías hacer la cueva un poco más profunda y colocar la cámara de tal manera que no se note que el modelo no tiene techo. También podrías dejar las puertas abiertas para que se vea un poco el modelo de la entrada desde fuera». Y después: «Deja el cable negro. Pero revisa las puertas, tienen una textura de suelo clippeada y las paredes interiores atraviesan las puertas».
  - **La cueva, más honda** (`silo_dentro.gd`): el patio queda 4,6 m bajo el corral (antes 2,8). Las estancias miden unos 4 m de alto, con bóveda, así que la cámara cuelga a 3,6 m por debajo del techo y solo ve paredes blancas. Ya no se quita ninguna tapa de tierra.
    - La bajada es ahora una escalera larga de 23 peldaños empedrados, sin rampa: con esa hondura la rampa salía demasiado empinada.
    - En la escalera la cámara baja detrás del jugador, unos peldaños más arriba (`room_at`).
    - El cable de las bombillas se queda negro.
  - **El portón, abierto** (`silo.gd`): las dos hojas abren hacia dentro y desde la calle se ve el rellano empedrado y los primeros peldaños, que se van oscureciendo. No se cruza andando: se entra por la flecha.
  - **El arreglo del portón**: el caño de fuera iba torcido (con el rumbo del real) y nivelado a la cota más alta del patio, así que el suelo y los muretes atravesaban las hojas. Ahora sale recto del portón, es más ancho que él y va pegado al terreno tramo a tramo.
  - **Pruebas**: `python tools/run_tests.py silo`, 5 ok y 0 fallos ([log](logs/selftest_silo_20261121_132656.log)). Hojas rehechas.
- **Cerrado** por Luis el 21/11: «El silo está perfecto. Añade un azafrán en una de las habitaciones pequeñas y lo damos por cerrado. (Pasale a sistemas que sería buena idea esconder azafrán en ubicaciones especiales)».
  - **El azafrán** (`silo_dentro.gd`, `_saffron`): una flor de azafrán en una macetita de barro, junto a la pared de la última alcoba (la de la cama azul, al fondo de la segunda casa). Es el coleccionable del juego, igual que los de las calles: al acercarse se recoge (+1 azafrán, +6 €). La maceta se queda.
    - El decorado la añade él mismo a `G.flowers` (`{"node", "p"}`), sin tocar `game.gd`. Su sitio queda en `silo.dentro.saffron_spot`.
    - Como las demás flores, vuelve a estar ahí cada vez que se arranca el juego.
  - **Idea de Luis pasada a Sistemas**: esconder azafrán en ubicaciones especiales.
  - **Pruebas**: `python tools/run_tests.py silo`, 6 ok y 0 fallos ([log](logs/selftest_silo_20261121_133743.log)); la comprobación nueva recoge la flor.
- **Sin commit.**

### Parque del Paseo del Cristo (21/11)

21 de noviembre de 2026, Edificios Especiales (Claude · Pretil). Luis, tras aprobar la Residencia: «Visto bueno. Podemos continuar con el parque largo empedrado que hay al lado del paseo del cristo (tiene su propia linea en street view, sin nombre)». Mandó una foto de noviembre de 2024 de la esquina oeste y el mapa con la flecha. Las capturas no se guardan en el repositorio.

- **Hecho.** `godot/scripts/paseo.gd`, sobre `obra.gd`. Es el «Parque del Paseo del Cristo» del mapa: unos 165 m desde la esquina de la Calle de las Viñas y la Calle de los Arcos hasta la placita de la ermita.
  - **El paseo central**: baldosa clara de 40 cm con un cuadro rojo en marco rojo cada 15 m. Apunta a la puerta de la ermita (a 0,01 m). A cada lado, una banda de losas de pizarra irregulares (`tools/paseo/losas.py` → `godot/assets/paseo/losas.png`).
  - **Los céspedes** con bordillo, y la acera ajedrezada roja y crema a lo largo del Paseo.
  - **Al oeste**:
    - la plaza de ladrillo, con la prensa de piedra (ver la corrección de abajo);
    - el seto de boj ante la casa de los arcos;
    - el parterre de cipreses con su verjita, el álamo y la farola alta;
    - el monolito con su banco de granito y su pilón, y la mesa de piedra con su asiento redondo.
  - **Al norte**: la tapia blanca de los huertos, con su albardilla de teja. Después, el murete de mampostería con pilares de ladrillo y verja, ante los patios y el callejón. La fuente de rocalla, entre el sauce llorón y una palmera.
  - **La plaza de losas del cruce**, con faroles de dos brazos. Al este, las losas alrededor del calvario (el de `cristoprado.gd`), los bancos de granito y los bolardos ante la placita.
  - **Lo demás**:
    - 33 árboles donde la ortofoto tiene sus copas: plátanos encalados, olmos y olmos trasmochos, álamos, la acacia, el sauce y una palmera;
    - bancos de hierro;
    - 22 faroles que se encienden con los del pueblo (`W.lamp_spots`);
    - papeleras y bolardos, como mobiliario que se puede tumbar (`W.extra_props`).
- **Sin horneado.**
  - Se tiende sobre el suelo, el césped y la senda del mapa, y se corta por el borde del asfalto tal como lo pone el juego: cada tramo de calle es una cápsula de su ancho ajustado, y las sendas peatonales no cuentan.
  - Los bordes se leen al cargar: el asfalto del Paseo al sur; la tapia, la verja, el callejón o las casas al norte.
  - Los 13 árboles del mapa que caían dentro se quitan con `W.fell_tree`.
- **Trampas.**
  - El Paseo del juego está unos 4 m metido en el parque real, así que el césped sur queda más estrecho.
  - La línea propia de Street View del parque es solo de marzo de 2013. En 2024 solo hay fotos desde el coche.
  - La tapia blanca no está en el mapa: la levanta el parque.
  - El asfalto de la esquina de la Calle de los Arcos pasa a 2,5 m del parterre de cipreses, que se corre hacia el este hasta quedar libre.
- **La casa de los arcos** (la de la foto de Luis, en la esquina norte) sigue siendo la casa genérica del horneado: no forma parte del parque.
- **Fuentes.** Street View (las cámaras están en `tools/paseo/capturas.py`), la ortofoto `tools/ign/paseo_cristo.jpg` y la foto de Luis. Notas en `referencias/paseo/LEEME.md`.
- **Archivos compartidos**, con el aviso dado a Sistemas:
  - `world.gd`: `PaseoS`, `var paseo` y el paso «the park of the Paseo del Cristo» detrás de la Residencia;
  - `selftest.gd`: el modo `--paseo` y `_paseo_checks()` en la prueba completa, tras `_residencia_checks`.
- **Pruebas.** `python tools/run_tests.py paseo`: 3 ok, 0 fallos ([log](logs/selftest_paseo_20261121_081505.log)).
  - El primer intento contaba las sendas peatonales como calles, y el borde del Paseo salía en la senda central. Ya está corregido.
- **Hojas.** `guion/fotos/paseo/01_street_view_y_juego.jpg` (13 puntos de Street View al lado del juego) y `02_en_el_juego.jpg` (la foto de Luis al lado del juego, y el parque).
- **Commit** `ad86143` de Sistemas (sin push), con la ermita y la Residencia.
- **Corrección: las piezas de piedra (21/11, mañana).**
  - Luis mandó cuatro capturas de Street View de marzo de 2013, de la línea propia del parque: «Faltan varias cosas. La prensa de piedra, el monolito de piedra, la mesa de piedra, la fuente». Las capturas no se guardan en el repositorio.
  - **Todo en `paseo.gd`**, con piezas nuevas del kit: `_lump` (una piedra tosca de caras planas, con ruido fijo), `_arc` (un murete curvo con albardilla) y `_arc_solids`.
    - **La prensa** (`_press`), en la esquina ante la casa de los arcos. Lleva un zócalo redondo de mampostería con albardilla, la solera, tres rulos cónicos de granito con la chapa de hierro del ojo y su churrete de óxido, el eje de hierro, los brazos y el aro. Uno de los rulos mira a la casa, como en la foto. Sustituye a la muela de pie y el cono de 2024.
    - **El monolito** (`_monolith`): una piedra alta y tosca de unos 2,1 m, ancha al pie y con una mancha de pintura roja. A su lado, un banco largo de granito al borde del paseo y un pilón de piedra con matas secas. Sustituye a la piedra y al tronco tallado.
    - **La mesa de piedra** (`_mesa`): un asiento redondo de mampostería con albardilla, abierto al este y al oeste, con respaldo en la mitad sur y la mesa redonda sobre su pie en medio. Sustituye a la jardinera redonda.
    - **La fuente de rocalla** (`_fountain`). Lleva el estanque de agua limpia (como la que Luis quiso para la plaza), el murete de toba, ocho pilares de toba con maceteros blancos y sus plantas, cadenas colgadas entre ellos, el montículo en medio con la estatua y losas alrededor hasta la banda del paseo. Sustituye a la rocalla de piedras sueltas.
    - **La estatua** (`_statue`). Luis, al ver la hoja: «Muchísimo mejor. Solo cambiaría que la estatua de la fuente es de una mujer desnuda con un jarrón de donde sale el agua que cae a la fuente».
      - Primero se hizo de piedra blanca, como en Street View (p14_n, 2013): una mujer desnuda de pie, con la cabeza inclinada hacia el cántaro que lleva al hombro izquierdo.
      - Luis, después: «vamos a sustituirlo por una figura de mármol de una mujer al estilo de nuestros personajes. Igual que con la estatua de bronce del fraile».
      - **Ahora es una figura del juego** (`chara.gd`), como el fraile de `santaana.gd`, pasada entera a mármol blanco: una mujer con moño, pestañas y nada de ropa, a 0,55 de tamaño (cerca de 1 m).
      - Tiene la cabeza un poco inclinada hacia el cántaro, que lleva al hombro izquierdo con esa mano; la otra mano la tiene delante. El nodo es `paseo.statue`.
      - Del cántaro cae un hilo de agua, que corre pegado a la rocalla hasta el estanque. Se hace con `_limb`, una pieza redonda de un punto a otro.
      - `chara.gd` no pasa la comprobación de sintaxis suelta (le falta MapData), así que se ha probado en el juego.
  - **Trampa de la fuente**: el callejón del norte pasa en el juego unos 2 m más al sur que el real, y la fuente no cabía. Ahora se coloca sola entre el borde norte tal como lo pone el juego y el paseo, y encoge si hace falta: queda con 2,08 m de radio exterior en lugar de 2,25.
    - El sauce pasa a (125,0, −8,4) y la palmera nueva queda en (131,2, −8,5), a cada lado.
    - Se quitan el banco norte de x = 127 y una papelera, que caían encima.
  - **Archivos**: `godot/scripts/paseo.gd` y `tools/paseo/hojas.py`, con la hoja 03 (`piezas=`, las cuatro fotos al lado del juego). Ningún archivo compartido.
  - **Pruebas**: `python tools/run_tests.py paseo`, 3 ok y 0 fallos ([log](logs/selftest_paseo_20261121_120228.log), ya con la figura de mármol), sin errores de formato en el registro.
    - En el primer intento el monolito salió negro: los materiales nuevos no habían entrado en `_material`. Ya está corregido.
    - Las vistas se llaman `ps_*`: con `pz_*` se leen en el marco de la plaza.
  - **Hojas**: `guion/fotos/paseo/03_piezas_de_piedra.jpg`, nueva, con la estatua de cerca al lado de Street View; `01` y `02`, rehechas.
- **Aprobado** por Luis el 21/11 («Visto bueno»), con las piezas de piedra y la figura de mármol. Las piezas y la figura, sin commit.

### Calle de las Viñas: 44 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). Es la siguiente calle del núcleo, a la orden del usuario («Visto bueno y siguiente»).

- **Hecho.** 44 casas con su frente en las Viñas (`vin_*`), descritas con las fotos del Catastro y doce con Street View. Lo que queda fuera y por qué está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd`: 44 entradas nuevas.
  - `godot/data/map.json`: horneado.
  - Las carpetas del Catastro `tools/casas/<ref>/`.
  - Las hojas `guion/fotos/tanda34/vinas_1..8.jpg`.
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado dos veces sobre el mapa de Edificios Especiales de las 02:25, con el Cristo del Prado y la Residencia, avisándole antes y después de cada vez.
  - La segunda vez fue para quitar `vin_bv12`, `vin_bv11` y `vin_ja8`, cuyas fachadas quedaban detrás de otras.
  - Comparado con la copia de antes: 44 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve y árboles (2954) siguen igual.
  - La holgura de 21 nodos junto a las casas nuevas baja unos 0,7 m; la menor queda en 3,7 m.
  - Ninguna casa tiene partes por delante de su frente.
- **Lección.** Además de las partes por delante, conviene buscar fachadas paralelas en el mismo lado de la calle a menos de unos 9 m una de otra. La de detrás no se ve desde la calle, y en la hoja la cámara queda dentro de la de delante.
- **Pruebas.**
  - `casas solo=vin_`: el primer intento falló porque `vin_rs67` no llegaba a 12 piezas.
  - Con la celosía de su foto, `solo=vin_rs67` dio 4 ok.
  - Tras los arreglos, `solo=vin_rs71,vin_x2,vin_12,vin_x4,vin_bv14,vin_4b,vin_4` dio 4 ok, 0 fallos ([log](logs/selftest_casas_solo_vin_rs71_vin_x2_vin_12_vin_x4_vin_bv14_vin_4b_vin_20261121_023910.log)).
- **Aprobada** por el usuario el 21/11 («Visto bueno y siguiente»). En el commit `ad86143` (Sistemas, 21/11, sin push).

### Calle del Florido, tramo norte: 29 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). Es la siguiente calle del núcleo, a la orden del usuario («Visto bueno y siguiente», tras aprobar las Viñas). La calle es larga (unas 84 casas, más 20 en la Bajada del Florido) y va en tres tandas; esta es la primera, de los Silos a la Bajada.

- **Hecho.** 29 casas con su frente en el Florido (`flo_*`), descritas con las fotos del Catastro y doce con Street View de noviembre de 2024. Lo que queda fuera y por qué está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos puestos a mano** (en `tools/casas/calles.json`):
  - `flo_68`: frente por la pared de delante, sobre el hueco de la escalera de fuera.
  - `flo_50` y `flo_50g`: una misma referencia partida por plantas con `only`: la parte de una planta y la de dos, cada una con su trozo de frente.
  - `flo_b10`: el trozo de una planta (`only` 1) de Bajada del Florido 10, su portón a esta calle.
  - `flo_62`: la tapia del patio, sin referencia (`rc` null, 0,9 m de fondo), porque el Catastro da el patio sin plantas.
  - Los Ángeles 1 queda fuera: su cara a esta calle está detrás de la casa de la esquina.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd`: 29 entradas nuevas.
  - `godot/data/map.json`: horneado.
  - Las carpetas del Catastro `tools/casas/<ref>/`.
  - Las hojas `guion/fotos/tanda34/florido_1..5.jpg`.
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el mapa de las 02:39 (el de las Viñas), avisando a Edificios Especiales antes y después.
  - Comparado con la copia de antes: 29 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve y árboles (2954) siguen igual; la holgura de un nodo baja de 4,9 a 3,5 m.
  - Antes de hornear se comprobó que ninguna casa tiene partes por delante de su frente ni fachadas paralelas escondidas detrás de otras (`precheck.py` en el scratchpad, sobre los anillos de `datos.json`).
- **Pruebas.**
  - `casas solo=flo_`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_flo__20261121_053430.log)).
  - Tras los arreglos de la comparación, `solo=flo_65,flo_66,flo_60,flo_58,flo_an15,flo_b10,flo_50,flo_50g,flo_48,flo_49` dio 4 ok, 0 fallos. El primer intento paró en un error de compilación de `residencia.gd`, que Edificios Especiales estaba editando; al terminar él, pasó.
  - `solo=flo_48`, con el friso en ladrillo oscuro: 4 ok ([log](logs/selftest_casas_solo_flo_48_20261121_054237.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En el mensaje de las hojas lo llamé «tramo sur» por error; es el extremo norte de la calle (en el mapa, z negativa es el norte). En el commit `ad86143` (Sistemas, 21/11, sin push).

### Calle del Florido, tramo medio, y Bajada del Florido: 34 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). Segunda de las tres tandas del Florido, a la orden del usuario («Visto bueno y siguiente», tras aprobar el tramo norte).

- **Hecho.** 18 casas del Florido entre la Bajada y el 21 y el 26 (`flo_*`) y 16 de la Bajada del Florido (`bfl_*`). Fotos del Catastro, y ocho con Street View de noviembre de 2024. Lo que queda fuera y por qué está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - `bfl_10` lleva `only` 2; su parte de una planta es `flo_b10`, del tramo norte.
  - Monjas 65 y 63 quedan fuera: sus frentes a la Bajada están de 4 a 7 m detrás de `bfl_2` y `bfl_1`, en el mismo lado.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (34 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/florido_medio_1..6.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 05:34 (el del tramo norte), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 34 casas nuevas, ninguna quitada. `flo_50g` cambia solo en qué aristas quedan tapadas por la casa nueva de al lado. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: ninguna parte por delante; las únicas fachadas escondidas eran las de Monjas 65 y 63, que se quitaron.
- **Pruebas.**
  - `casas` de las 34: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_flo_41_flo_46_flo_39_flo_34_flo_37_flo_32_flo_35__20261121_055758.log)).
  - Tras los arreglos, `solo=flo_27,flo_23,flo_26,bfl_21,bfl_23`: 4 ok ([log](logs/selftest_casas_solo_flo_27_flo_23_flo_26_bfl_21_bfl_23_20261121_060251.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En el commit `ad86143` (Sistemas, 21/11, sin push).

### Calle del Florido, tramo sur, y Prolongación del Florido: 39 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). Última de las tres tandas del Florido, a la orden del usuario («Visto bueno y siguiente», tras aprobar el tramo medio y la Bajada).

- **Hecho.** 18 entradas del tramo sur del Florido (del 24 y el 15 hasta el final, con el 1 A y el 1 B) y 21 de la Prolongación (`flo_p*`), todas `flo_*`. Fotos del Catastro, y Street View de 2024 (2026 en la Bajada del Rollo) en las casas sin foto, cambiadas o dudosas. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - `only` para partir dos referencias: `flo_x2`/`flo_x2g` (3692606, bloque de tres plantas y almacén con `reach` 6, para que sus naves de la calle de la Vega queden normales) y `flo_x3`/`flo_x3t` (3692608, bloque y tapia de bloques).
  - Pareadas impares de la Prolongación: `house_street` cogía la cara inclinada del porche (4 m). El frente va ahora paralelo a la calle en la cara del cuerpo de dos plantas, a todo lo ancho, con `floors` 2 y `strip` 2.5 para quitar el porche (lo calcula `sur_write.py` en el scratchpad).
  - Bajada del Rollo 4 (3692302) está derribada según Street View de 2026. No hay forma de dejar un solar sin tocar `bake_godot.py`, así que queda la casa genérica; está apuntado.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (39 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/florido_sur_1..7.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 05:57 (el del tramo medio), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 39 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: ni partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 39: 3 ok, 1 fallo, porque `flo_x3t` tenía pocas piezas ([log](logs/selftest_casas_solo_flo_24_flo_15_flo_x4_flo_13_flo_11_flo_9_flo_22_f_20261121_075137.log)).
  - Con más hiladas, `solo=flo_x3t`: 4 ok ([log](logs/selftest_casas_solo_flo_x3t_20261121_075422.log)).
  - Tras los cambios de color: 4 ok ([log](logs/selftest_casas_solo_flo_x2_flo_p13_flo_p15_flo_p14_flo_p16_flo_p18_fl_20261121_075654.log)) y 4 ok ([log](logs/selftest_casas_solo_flo_p14_flo_p16_flo_p18_flo_p20_flo_p22_flo_p24_f_20261121_075815.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y seguimos»). En el commit `ad86143` (Sistemas, 21/11, sin push). La Bajada del Rollo 4 sigue genérica.

### Commit del Cristo del Prado, la Residencia, el Paseo, el suelo y las casas del Florido (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Cuando terminen sus dos trabajos actuales haz commit».
- Los trabajos son el parque del Paseo de Pretil y lo que tenía Texturas.
- Prueba completa: 886 ok, 1 fallo. El fallo era solo el mínimo de fachadas de «houses meet their street»: pedía más de 5000 y quedan 4807, porque las casas hechas a mano sustituyen a las genéricas.
- Los límites de verdad pasan: 6 fachadas raras, la peor 2,4 m por encima y 0,1 m por debajo.
- El mínimo baja a 4000 en `selftest.gd`, con una nota.
- Commit `ad86143`, sin push.
- Queda: el tramo sur del Florido, a la espera del visto bueno del usuario. Y unos errores del motor al cargar: `set_uv` en `obra.gd` desde `cristoprado.gd` `_calvario`, el tejado. No hacen fallar la prueba; se lo he pasado a Pretil.

### Calle de la Rosa del Salvador: 35 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y seguimos», tras aprobar el tramo sur del Florido).

- **Hecho.** 35 entradas `rsa_*`. Fotos del Catastro (2019), y Street View de noviembre de 2024 (el 24, de 2013) donde no había foto, la foto era de otra fachada o la casa ha cambiado. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - Lado par del 20 al final: la calle del mapa va 3–4 m al sur de la real. Frentes de la pared genérica (`frente_gen.py`) con `clear` 6; el 4 y el 6 también (su frente del Catastro era una pared interior), con `clear` 3.
  - Cajas a mano (`rc: null`): `rsa_9` y `rsa_18` (0 plantas en el Catastro: eran un hueco en el juego), `rsa_10g` (la parte de 0 plantas de la trasera de Sevilla 7) y `rsa_34` (el cobertizo; la parcela de Sevilla 27 queda bajo la calle).
  - Traseras con `reach`: `rsa_s7`, `rsa_s9` (8 m), `rsa_24`, `rsa_44` (6 m) y `rsa_36` (8 m); `rsa_1` lleva `reach` 6 para dejar su bloque de tres plantas del fondo.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (35 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/rosa_salvador_1..6.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 07:51 (el del Florido sur), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 35 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve, árboles (2954) iguales. Solo la holgura del nodo 310 (Rosa del Salvador) pasa de 2,3 a 2,1 m.
  - `precheck.py` antes de hornear: sin fachadas escondidas; partes por delante solo en las de `clear`.
- **Pruebas.**
  - `casas` de las 35: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_rsa_1_rsa_3_rsa_5_rsa_7_rsa_9_rsa_11_rsa_13_rsa_1_20261121_113502.log)).
  - Tras arreglar puertas y tonos, `solo=rsa_1,rsa_4,rsa_6,rsa_15,rsa_21,rsa_32`: 4 ok ([log](logs/selftest_casas_solo_rsa_1_rsa_4_rsa_6_rsa_15_rsa_21_rsa_32_20261121_113959.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y continuar»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle de Sevilla: 36 casas, y `house_of` con `reach` en el horneado (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y continuar», tras aprobar la Rosa del Salvador).

- **Hecho.** 36 entradas `sev_*`. Fotos del Catastro, y Street View de noviembre de 2024 donde no había foto, la foto era de otra fachada o la casa ha cambiado. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Cambio en `tools/bake_godot.py`.**
  - `house_of(bid, floors, p)` salta una entrada cuyo `reach` deja fuera la parte `p` y prueba la siguiente con la misma referencia.
  - Motivo: cuatro parcelas pasantes (Sevilla 7, 9, 19 y 29) ya tenían su trasera en la Rosa (`rsa_s7`, `rsa_s9`, `rsa_24`, `rsa_36`, con `reach`). Antes, la primera entrada era la única que contaba, y la fachada de Sevilla se quedaba genérica.
  - Las referencias con una sola entrada hornean igual: el horneado no quitó ni movió ninguna casa.
- **Archivos.** `tools/bake_godot.py`, `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (36 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/sevilla_1..6.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 11:34 (el de la Rosa), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 36 casas nuevas, ninguna quitada. `rsa_6`, `rsa_8`, `rsa_s7` y `rsa_36` cambian solo en qué aristas quedan tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 36 y las cuatro de la Rosa: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_sev_3_sev_5_sev_7_sev_9_sev_11_sev_13_sev_15_sev__20261121_120325.log)).
  - Tras arreglar los tonos del 13 y del 22, `solo=sev_13,sev_22`: 4 ok ([log](logs/selftest_casas_solo_sev_13_sev_22_20261121_120630.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Las cámaras de las giras de la Chiki y de Alberto (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «La cámara de la Chiki cuando te enseña los grafitis y la de Alberto cuando enseña el pueblo muchas veces acaba clippeada entre edificios y no se ve el objetivo».

- **Por qué pasaba.** Las dos ponían la cámara a una distancia fija de la calle más cercana.
  - La Chiki, a 7 m de la pared hacia fuera. En una calle estrecha eso cae dentro de la casa de enfrente: con los sitios viejos, 22 de las 60 paredes no se veían.
  - Alberto, a 7 m a lo largo de la calle. En una curva o al final de la calle eso cae en una casa.
- **El arreglo.** Una función nueva en `game.gd`: `scene_shot(at, want_a, want_b)`, con `_shot_turned`, `_shot_clear`, `_shot_room` y `_shot_open`.
  - Mira con rayos de la capa 1 (las paredes) desde el objetivo hacia cada punto, y deja la cámara 0,6 m antes de la primera pared.
  - Prefiere de frente y más cerca, siempre que conserve al menos el 45 % de la distancia, antes que girada de lado.
  - Si no, prueba a girarla poco a poco (±0,4, ±0,8, ±1,2 rad) y a subirla 3 m.
  - La separa de una pared que tenga pegada al lado.
  - Comprueba que el paso de un punto al otro no cruce ninguna esquina.
- **Dónde se usa.**
  - `pintadas.gd`: `tour_shot(t)`, que apunta al propio grafiti y sale según la cara de la pared (`t.n`).
  - `recress.gd`: `_sad_corners()` y el paso por la puerta del Recress en `_pitch`.
- **Prueba.**
  - `selftest.gd`: `_tour_camera_checks()`, al principio de `_pintadas_checks`, así que entra en la prueba completa.
  - Las 60 paredes se ven desde los dos extremos del paso, de frente (a menos de 63°), a 2,5 m o más y sin nada en medio. Los 5 rincones de Alberto, igual.
  - Con `--shots` saca las fotos `gira_chiki_N_antes/ahora` y `gira_alberto_N`.
  - `run_tests.py pintadas --headless`: 7 ok. `pintadas shots --window`: 7 ok, y las fotos están revisadas. `recress --headless`: 16 ok.
  - Sin commit.

### Calle del Cristo, de la Mayordomía a la Travesía del Cristo: 32 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar la calle de Sevilla).

- **Hecho.** 32 entradas `cri_*`. Fotos del Catastro, y Street View de noviembre de 2024 donde no había foto, la foto era de otra casa o la casa ha cambiado. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - Fuera:
    - el 3 (4790711): es la nave de la Mayordomía, hecha a mano (`MERKOCARRY_RCS` en `bake_godot.py`);
    - Paz 1 y Doctor Fleming 22: dan a sus calles;
    - nada al sur de la Travesía del Cristo, donde empiezan el parque, la ermita y la Residencia de Edificios Especiales.
  - Las fotos del Catastro del 35 y del 45 son de otras casas. Se han seguido las placas de Street View.
  - Las tiendas llevan solo lo que venden (PASTELERIA, ELECTRICIDAD).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (32 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/cristo_1..6.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 12:03 (el de Sevilla), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 32 casas nuevas, ninguna quitada. `argentina_42` y `argentina_b029` cambian solo en las aristas tapadas.
  - Calles, nodos, relieve y árboles (2954) iguales. La holgura del nodo 225 (cruce del Cristo con la Cruz) pasa de 4,7 a 4,2 m.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 32 y las dos de Argentina: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_cri_5_cri_7_cri_9_cri_x11_cri_13_cri_15_cri_15d_c_20261121_122321.log)).
  - Tras aclarar el amarillo, `solo=cri_x11`: 4 ok ([log](logs/selftest_casas_solo_cri_x11_20261121_122612.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle del Doctor Fleming: 24 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar la calle del Cristo). Elegida con `faltan.py`: la calle cercana con más fachada genérica sin tocar (319 m), al sur de Sevilla.

- **Hecho.** 24 entradas `fle_*`. Fotos del Catastro (viejas, hacia 2010), y Street View de noviembre de 2024 en casi toda la calle. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - `fle_23`: la tapia de una planta de la trasera de Sevilla 34; `sev_34` ya tomaba solo las partes de dos plantas, así que no se pisan.
  - `fle_6`: la tapia con portón de Paseo del Cristo 1 (`reach` 6).
  - Fuera: Paseo del Cristo 2 y 48, que dan al Paseo, junto al parque de Edificios Especiales.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (24 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/fleming_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 12:23 (el del Cristo), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 24 casas nuevas, ninguna quitada. `sev_26` y `sev_28` cambian solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 24 y las dos de Sevilla: 3 ok, 1 fallo, porque `fle_25` tenía pocas piezas ([log](logs/selftest_casas_solo_fle_1_fle_3_fle_5_fle_7_fle_9_fle_11_fle_13_fle_1_20261121_124038.log)).
  - Con más parches y una hilada de albardilla, `solo=fle_25`: 4 ok ([log](logs/selftest_casas_solo_fle_25_20261121_124336.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle de la Vega: 16 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar Doctor Fleming). Elegida con `faltan.py` (257 m de fachada genérica), junto al Florido y lejos del silo que está haciendo Edificios Especiales.

- **Hecho.** 16 entradas `veg_*`. Fotos del Catastro y Street View de noviembre de 2024 en toda la calle. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.**
  - Las hileras de adosadas del lado sur (`veg_x1`, `veg_x3`: cuatro casas; `veg_x5`, `veg_x7`: dos) son una parcela cada una. `veg_write.py` (scratchpad, `row()`) pinta cada casa con garaje, escalera (`esc`) y su color con `paño`.
  - `veg_6` lleva `floors` 1: su cuerpo de tres plantas llega a la calle y las tiras de una planta de delante entran en el mismo frente.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (16 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/vega_1..3.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 12:40 (el de Fleming), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 16 casas nuevas, ninguna quitada. `sap_19` cambia solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 16 y `sap_19`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_veg_x1_veg_x3_veg_x5_veg_x7_veg_3d_veg_sap25_veg__20261121_125239.log)).
  - Tras bajar los ventanucos, `solo=veg_3d`: 4 ok ([log](logs/selftest_casas_solo_veg_3d_20261121_125440.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y continuar»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle de los Ángeles: 17 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y continuar», tras aprobar la Vega). Elegida con `faltan.py` (246 m de fachada genérica).

- **Hecho.** 17 entradas `ang_*`. Fotos del Catastro, y Street View de noviembre de 2024 en la mitad de la calle. Lo que queda fuera está en `PROJECT_STATE.md`; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - `ang_19`: frente de la pared genérica; el del Catastro es un muro 7 m más adentro.
  - `ang_25`: frente recortado a su casilla (6 m de 22); lo demás es una tapia de patio sin edificio.
  - Entran tres esquinas de otras calles (`ang_tol1`, `ang_vp1`, `ang_bf25`). Bajada del Florido 25 quedó fuera de la Bajada porque no tiene fachada allí.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (17 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/angeles_1..3.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 12:52 (el de la Vega), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 17 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve y árboles (2954) iguales. La holgura del nodo 1491 pasa de 2,3 a 2,2 m.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - El primer intento de `casas` paró en el arranque, por un error de sintaxis en `fondo_casa.gd:256` (archivo nuevo de Sistemas, a medio escribir; avisado). No se tocó.
  - A las 13:10, ya corregido, `casas` de las 17: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_ang_tol1_ang_2_ang_4_ang_8_ang_10_ang_x12_ang_vp1_20261121_131024.log)).
- **Visto bueno** del usuario el 21/11 («Visto bueno y siguiente cuando puedas»), antes de ver las hojas, que se le mandaron después. En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle de la Virgen de la Paloma: 20 entradas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente cuando puedas»). Elegida con `faltan.py` (241 m de fachada genérica), junto a Los Ángeles.

- **Hecho.** 20 entradas `vpa_*` (18 parcelas). Fotos del Catastro (2010–2015) y Street View de noviembre de 2024 en la mitad de la calle. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.** Dos parcelas con `only`: `vpa_x18` (3 plantas; la de 4 retranqueada queda como bloque normal) con `vpa_x18g` (1 planta), y `vpa_20` (2) con `vpa_20g` (1). Las esquinas `vpa_tol17` (Camino de Toledo 17) y la de Los Ángeles (`ang_vp1`, ya hecha) dan a esta calle.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (20 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/paloma_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 13:07 (el de Los Ángeles), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 20 entradas nuevas, ninguna quitada. `ang_vp1` cambia solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 20 y `ang_vp1`: 3 ok, 1 fallo, porque `vpa_3` tenía pocas piezas ([log](logs/selftest_casas_solo_vpa_3_vpa_5_vpa_9_vpa_11_vpa_13_vpa_x15_vpa_19_vp_20261121_131744.log)).
  - Con una hilada de albardilla más, `solo=vpa_3`: 4 ok ([log](logs/selftest_casas_solo_vpa_3_20261121_131931.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle de Pizarro: 16 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar la Virgen de la Paloma). Elegida con `faltan.py` (197 m de fachada genérica), entre Los Ángeles y la Virgen de la Paloma.

- **Hecho.** 16 entradas `piz_*`. Fotos del Catastro y Street View de noviembre de 2024 en la mitad de la calle. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.** Los frentes del lado impar quedan 6 m del eje de la calle (2,5 m más que los del par), pero el juego ya tenía allí sus paredes genéricas: se han dejado los del Catastro. Tres costados de otras calles entran (`piz_an16b`, `piz_va1`, `piz_va8`).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (16 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/pizarro_1..3.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 13:17 (el de la Virgen de la Paloma), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 16 casas nuevas, ninguna quitada. `vpa_13` cambia solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 16 y `vpa_13`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_piz_an16b_piz_3_piz_5a_piz_5d_piz_7_piz_x9_piz_va_20261121_133113.log)).
  - Tras apagar el ocre, `solo=piz_13`: 4 ok ([log](logs/selftest_casas_solo_piz_13_20261121_133308.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y seguimos»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Misiones de fondo (la casa de la Eufrasia, Edmundo Monedero, cajero) y Trabajos (21/11, Claude · Sistemas)

21 de noviembre de 2026. Lo pidió el usuario. Los modelados los hace Pretil; los sistemas, Sistemas.

**Misiones «de fondo».** Van a la vez que el resto del juego: no usan `G.side` ni el objetivo de la hoja. Están en la Agenda, en una página 3 nueva, «MISIONES DE FONDO» (`log_bg`). Ahora la Agenda tiene 7 páginas y 7 pestañas, más juntas (`menu.gd`). En esa página van:
- la casa;
- las pintadas de la Chiki, que salen de la página de encargos y cuentan «tuyas N de 60»;
- el azafrán.

**La casa** (`fondo_casa.gd`, nuevo):
- **La llamada de la Paca.** 2 h de juego después de abrir el puente te llama la Paca: «ven a verme, ande siempre, al lao de casa».
- **La deuda.** Allí te cuenta que la Eufrasia defraudaba a Hacienda y que la casa tiene una carga de **10.000 €**.
  - El usuario escribió «tía Eusebia», pero en el juego la tía de la herencia es la **Eufrasia** (loc `paca_cutscene`), así que se queda Eufrasia. Hay que confirmárselo.
- **El cajero.** Se paga a plazos en el cajero del Banco Cantabria: 100, 500, 1.000 o «To lo que llevo». Lo que no te llega sale en gris.
  - El cajero es el modelado de Pretil: `bancosancho.cajero_spot`, `cajero_face` y `cajero_at`.
- **Edmundo Monedero.** Cuando la deuda está pagada, te llama en un cuarto de hora. Es el director de sucursal, «usurero tipo Tom Nook»: vende productos y suelta verdades por lo bajini, con `((…))` en gris.
  - Dónde está:
    - De lunes a viernes, de 8:30 a 14:30, en la puerta del banco.
    - Cuando Pretil haga el interior, dentro: `bancosancho.banco.manager_spot` y `manager_h`.
  - Aspecto provisional: hombre adulto, camisa con cuello azul oscuro (top 11), corbata (pendant 6), gafas y piel pálida. No hay ninguna chaqueta de traje entre las prendas.
- **Las obras.**
  - Se contratan con Edmundo, y cada una tiene que estar pagada antes de que te ofrezca la siguiente.
  - Están hechas a la mañana siguiente, a partir de las 7. Lo que cuestan se debe al banco y se paga en el cajero.
  - Estados, con su precio:
    1. Arreglada: 20.000 €.
    2. Fachada nueva y más sitio dentro: 30.000 €.
    3. Cuarto a la izquierda: 40.000 €.
    4. Cuarto a la derecha: 50.000 €.
    5. Segundo piso, con su puerta por detrás: 60.000 €.
  - Cuando se cambia de estado se llama a `casa.set_state(n)` y `casa.dentro.set_state(n)`, si existen (Pretil).
- **Lo que se guarda:** `stats.casa = {st, debe, estado, obra, obra_dia, offered}`.

**Trabajos** (`trabajos.gd`, nuevo). Ocupan `G.side = {id: "trabajo", kind, stage…}`, y una misión de la historia los deja.
- **El de las faenas** (`faenas`) es un NPC genérico en la Plaza del Ayuntamiento: `plaza.spot(6, 24)`. Da tres trabajos:
  - **Reparto en coche.** Recoges un bulto y lo llevas a una casa a 250–800 m, contrarreloj. Paga 100–600 € según lo rápido y lo entero que llegue.
  - **Taxi.** Un turno de 5 carreras: un vecino genérico a 40–150 m te hace señas, paras, se sube y lo llevas a 250–700 m. Cada carrera paga 100–500 €. Si te bajas del coche más de 10 s, se acaba el turno.
  - **Jornal en el campo.** 30 rosas del azafrán en la viña o el surco grande más cercano, en 150 s. Paga 25 € por rosa y 50 € más si las coges todas.
- **Henry**, cualquier día menos el jueves, te da un pedido para un vecino conocido; si conoces a menos de 3, para cualquier vecino con nombre del pueblo. Paga 30–150 € según lo caliente que llegue, y da +2 de confianza.
- **Lo cobrado** se guarda en `stats.trabajos`, con una línea en la página de encargos.

**Engranajes compartidos:**
- `game.gd`: preloads, setup, tick, `talk_to`, cajero en `interact` y en el texto de la acción, `restore` en `start_game`, `_side_drop`/`_side_show`/`_side_tick` para "trabajo", y la Agenda.
- `marcas.gd`: `givers`.
- `loc.gd`: los textos.
- `selftest.gd`:
  - Modo `--herencia`, porque `--casa` ya existía: 11 comprobaciones.
  - Modo `--trabajos`: 7 comprobaciones.
  - Las dos entran en la prueba completa, detrás de `_pintadas_checks`.
  - La comprobación de las páginas de la Agenda cambia de 6 a 7.

**Arreglado de paso:** la prueba `bancosancho` entraba en la copistería solo con pisar la flecha. Ahora pulsa Acción, y ya da 5 ok.

**Pruebas:** `herencia` 11 ok, `trabajos` 7 ok, `palabros` 3 ok, `bancosancho` 5 ok. Las fotos salen con `herencia shots` y `trabajos shots`. La prueba completa va después.

**Diagrama de misiones:** `guion/misiones.html` y el artefacto (v3) tienen ahora las secciones «De fondo» y «Trabajos».

**Pendiente:**
- `guion/relaciones.html`: añadir a Edmundo y a El de las faenas.
- Los modelados de Pretil: el interior del banco y los 6 estados de la casa.
- Para las rosas del jornal se usa la bola morada de `pickups`; mejor una rosa de verdad.

### Travesía del Rollo y tramo norte de la Bajada del Rollo: 21 entradas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y seguimos», tras aprobar Pizarro). Elegida con `faltan.py` (Travesía del Rollo, 170 m de fachada genérica), con lo que faltaba de la Bajada del Rollo al lado.

- **Hecho.** 21 entradas `rol_*`. Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.**
  - Pareadas de 1995 (Bajada del Rollo 30 a 44 en el Catastro): `rol_write.py` (scratchpad) pone el frente paralelo a la Travesía en la cara del cuerpo de dos plantas, recortado en la medianera, con `floors` 2 y `strip` 2,5, como `sur_write.py` en la Prolongación del Florido.
  - Travesía 3 en dos entradas con `only`: `rol_tr3h` (2 plantas, frente al tramo noreste) y `rol_tr3w` (1 planta, la tapia larga, `reach` 16).
  - `rol_tr3h` y `rol_tr1` se adelantaron 1,7 y 1,9 m hasta la cara de su parte, porque `precheck.py` las daba por detrás.
  - `rol_br10` se quitó tras ver las hojas: su frente estaba en un patio detrás de `rol_br8` (no lo cogió el aviso de fachadas escondidas).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (21 entradas; respetada la línea `alemania_5` de Edificios Especiales); `godot/data/map.json`; las hojas `guion/fotos/tanda34/rollo_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado sobre el de las 13:31 (el de Pizarro) y otra vez para quitar `rol_br10`, avisando a Edificios Especiales antes y después de cada uno.
  - Frente a las copias: 21 entradas nuevas, ninguna quitada de las de antes. `monjas_21`, `monjas_5` y `rol_br8` cambian solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
- **Pruebas.**
  - A las 14:02 el juego no cargaba `casa_dentro.gd` (Edificios Especiales lo estaba editando; avisado, no se tocó).
  - A las 14:05, `casas` de las 22 y las dos de Monjas: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_rol_b30_rol_b32_rol_b34_rol_b36_rol_b38_rol_b40_r_20261121_140557.log)).
  - Tras quitar `rol_br10`, `solo=rol_br8,rol_br15a,rol_br17`: 4 ok ([log](logs/selftest_casas_solo_rol_br8_rol_br15a_rol_br17_20261121_140907.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y seguimos»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11).

### Calle del Rollo y calle del Socorro: 16 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y seguimos», tras aprobar la Travesía y la Bajada del Rollo). Dos calles cortas en una tanda: el Rollo recoge las casas 17 y 19 que quedaron fuera de la Travesía; el Socorro sale de `faltan.py`.

- **Hecho.** 8 entradas `rro_*` y 8 `soc_*`. Fotos del Catastro; Street View de noviembre de 2024 en el bloque del Socorro. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.**
  - Rollo 1 (3890801) y Juan Carlos I 50 (3890803) están en `CARIDAD_RCS` de `bake_godot.py`: fuera.
  - `soc_2b` (3 plantas) y `soc_2y` (1 planta) comparten la parcela 4298527 con `only`.
  - `soc_4` y `soc_6` llevan `reach` 6, para dejar como casas normales sus cuerpos de dos plantas del fondo.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (16 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/rollo_socorro_1..3.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 14:08 (el del Rollo sin `rol_br10`), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 16 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 16: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_rro_17_rro_19_rro_37_rro_39_rro_41_rro_43_rro_45__20261121_141632.log)).
  - Tras oscurecer el ladrillo del bloque, `solo=soc_2,soc_2b`: 4 ok ([log](logs/selftest_casas_solo_soc_2_soc_2b_20261121_141825.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno a todo y paramos un poco»). En la 0.0.19 (commit `af9420f`, Sistemas, 21/11). Pausa después de esta tanda.

### «Saltar a misión» con todas las misiones (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Actualiza el "ir a misión" del modo desarrollador para que incluya todas las misiones».
- `game.gd`: la página `dev_missions` lista ahora la historia, como antes, y tres apartados más (`DEV_OTHERS`):
  - **Secundarias:** el menú de la Josefa, Don Luis, el jamón de los jueves, las pintadas de la Chiki, el Recress, el ajedrez y la Tomasa.
  - **De fondo:** la herencia y las obras con Edmundo.
  - **Trabajos:** El de las faenas y los pedidos de Henry.
- `_dev_side(id)` deja la historia hecha (paso `tbc`), con lo que pide esa misión abierto y sin hacer.
  - La hora es la que le hace falta: el jueves a las 8:30 para el jamón, y la llamada suena ya.
  - Te baja del coche de la Paca y te pone al lado de quien la da. Para las obras, en la flecha del banco.
  - Guarda la partida, como los saltos de la historia.
- Arreglado de paso: la Chiki no salía entre quienes dan misión, así que no tenía flecha verde con su encargo por estrenar y se iba de ronda. Ahora sí sale, con `pintadas.givers()` en `marcas.gd`.
- Prueba: modo `--devmisiones` (solo suyo, porque pone el juego patas arriba), 2 ok: están las 11 y cada salto te deja junto a quien da la misión.
  - `pintadas` 7 ok y `civicos` 39 ok.
  - La prueba completa de las 14:05 dio 917 ok y 0 fallos; fue antes de este cambio.

### Tres pitillos al día y 24 horas entre sueño y sueño (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Los cigarros limitados a tres al día y el dormir tendrá un cooldown de 24 horas in-game».
- **Pitillos** (`fumar.gd`): como mucho `PER_DAY` 3 en un día de juego, contando desde la medianoche.
  - Se cuentan en `stats.pitillo_n` y `stats.pitillo_dia`.
  - Con un cuarto, `why_not()` devuelve `fumar_day`: «Ya llevas tres pitillos hoy…». El pitillo no se gasta.
  - El de la Tomasa no cuenta.
- **Dormir** (`game.gd`): `SLEEP_EVERY` son 24 h, contadas desde que te acuestas. Se guarda en `stats.slept_h`, que pone `_go_to_sleep`. Así, quien se acuesta a las diez puede volver a hacerlo a las diez de la noche siguiente.
  - Antes de tiempo, la cama dice «Sin sueño hasta el MARTES · 22:00», y al pulsar sale un aviso.
  - La hora de dormir de la historia (paso `sleep`) nunca espera.
- **Prueba:** modo `--descanso`, 2 ok, también en la completa detrás de los trabajos. `mejoras2`, 12 ok.
- **Diagrama:** la tarjeta de los pitillos y una de dormir nuevas.

### Publicación de la 0.0.19 en GitHub (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Cuando termine Pretil, visto bueno a todo y 0.0.19».
- **Congelado.** Pretil y Texturas, desde que avisaron de que habían terminado.
- **Prueba completa:** 920 ok, 0 fallos (`logs/selftest_full_20261121_144541.log`). Después, `herencia` 12 ok y `casa` 4 ok, con el último retoque de Pretil en las fachadas, que solo cambia comentarios respecto a la versión probada.
- **Commits:**
  - `af9420f`: todo lo aprobado, de Sistemas, Pretil y Texturas.
  - «Matritellus 0.0.19»: número de versión, notas y los `.uid` de los scripts nuevos.
- **Etiqueta:** `v0.0.19`.
- **Paquetes:** `tools/make_apk.py 0.0.19` (versión 0.0.19, código 19, firmado y verificado), `tools/make_installer.py` y `tools/make_linux.py`.
  - Están en `dist/v0.0.19/`, con [sus SHA-256](dist/v0.0.19/SHA256SUMS.txt) comprobados.
  - Subidos a la release: https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.19
- **Sin probar:** no se ha probado en móvil ni en Steam Machine.

### Calle de Don Pedro de Castilla y calle de Dulcinea del Toboso: 19 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Perfecto. Puedes seguir», tras publicarse la 0.0.19). Las dos siguientes de `faltan.py`.

- **Hecho.** 11 entradas `dpc_*` y 8 `dul_*`. Fotos del Catastro; Street View de 2013 en `dpc_8d`. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.**
  - La hilera de 2007 de Don Pedro sale de `dd_write.py` (scratchpad, `orange()`).
  - `dpc_x14` lleva `floors` 1, para tomar el semisótano de los garajes, con `esc`.
  - Fuera: `dpc_b28` (Bajada del Rollo 28, 3,5 m de costado) y el molino (`MOLINO_RC`).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (19 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/donpedro_dulcinea_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 14:16 (el que publicó la 0.0.19), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 19 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 19: 3 ok, 1 fallo, porque `dul_4` tenía pocas piezas ([log](logs/selftest_casas_solo_dpc_2_dpc_4_dpc_8d_dpc_x10_dpc_x14_dpc_16_dpc_18__20261121_152232.log)).
  - Con hiladas y una puerta, `solo=dul_4`: 4 ok ([log](logs/selftest_casas_solo_dul_4_20261121_152411.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11).

### Camino Hondo: 12 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar Don Pedro y Dulcinea). La siguiente de `faltan.py`.

- **Hecho.** 12 entradas `cho_*`. Fotos del Catastro; Street View de noviembre de 2024 en `cho_9a` y `cho_9b`. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.** `cho_jx43` lleva el frente de la pared genérica (el del Catastro era un muro 4 m más al este). Fuera `cho_co8` (Concordia 8 da a la Concordia).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (12 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/camino_hondo_1..2.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 15:22 (el de Don Pedro y Dulcinea), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 12 casas nuevas, ninguna quitada. `bs_h20` cambia solo en las aristas tapadas. Calles, nodos, relieve, árboles (2954) y holguras iguales.
  - `precheck.py` antes de hornear: sin partes por delante ni fachadas escondidas.
- **Pruebas.**
  - `casas` de las 12 y `bs_h20`: 3 ok, 1 fallo, porque `cho_30` tenía pocas piezas ([log](logs/selftest_casas_solo_cho_jx43_cho_jx45_cho_1a_cho_14_cho_co10_cho_16_c_20261121_154705.log)).
  - Con hiladas y una puerta, `solo=cho_30`: 4 ok ([log](logs/selftest_casas_solo_cho_30_20261121_154832.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y continuar»). En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11).

### Calle de las Monjas, del 29 y el 40 a la Rosa de Santa María: 27 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y continuar», tras aprobar el Camino Hondo). La calle con más fachada genérica de `faltan.py` (378 m); esta es su primera tanda.

- **Hecho.** 27 entradas `mon_*`. Fotos del Catastro; Street View de noviembre de 2024 en tres puntos. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.** `mon_54`: frente adelantado 2 m hasta la cara de su porche (`precheck.py`). `mon_64` lleva `floors` 2. Fuera: Santa Ana (`SANTAANA_RC`), Monjas 63 y 65.
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (27 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/monjas_1..5.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 15:46 (el del Camino Hondo), avisando a Edificios Especiales antes y después.
  - Frente a la copia: 27 casas nuevas, ninguna quitada. Cuatro vecinas cambian solo en las aristas tapadas. Calles, nodos, relieve y árboles (2954) iguales. La holgura del nodo 2305 pasa de 6,3 a 6,0 m.
- **Pruebas.**
  - `casas` de las 27 y las cuatro vecinas: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_mon_29_mon_33_mon_35_mon_35d_mon_37_mon_39_mon_45_20261121_155912.log)).
  - Tras los cambios de color, `solo=mon_44,mon_46,mon_62,mon_x55`: 4 ok ([log](logs/selftest_casas_solo_mon_44_mon_46_mon_62_mon_x55_20261121_160145.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11).

### Calle de las Monjas, el resto (de Nalda a Sancho Panza): 20 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Visto bueno y siguiente», tras aprobar el primer tramo de las Monjas).

- **Hecho.** 20 entradas `mon_*`: Nalda 21, 23 y 25, Monjas 6, 10, 17, 19, 24, 36, 76, 78, 82, 84, 87, 88, 89, 90, 91, San Isidro 59 y Sancho Panza 10. Street View de noviembre de 2024 en todas (el 24, de marzo de 2013) y fotos del Catastro. Lo que no se parece está en `guion/repaso_casas.md`.
- **Casos especiales.**
  - El 6 y el 89 son solares en el Catastro y tienen casa en 2024: `rc` nulo con `deep` (10 y 5 m).
  - El 87 es el brazo de la parcela de Florido 68 (`flo_68` toma solo las partes de 3 plantas): `only` 2, `reach` 3.
  - El 17 (`reach` 4: el trozo de la acera y el bloque de 3 plantas de detrás) y el 10 (`reach` 2,5: solo la punta a la calle).
  - Nalda 25 y Sancho Panza 10 llevan el frente en la calle de su número.
  - `monjas_26` (tanda antigua): frente movido de la trasera de `mon_24` a su cara a la revuelta, solo en `calles.json`. `precheck.py` da FORWARD 2,2 m: es el quiebro real de su fachada, más allá del final del frente.
  - Fuera: Monjas 22 (nada en pie a la calle en el Catastro).
- **Archivos.** `tools/casas/calles.json` (20 entradas y el frente de `monjas_26`), `godot/scripts/casas_calles.gd` (20 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/monjas_b_1..5.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Horneado una vez sobre el de las 16:23, avisando a Edificios Especiales antes y después.
  - Frente a la copia: 20 casas nuevas, ninguna quitada. Nueve vecinas cambian solo en las aristas tapadas; `amargura_17` y `monjas_85`, además, 1–3 cm de suelo. Calles, nodos, relieve y árboles (2954) iguales.
- **Pruebas.**
  - `casas` de las 20, `monjas_26`, `amargura_17` y `monjas_85`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_mon_n21_mon_n23_mon_n25_mon_10_mon_6_mon_17_mon_1_20261121_172329.log)).
  - Tras los cambios de color de ocho y la ventana de San Isidro 59, `solo=mon_n23,mon_6,mon_17,mon_36,mon_76,mon_si59,mon_88,mon_90,mon_24`: 4 ok ([log](logs/selftest_casas_solo_mon_n23_mon_6_mon_17_mon_36_mon_76_mon_si59_mon_8_20261121_172751.log)).
- **El arco del patio entre el 2 y el 10** (el usuario, al ver las hojas: «Falta el arco de ladrillo con patio interior. Tendrá la portada abierta y habrá un azafrán escondido ahí»).
  - El mapa ya dejaba ese hueco sin casa entre `mon_10` y `monjas_b742`: es el patio. No hizo falta rehornear.
  - `godot/scripts/casas.gd`: `_mon_10()` construye la casa por su línea corta y, en un marco propio a lo largo del hueco, el muro de ladrillo con arco de medio punto y albardilla de teja, el zócalo de granito, la franja blanca contra el 2, las dos hojas de la cancela abiertas hacia dentro (`_arco_leaf`), el solado rojo del patio, un palé de ladrillos y, detrás, el azafrán en su maceta (`game.flowers`, `"id": "arco_monjas"`, `"hidden": true`).
  - Los pilares, la franja blanca y el palé dejan su contorno en `MapData.outlines` (y en la rejilla si ya está hecha), como la almazara; el arco queda libre para pasar.
  - Pruebas: `casas` de `mon_10` y `monjas_b742`: 4 ok ([log](logs/selftest_casas_solo_mon_10_monjas_b742_20261121_174451.log)); los 12 avisos `ARRAY_FORMAT_TEX_UV` ya salían antes. Fotos con `vistas=arco_calle,arco_dentro,arco_azafran` (sale «VISTAS OK»; `run_tests.py` no reconoce esa línea y da «NO RESULT»). Hoja `guion/fotos/tanda34/monjas_arco.jpg`.
  - No probado: coger el azafrán en una partida de verdad (la recogida es la misma de los otros escondidos). Avisado Sistemas.
- **Aprobado** por el usuario el 21/11 («Visto bueno»), la tanda y el arco. En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11).

### Travesía del Clavel, principio del Clavel y Calle del Romero: 24 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Siguiente», tras aprobar las Monjas). Elegidas por `faltan.py`: calles cerca del centro con fachada genérica.

- **Hecho.** 24 entradas: `tcl_4` a `tcl_20` (la hilera de 2004 del callejón), `cla_6`, `cla_tsr8`, `rom_d14`, `rom_45`, `rom_39`, `rom_39b`, `rom_24c`, `rom_24b`, `rom_24a`, `rom_18b`, `rom_21`, `rom_19`, `rom_17`, `rom_15`, `rom_9`. Fotos del Catastro y Street View de noviembre de 2024; lo que no se parece, en `guion/repaso_casas.md`.
- **Casos especiales.**
  - La hilera va en parejas que comparten la escalera de entrada: la puerta a la derecha en el 4, 8, 12, 16 y 20, a la izquierda en el 6, 10, 14 y 18 (`tcl()` en el borrador).
  - `rom_39` (`only` 2) y `rom_39b` (`only` 1, `reach` 3): la casa de dos plantas y su trozo bajo. `rom_24c` con `reach` 8 (su bloque de cuatro plantas de detrás, no el del fondo).
  - Fuera: 4494604 (una tira de una planta sin dirección en el lado oeste de la Travesía), Delicias 21 y 12 (no dan al Romero).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (24 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/clavel_romero_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Horneado una vez, avisando a Edificios Especiales antes y después. Frente a la copia: 24 casas nuevas, ninguna quitada; `romero_11` y `rafael_tc2` solo cambian en las aristas tapadas (y 6 cm de suelo en la segunda). Calles, nodos, relieve y árboles (2954) iguales.
- **Pruebas.**
  - `casas` de las 24, `romero_11` y `rafael_tc2`: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tcl_4_tcl_6_tcl_8_tcl_10_tcl_12_tcl_14_tcl_16_tcl_20261121_180513.log)).
  - Tras los cambios de color (el ocre de la hilera; los portones del 24 A y el 17; la puerta del 21): 4 ok ([log](logs/selftest_casas_solo_tcl_4_tcl_12_tcl_20_rom_24a_rom_21_rom_17_20261121_180823.log), [log](logs/selftest_casas_solo_tcl_6_tcl_8_tcl_10_tcl_14_tcl_16_tcl_18_20261121_180932.log)).
- **La Travesía, peatonal y elevada:** el usuario preguntó si la había hecho elevada, con sus dos accesos (escalera por el Clavel, rampa por San Rafael). No lo estaba: en el mapa es una calle `residential` de asfalto. El usuario: «De acuerdo, que sea peatonal y con las cosas que has dicho. Que se ponga Petril con eso cuando termine con el Rice». Encargado a Edificios Especiales por mensaje. Fotos y notas en `referencias/travesia_clavel/` (LEEME.md, nuevo).
- **Aprobado** por el usuario el 21/11 («Visto bueno a todo y paramos»). En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11).
- **Después, a petición de Pretil** (su paseo elevado, `travesia.gd`, pasa 0,30–0,55 m por debajo de cada umbral, con un rellano y peldaños ante cada puerta): en `tcl_4` a `tcl_20` quité la escalera `esc` y el ventanuco de la planta de piedra. Queda `wall=stone h=1.4`; las puertas no se mueven. Sin horneado. Sobre el mapa de Pretil con la Travesía (clave `travesia`), `casas` de las nueve: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tcl_4_tcl_6_tcl_8_tcl_10_tcl_12_tcl_14_tcl_16_tcl_20261121_192344.log)). En las fotos, sus rellanos con barandilla quedan ante cada puerta y la piedra asoma por debajo.

### Teniente Infante, Avenida de Castilla-La Mancha, Alameda y Arroyuelo Bajo: 17 casas (21/11)

21 de noviembre de 2026, Texturas (Claude). A la orden del usuario («Siguiente calle»). Elegidas por `faltan.py`: calles cerca del centro con fachada genérica.

- **Hecho.** 17 entradas:
  - `tin_15`, `tin_x11`, `tin_x10`, `tin_16`, `tin_x6`;
  - `acm_6`, `acm_8`, `acm_21`, `acm_24`, `acm_26`, `acm_28`, `acm_ar28`;
  - `ala_10`, `ala_am36b`, `abj_jm27`, `abj_rs14`, `abj_jc15d`.
  - Fotos del Catastro y Street View de noviembre de 2024; lo que no se parece, en `guion/repaso_casas.md`.
- **Rótulos.** La sucursal de la caja rural del Teniente Infante lleva «AHORROS RURALES», el banco del juego. La zapatería de Castilla-La Mancha 28 lleva solo «CALZADOS». Los carteles de «se alquila» van con `t=1` (de agencia, sin número de teléfono).
- **Fuera.** Cervantes 3 es la iglesia parroquial, hecha a mano. Santo 40 y Reina Sofía 31 no dan a estas calles. Castilla-La Mancha 14 queda escondida detrás de `castilla_16` (`precheck.py`).
- **Archivos.** `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (17 entradas); `godot/data/map.json`; las hojas `guion/fotos/tanda34/infante_castilla_1..4.jpg`; `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.**
  - Paré mi primer horneado al avisar Edificios Especiales de que horneaba la cafetería Rize; no llegó a escribir `map.json`.
  - El de Pretil terminó (18:37) antes de mi fusión, así que no traía mis casas. Volví a hornear sobre el suyo, avisando antes y después.
  - Frente a la copia: 17 casas nuevas, ninguna quitada, `rize` intacto. `alameda_9`, `alameda_10` y `castilla_22` solo cambian en las aristas tapadas (y 9 cm de suelo en la primera). Calles, nodos, relieve y árboles (2954) iguales.
- **Pruebas.**
  - `casas` de las 17 y esas tres: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tin_15_tin_x11_tin_x10_tin_16_tin_x6_acm_6_acm_8__20261121_184539.log)).
  - Tras cambiar a `brick_rose` el ladrillo del 6 y del 28 de Castilla-La Mancha: 4 ok ([log](logs/selftest_casas_solo_acm_6_acm_28_20261121_184753.log), [log](logs/selftest_casas_solo_acm_6_20261121_184902.log)).
- **Aprobado** por el usuario el 21/11 («Visto bueno a todo y paramos»). En la 0.0.20 (commits `b97ac87` y `d4066ba`, Sistemas, 21/11). Las calles quedan en pausa hasta nueva orden; la siguiente por `faltan.py` sería Tembleque o Delicias.

### La almazara «González de la Ruz» (21/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Ahora ponte con aceites García de la Cruz (que llamaremos Gonzalez de la Ruz) tiene fachada tanto en calle triunfo como en carretera de villacañas».
- **Qué es.** La almazara de la carretera de Villacañas (Catastro 4699012VJ5649N), con la trasera en la calle del Triunfo, hecha a mano en `godot/scripts/almazara.gd`. Incluye la nave alta junto a la carretera, que Catastro no tiene.
  - Por la carretera: testero de la nave vieja con el mural, la entrada abierta al patio, el muro largo con el rótulo repetido y la nave alta de 14,7 m.
  - En el patio: el costado de la tienda, las oficinas color salmón, la nave de recepción abierta con su cabina, su tolva y sus depósitos; tras el muro, banderas, cobertizo de madera, depósitos de acero e instalaciones.
  - Por el Triunfo: el otro testero, un bloque de dos plantas, un tramo viejo con alero de teja y el muro largo de las naves.
  - Rótulo, emblema y mural son dibujos propios (`tools/almazara/dibujos.py`, en `godot/assets/almazara/`). Sin personajes. Sin interior.
  - Un azafrán escondido tras el muro (`"id": "almazara"`, `"hidden": true`).
- **Rehorneado** (avisados Sistemas y Texturas antes y después; ensayado con `tools/colegio/ensayo.py`).
  - Bloque ALMAZARA en `tools/bake_godot.py`: salta el RC, sus contornos en `block_list`, sin árboles en su zona, clave `almazara`.
  - Cambios en `godot/data/map.json`: fuera las 5 naves genéricas de la parcela (5 tejados planos, 46 muros) y la holgura del nodo 1250 del Triunfo de 2,3 a 2,4 m. Relieve, nodos, calles y árboles (2954) iguales.
  - Después retoqué dos contornos del bloque (nave de recepción más grande, nave alta un metro más corta). Un segundo ensayo da el mismo mapa que el horneado, así que no hizo falta rehornear.
- **Archivos.**
  - Nuevos: `godot/scripts/almazara.gd`, `godot/assets/almazara/` (6 PNG), `tools/almazara/` (capturas, alzado, manzana, plano, vistas, hojas, dibujos, LEEME), `tools/ign/almazara*.jpg/.json`, `referencias/almazara/LEEME.md`, `guion/fotos/almazara/01–03`, `tools/casas/4699012VJ5649N/` (ficha de Catastro).
  - Compartidos, solo con añadidos y con aviso: `tools/bake_godot.py`, `godot/data/map.json`, `godot/scripts/map_data.gd` (`var almazara`), `godot/scripts/world.gd` (`AlmazaraS`, `var almazara`, paso «the oil mill», `_build_almazara()`), `godot/scripts/selftest.gd` (modo `--almazara`, `_almazara_checks()` y su llamada en la completa tras `_silo_checks()`).
- **Decisiones que conviene conocer** (detalle en [referencias/almazara/LEEME.md](referencias/almazara/LEEME.md)).
  - El muro del Triunfo va retranqueado hasta un metro respecto a Catastro, para no meterse en el pasillo que el horneado reserva a la calle.
  - El muro de la carretera sigue el terreno: en el juego la carretera cae 4 m hacia el noreste.
  - La nave alta y la de recepción se han trazado sobre la ortofoto, no sobre Catastro.
- **Pruebas.**
  - `python tools/run_tests.py almazara`: 3 ok, 0 fallos ([log](logs/selftest_almazara_20261121_163528.log)). Comprueba que está construida, que frena en las dos calles, que la entrada está abierta, que el mapa conoce sus contornos, el azafrán y el paseo desde la carretera hasta su rincón.
  - `python tools/run_tests.py relief` tras el horneado: 19 ok, 0 fallos ([log](logs/selftest_relief_20261121_163800.log)).
  - La prueba completa no la he pasado.
- **Aprobada por Luis** (21/11): «Mejor con tilde. Visto bueno». El rótulo se queda como está, «González de la Ruz», con tilde (él lo había escrito sin ella y se lo pregunté).
- **Sin commit**: lo hace Sistemas.

### Javi y sus pollos (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario, a través de Pretil, que hace el asador y su interior: Javi, del «Asador de pollos Juli» (llamado Javi).
- **Qué pidió.** Repartos «como los de Henry pero de pollo», los martes y los domingos. Se desbloquea tras el jamón de la Josefa, «al llegar el próximo día de reparto o al hablar con él». Desde entonces sale su cara en el mapa y la Josefa te habla de él. Javi es «bajito, hermoso, con gafas, calvo y vestido de negro básico».
- **`javi.gd` (nuevo).**
  - La figura:
    - Camiseta negra, calvo (`hair_style` 32), gafas.
    - `scale` 0.86 y `build` 1.34.
  - Dónde está: tras el mostrador mientras abre el asador. Lo lee de `G.world.asador.dentro`: `javi_spot`, `javi_h` y `open`, o si no `asador.open_at`.
  - El desbloqueo:
    - Se guarda en `stats.javi`.
    - Con `stats.menu_done`, llega por un martes o domingo o al hablarle.
    - Te avisa con un toast y te lo presenta (`folk.meet`).
  - La Josefa te habla de él una vez (`stats.javi_josefa`).
  - Lleva flecha verde y cara en el mapa cuando tiene un pedido.
  - Sin asador en el mapa, no se crea.
- **`trabajos.gd`.** Los pedidos de Henry pasan a `order_offer(n, kind, lines_key)`, y los pollos de Javi son el kind `pollo`. Cuando el que da el pedido está dentro de un decorado, la distancia se mide desde la puerta.
- **`game.gd` y `marcas.gd`:** los enganches.
- **`loc.gd`:** sus frases, y las de firma de Javi.
- **Pruebas:**
  - Modo `--javi` (`_javi_checks`), también en la completa. Mientras no esté el asador se salta.
  - `trabajos`: 7 ok. Ahora entrega el pedido hablando, porque ponerse a 1 m de la Paca dejaba al jugador dentro de la pared.
  - `palabros`: 3 ok.
- **Árbol de relaciones** (sin foto hasta que exista en el juego) y **diagrama de misiones** (v5), actualizados.
- **Pendiente:** el asador de Pretil, para enganchar y pasar `javi`.

### El asador de pollos «Javi»: fachada e interior (21/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Siguiente edificio asador de pollos juli (que llamaremos Javi). Abrirá en horario comercial y dentro estará Javi […] Se podrá acceder al interior, que estará diseñado (adjunto foto). Pasa a sistemas lo que le toque».
- **Reparto.** Yo hago el edificio y su interior. A Sistemas le pasé su parte con las palabras de Luis: el personaje Javi, sus repartos de pollo de martes y domingos, el desbloqueo tras la misión del jamón de Josefa, su cara en el mapa y la mención de Josefa.
- **Dónde.** La casa ocre de la calle de los Arcos (Catastro 4390040VJ5649S), que es la `arcos_4d` de Texturas. Google la da como «Arcos, 6», pero en Catastro ese número es la casa blanca de al lado.
- **Qué hay.**
  - `godot/scripts/asador.gd`: la fachada sobre la casa del mapa. Ocre sobre zócalo de piedra, puerta de la vivienda con cortina, la tienda con su reja plegable y su toldo, el rótulo «Javi · Pollos Asados · Comidas preparadas» (primero decía «Asador de pollos»; Luis: «En vez de Asador de Pollos mejor llamarlo Pollos Asados»), la banderola «POLLOS ASADOS», dos balcones y una buhardilla. Abierto y cerrado según la hora.
  - `godot/scripts/asador_dentro.gd`: el interior, un decorado aparte en (2100, −1400) con flecha verde en la puerta. Sigue la foto de Luis: mostrador de acero con tela morada, mampara y diez bandejas, la caja registradora, suelo de barro, cortinas naranjas; detrás, el asador con los pollos girando.
  - Rótulos propios en `godot/assets/asador/` (`tools/asador/dibujos.py`), sin el nombre real ni teléfonos.
  - Un azafrán escondido dentro (`"id": "asador"`, `"hidden": true`).
  - Sin personajes: dejo `javi_spot`, `javi_h`, `client_spot`, `client_h` y `counter_front` para Sistemas.
- **Horario**: martes y domingos de 7:00 a 16:00; cerrado el resto de la semana (`HOURS` en `asador.gd`). Un cartel en el cristal lo dice. Luis pidió primero «horario comercial», luego mandó el del asador real (martes 11–15, domingos 11:30–15) y por último: «Pon que esos días abre a las 7:00 mejor. Y cierra a las 16:00».
- **Archivos.**
  - Nuevos: `godot/scripts/asador.gd`, `godot/scripts/asador_dentro.gd`, `godot/assets/asador/` (4 PNG), `tools/asador/` (`dibujos.py`, `hojas.py`), `referencias/asador/` (`LEEME.md`, `arcos_4d_antes.txt`), `guion/fotos/asador/01–02`.
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`AsadorS`, `var asador`, paso «the roast chicken shop», `_build_asador()`), `entradas.gd` (una entrada en `shops()`), `selftest.gd` (modo `--asador`, `_asador_checks()` y su llamada en la completa tras `_almazara_checks()`).
  - De Texturas: `casas_calles.gd`, solo la línea de `arcos_4d`, que pasa a `["obra"]`. Le avisé antes con el detalle; como no contestó (estaba ocupado), la cambié yo y se lo comuniqué. Sin rehorneado.
- **Pruebas.** `python tools/run_tests.py asador`: 5 ok, 0 fallos ([log](logs/selftest_asador_20261121_180801.log)). Comprueba que está construido, que la casa está cedida, el horario y los dos estados, que el decorado está lejos y cerrado, que es una tienda con flecha, el azafrán y que el mostrador no deja pasar.
  - No he probado entrar por la flecha desde la calle andando, ni la prueba completa.
- **Trampas** (detalle en [referencias/asador/LEEME.md](referencias/asador/LEEME.md)): el primer sitio del decorado tenía dos olivos del mapa dentro; la puerta del decorado tiene que ir centrada en su pared.
- **Aprobado por Luis** (21/11): «Visto bueno», tras los cambios de nombre y de horario.
- **Pendiente.** La parte de Sistemas (Javi y sus repartos). Sin commit.

### Coger con Acción, azafrán que gira, bate al recogerlo, pedidos que esperan, Marciano (21/11, Claude · Sistemas)

21 de noviembre de 2026. Lo pidió el usuario:
> «Todos los azafranes deberían ser como los desperdigados por la ciudad, pero con el mismo efecto 3D giratorio y halo del resto de objetos»
> «muchos de los que te piden recoger aparecen exactamente donde está el jugador… no da tiempo a ver el modelo»
> «El golpe con bate estará disponible desde que lo recoges del suelo»
> «para evitar coger el objeto por accidente sería mejor que sea necesario pulsar el botón de acción»
> «cuando Henry o Javi te digan que recojas el encargo… no se activará el temporizador hasta que recojas el objeto 3D»

- **Coger con Acción** (`pickups.gd`). Ya no se coge nada solo con pisarlo.
  - `near(pp)`, `prompt(it)` («Coger %s», `p_coger`) y `take(it)`, en `interact` y en el texto de la acción de `game.gd`.
  - Los de mostrador (`auto` false: el tabaco, los pitillos) siguen con su botón.
  - Un objeto que aparecería encima de ti sale a 2,4 m, por el primer lado sin pared (`_off_the_player`).
- **Azafrán.**
  - Las flores del pueblo y las escondidas por los decorados flotan, giran y llevan el halo (`pickups.dress`, `game._dress_flowers`).
  - El jornal usa la misma flor (kind `azafran` en `_build_mesh`).
  - Se coge con Acción (`near_flower`, `_take_flower`).
- **Bate.** `has_bat()` vale también con `stats.bate`, que se pone al recoger el bate en casa de la Josefa.
- **Pedidos de Henry y Javi.** Con el «sí», el pedido aparece junto a quien lo da (kind `jamon` o `pollo`; el pollo es un modelo nuevo) y no corre el tiempo (`stage` `recoger`). Al cogerlo empieza el reloj.
  - Se entrega hablando antes que cualquier otra cosa del vecino (`trabajos.hand_over`, al principio de `talk_to`).
  - El vecino a quien va ya no tiene que estar a la vista (desde dentro de un decorado no se ve a nadie).
- **Javi, enganchado a Pollos Asados Javi** (Pretil: `asador.dentro`). Su horario final: martes y domingos de 7 a 16. El nombre del sitio está cambiado en los textos.
- **Marciano** (`marciano.gd`, nuevo; el usuario: bigote, hermoso, tupé negro).
  - Aspecto: `hair_style` 8, `face` 4 y `build` 1.3.
  - Está enfrente de la cafetería del callejón (`G.world.cafeteria.marciano_spot`/`_h`, que hace Pretil). Seis charlas: los jóvenes de hoy, los ochenta y la ruta del bacalao.
  - Hasta que esté la cafetería no aparece.
- **`scene_shot`:** una segunda pasada más cerca y más alta, con los planos de lado solo al final. Con la tanda nueva de casas, una pared de la Chiki había quedado de lado.
- **Pruebas:**
  - Completa: 934 ok, 0 fallos (`logs/selftest_full_20261121_181743.log`), antes de Marciano.
  - `javi`: 5 ok. `trabajos`: 8 ok. `herencia`: 12 ok. `pintadas`: 7 ok. `motin`: 64 ok. `palabros`: 3 ok.
  - `--marciano` se salta hasta que esté la cafetería.

### La «Cafetería Rize» y su callejón (21/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «El siguiente objetivo es la cafetería rice con todo su callejón incluido. Hay una foto 360° dentro del callejón. Enfrente habrá un NPC con bigote, hermoso, y peinado tupé negro que se llamará Marciano […]». Y después: «Lo llamaremos al local Rize en vez de Rice».
- **Reparto.** Yo hago el callejón, la cafetería y lo que la rodea. Marciano es de Sistemas (`marciano.gd`), que ya lee `G.world.rize`.
- **Dónde.** El callejón sin nombre que entra desde la avenida de Juan Carlos I entre `juancarlos_10` y `juancarlos_4`. Catastro: la cafetería es 4091010VJ5649S y el garaje de enfrente, 4091028VJ5649S.
- **Fuentes.** Una foto 360° del fondo del callejón (febrero de 2020; de otra persona, no está en el repositorio) y Street View desde la avenida (noviembre de 2024). En 2020 el suelo era hormigón y en 2024 adoquín gris: vale lo más reciente.
- **Qué hay** (`godot/scripts/rize.gd`, `world.rize`).
  - El callejón adoquinado y cerrado al tráfico, con un remate propio al fondo.
  - La cafetería: pared blanca sobre zócalo de granito, tres ventanas en rombo con reja, puerta sobre tres escalones, toldo con el nombre, terraza de cuatro mesas, barril, cajas y sillas apiladas.
  - El fondo: tapia vieja con un portón verde, la tinaja y las sombrillas cerradas.
  - Enfrente: el garaje blanco de uralita con el emblema y la puerta de ramas pintadas, y la casa gris de recercos de travertino.
  - La casa gris es una piel de 22 cm sobre el costado de `juancarlos_10` (Texturas la acepta: «me vale; déjala»).
  - En la boca, la pizarra, solo mientras está abierta.
  - El emblema es del juego (tupé y bigote negros, «SIEMPRE DE FIESTA»), en lugar del de la peña real.
  - Un azafrán escondido tras las cajas (`"id": "rize"`, `"hidden": true`).
  - Sin interior.
  - Para Sistemas: `marciano_spot`, `marciano_h`, `door`, `is_open`, `open_at(day, hour)`.
- **Horario**, el de la cafetería real: lunes cerrado; martes y miércoles de 9 a 17; de jueves a domingo de 9 a 19.
- **Horneado** (hecho, con aviso antes y después a Texturas y a Sistemas).
  - `PAVED_ALLEYS`: la vía sin nombre pasa a `k` 2, `paved` 2 y la marca nueva `narrow`.
  - `corridor_half` respeta `narrow` (pasillo de 1,9 m: ninguna casa se mueve).
  - Bloque `RIZE`: las dos parcelas ya no se levantan como genéricas; clave `rize` en `map.json`.
  - Diferencias: 2 tejados y 5 muros genéricos menos; `clr` del nodo 3062 de 2,8 a 1,6; lo demás, igual.
- **Archivos.**
  - Nuevos: `godot/scripts/rize.gd`, `godot/assets/rize/` (4 PNG), `tools/rice/` (`dibujos.py`, `hojas.py`, `manzana.py`, `vistas360.py`), `tools/ign/rice.jpg` y `.json`, `tools/casas/4091010VJ5649S/`, `referencias/rice/LEEME.md`, `guion/fotos/rice/01–02`.
  - Compartidos, solo con añadidos y con aviso: `tools/bake_godot.py`, `godot/data/map.json` (rehorneado), `map_data.gd` (`var rize`), `world.gd` (`RizeS`, `var rize`, paso «the Cafetería Rize», `_build_rize()`), `selftest.gd` (modo `--rize`, `_rize_checks()` y su llamada en la completa tras `_asador_checks()`).
- **Pruebas.** `python tools/run_tests.py rize`: 4 ok, 0 fallos ([log](logs/selftest_rize_20261121_185042.log)). Comprueba que está construido, que sus muros paran y el callejón es peatonal, el horario y los dos estados, el azafrán, que se entra andando desde la avenida hasta el fondo y que el sitio de Marciano ve la puerta.
  - No he pasado la prueba completa ni `--marciano` (es de Sistemas).
- **Trampas** (detalle en [referencias/rice/LEEME.md](referencias/rice/LEEME.md)): `nearest_road(p, true)` para ver una vía peatonal; lo que rellena los huecos de la piel va por delante del ladrillo; la piedra clara necesita `_glow` para no salir parda en la sombra.
- **Aprobado por Luis** (21/11): «Visto bueno sobre todo». Sin commit (lo hace Sistemas).

### La persecución de la furgoneta del sabotaje, sin caída de FPS (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «la misión de sabotaje baja mucho de FPS cuando empiezas a perseguir a la furgoneta».
- **Medido** con el modo nuevo `--perfil_sabotaje` (en ventana, sin `--fixed-fps`): el tick por partes antes del recado y durante la persecución.
  - Antes del recado: 201 fps.
  - Persiguiendo: entre 51 y 73 fps.
  - La parte de la misión pasaba de 0,1 a 5 ms en cada fotograma.
- **Causa.** `sabotaje.stop(i)` recorría las 2.727 casas del mapa y llamaba a `MapData.nearest_road`, que mira todas las calles, y `_follow` la pedía en cada fotograma.
- **Arreglo.** Se calcula una vez y se guarda (`_stops`, `_find_stop`).
- **Después:** entre 116 y 136 fps persiguiendo; la misión, 0,07 ms por fotograma. El tick de física sigue algo más alto que fuera de la misión (unos 11–15 ms frente a 5–6), pero ya no por la misión: sus partes medidas suman menos de 1,5 ms.
- **`game.gd`:** la marca «garages, missions» del perfil se parte en «garages, calls», «mission markers», «side lines» y «sabotage». Sin perfil activo no cuestan nada.
- **Prueba:** en `_sabotaje_checks`, la misión cronometrada directamente durante la persecución tiene que costar menos de 0,5 ms por fotograma. Con el código antiguo falla (4,72 ms) y con el arreglo pasa (0,07 ms). `sabotaje`: 46 ok.
- **Revisado** el resto de búsquedas caras (`nearest_road`, recorrer `houses`, `path`, `route_nodes`) dentro de código de cada fotograma: las que quedan van cada 2 s.

### La Travesía del Clavel, peatonal y elevada (21/11, Claude · Edificios Especiales)

- **Encargo de Luis**, que llegó por Texturas: «De acuerdo, que sea peatonal y con las cosas que has dicho. Que se ponga Petril con eso cuando termine con el Rice». Antes había dicho: «Tiene dos accesos, es de la escalera de la calle clavel y el de la rampa de la calle san Rafael».
- **Qué hay** (`godot/scripts/travesia.gd`, `world.travesia`).
  - El paseo de baldosa a cuadros, un plano inclinado entre 0,9 y 1,5 m sobre el terreno.
  - Por San Rafael, tres rampas en zigzag entre muretes blancos con rejillas y barandilla de tubo.
  - Por el Clavel, la escalera a cuadros, el carril del garaje y la escalera de la terraza de la hilera este.
  - Ante cada puerta de la hilera este (de Texturas), un rellano con sus peldaños y barandilla de forja.
  - La hilera oeste y la casa blanca de la esquina del Clavel, hechas a mano: el Catastro las tiene de 1,4 a 5 m fuera de su sitio.
  - Un azafrán escondido junto al primer banco (`"id": "travesia"`).
- **Aproximado**: el carril del garaje no baja bajo el paseo (el relieve no admite un foso tan estrecho); la hilera oeste es una reconstrucción regular.
- **Horneado** (hecho, con aviso antes y después): la calle pasa a `k` 2, `pedestrian`, `paved` 5; la parte 2 de 4494604 no se levanta; clave `travesia`. Relieve, nodos, `clr`, árboles y casas, iguales.
- **Archivos.**
  - Nuevos: `godot/scripts/travesia.gd`, `godot/assets/travesia/` (3 PNG), `tools/travesia/` (5 scripts), `tools/ign/travesia.jpg` y `.json`, `guion/fotos/travesia_clavel/01–03`.
  - Compartidos, solo con añadidos y con aviso: `tools/bake_godot.py`, `godot/data/map.json`, `map_data.gd` (`var travesia`), `world.gd` (`TravesiaS`, `var travesia`, paso, `_build_travesia()`), `selftest.gd` (`--travesia`, `_travesia_checks()` tras `_rize_checks()`), `empedrado.gd` (salta `paved` 5).
  - De Texturas, hecho por ella a petición mía: `casas_calles.gd`, las nueve líneas `tcl_4` a `tcl_20` sin `esc` ni ventanuco.
  - Notas añadidas al final de [referencias/travesia_clavel/LEEME.md](referencias/travesia_clavel/LEEME.md).
- **Pruebas.** `travesia`: 4 ok ([log](logs/selftest_travesia_20261121_192929.log)): construido, el paseo elevado, se sube por las rampas, se recorre y se baja por la escalera, los muros paran, el azafrán. `relief`: 19 ok ([log](logs/selftest_relief_20261121_192716.log)).
  - No he pasado la completa.
- **Para Sistemas**: ante las puertas de la hilera hay que usar `MapData.foot(p)`; avisado.
- **Aprobado por Luis** (21/11): «Visto bueno sobre todo». Sin commit (lo hace Sistemas).

### Rendimiento de las misiones y la riña que deja ver a través (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Prueba de rendimiento» y «Que durante la riña del jamón los NPCs detrás de ti salgan transparentes, no invisibles».
- **Medida.** Modo nuevo `--perfil_misiones` (en ventana, sin `--fixed-fps`). Mide una tras otra varias situaciones del juego, y el informe del perfil saca ahora también las llamadas de dibujado, los objetos y los triángulos.

  | Situación | FPS |
  |---|---|
  | A pie en la plaza | 140 |
  | Taxi | 112–116 |
  | Reparto | 160 |
  | Jornal con 30 rosas | 232 |
  | Persecución de la policía | 101 |
  | Dentro del Recress | 252 |
  | La riña del jamón | 70–74 |
  | Persecución de la furgoneta del sabotaje, ya arreglada (antes 51–73) | 116–136 |

- **La riña.** Ninguna parte del código destaca. Lo que pesa es el dibujado:
  - 2.471 llamadas frente a 1.343 a pie, y 3.790 objetos frente a 2.014.
  - Cada vecino de la multitud son decenas de piezas.
  - Quitar las sombras de la multitud no cambia nada: solo 103 piezas hacían sombra.
  - **Pendiente:** juntar las piezas de cada vecino en una malla. Es un cambio en `chara.gd` de calado, que se deja fuera de esta versión.
- **Transparencia en la riña** (`game.gd` `_ghost_lens` y `_ghost`, `GHOST` 0.68). Los vecinos entre la cámara del hombro y tú se ven a través, con `transparency` en sus `GeometryInstance3D`, en vez de ocultarse. En las escenas de cámara fija, quien queda pegado al objetivo se sigue ocultando como antes.
  - Prueba nueva en `motin`: un vecino en medio se ve a través y vuelve a ser sólido al apartarse. `motin`: 66 ok. La foto es `motin_transparente`.

### Publicación de la 0.0.20 en GitHub (21/11, Claude · Sistemas)

21 de noviembre de 2026. El usuario: «Si todo sale bien, prueba completa, commit de todo y release».
- **Congelado.** Pretil y Texturas, sin nada a medias.
- **Prueba completa:** 945 ok, 0 fallos (`logs/selftest_full_20261121_200056.log`).
- **Commits:**
  - `b97ac87`: todo, de Sistemas, Pretil y Texturas.
  - «Matritellus 0.0.20»: versión y notas.
- **Etiqueta:** `v0.0.20`.
- **Paquetes:** `tools/make_apk.py 0.0.20` (versión 0.0.20, código 20, firmado y verificado), `tools/make_installer.py` y `tools/make_linux.py`.
  - Están en `dist/v0.0.20/`, con [sus SHA-256](dist/v0.0.20/SHA256SUMS.txt) comprobados.
  - Release: https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.20
- **Sin probar:** no se ha probado en móvil ni en Steam Machine.

### «Seguros Sopiss», primera pieza del cruce de los semáforos (21/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «…el cruce de los semáforos o las cuatro esquinas… Te pido ahora colocar estos donde corresponde. Antes igual tendremos que hacer unas pocas fachadas. Sugiero ir una por una y empezar por el edificio de soliss seguros (última foto) y que llamaremos seguros sopiss, tendrá luces de apagado o encendido según su horario y en su interior saldrán dos NPCs genéricos hablando de seguros cuando abierto, y una señora de la limpieza cuando cerrado. Se podrá ver desde fuera, pero no pasar. Vayamos poco a poco».
- **Qué hay** (`godot/scripts/sopiss.gd`, `world.sopiss`, sobre la casa `salvador_24`, sin horneado).
  - El edificio rojo de tres plantas con sus tres fachadas, la banda fucsia «SOPISS · Seguros de toda la vida», balcones de forja, alero de madera y tejado a cuatro aguas.
  - La oficina a la vista por cristales de verdad; no se entra.
  - Luces, penumbra y cartel «ABIERTO»/«CERRADO» según el horario real: lunes a viernes de 9 a 14 y de 17 a 20.
  - Un azafrán escondido en el portal de los pisos (`"id": "sopiss"`).
- **Reparto.** Texturas pasó `salvador_24` a `["obra"]`. Los tres personajes son de Sistemas (`sopiss_gente.gd`), que lee `desk_spots`, `clean_spots` e `is_open`.
- **Archivos.**
  - Nuevos: `godot/scripts/sopiss.gd`, `godot/assets/sopiss/` (10 PNG), `tools/cruce/` (6 scripts), `tools/ign/cruce*.jpg` y `.json`, `guion/fotos/cruce/sopiss_01–04`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`SopissS`, `var sopiss`, paso «Seguros Sopiss», `_build_sopiss()`), `selftest.gd` (`--sopiss`, `_sopiss_checks()` y su llamada tras `_travesia_checks()`).
- **El neón (22/11).** Luis: «El neon de salamanquesa podría brillar en amarillo por la noche». El letrero «Salamanquesa» es azul de día y luz amarilla de noche, con una luz sin sombras en la pared; sigue al cielo (`sky_fx.night`), no al horario. Es más grande que al principio (2,5 m) para que se lea.
- **Prueba.** `sopiss`: 4 ok ([log](logs/selftest_sopiss_20261122_000215.log)).
  - No he pasado la completa ni la prueba de Sistemas con los personajes dentro.
- **Visto de paso, sin tocar.**
  - La calle al sur del edificio es «Calle del Teniente Infante» en el mapa y «Calle Cervantes» en la placa real. Preguntado a Luis.
  - Cada arranque del juego escribe doce veces el error `ARRAY_FORMAT_TEX_UV` al construir la almazara (`_build_almazara`): mezcla piezas con y sin coordenadas de textura en un mismo material. Es mío y viene de antes; no afecta a lo que se ve. **Quitado el 22/11**: los dos faldones de chapa de las naves de atrás se ponen ahora sin esas coordenadas, como el resto de su chapa (`_sheet_slope` en `almazara.gd`). `almazara`: 3 ok y ninguna aparición del error ([log](logs/selftest_almazara_20261122_003121.log)).
- **Visto bueno de Luis (22/11):** «Visto bueno a sopiss».
- **Pendiente.** Las otras esquinas, una por una; los semáforos, el espejo y las señales del cruce. Sin commit (lo hace Sistemas).

### «Clínica Dental», segunda pieza del cruce de los semáforos (22/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Vamos con el dentista. Lo llamaremos "Clínica Dental" y "Dr. Josué Escudero"».
- **Qué hay** (`godot/scripts/clinica.gd`, `world.clinica`, sobre la casa `arcos_2`, sin horneado).
  - La esquina de la calle Cervantes con los Arcos: planta baja de piedra oscura con tiras de acero y letras en relieve, ventanas de espejo con sus palabras, puertas de lamas y puerta de la clínica.
  - A los Arcos, además, el portal de la casa entre granito gris, tras una cortina rosa.
  - Arriba, el balcón corrido de chapa que dobla la esquina, tres balcones de forja y el alero de madera.
  - Sin azafrán: puse uno en el portal de la casa y Luis lo mandó quitar (ver abajo).
- **Añadido mío, sin pedir**: los cristales tienen una luz tenue mientras está abierta (horario real: L–V 9–13:30 y 16:30–20) y las letras se iluminan de noche.
- **Código común nuevo**: `godot/scripts/esquina.gd` recoge lo que comparten los edificios del cruce (tejado por faldones, aleros, medianeras, sólidos). `sopiss.gd` pasa a extenderlo; su prueba sigue en 4 ok tras el cambio ([log](logs/selftest_sopiss_20261122_001746.log)).
- **Reparto.** Texturas pasó `arcos_2` a `["obra"]`. No hay personajes.
- **Archivos.**
  - Nuevos: `godot/scripts/clinica.gd`, `godot/scripts/esquina.gd`, `godot/assets/clinica/` (7 PNG), `tools/cruce/dibujos_clinica.py`, `guion/fotos/cruce/clinica_01–03`.
  - Cambiados, míos: `godot/scripts/sopiss.gd`, `tools/cruce/capturas.py`, `mide.py`, `hojas.py`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`ClinicaS`, `var clinica`, paso «the dental clinic», `_build_clinica()`), `selftest.gd` (`--clinica`, `_clinica_checks()` y su llamada tras `_sopiss_checks()`).
- **Prueba.** `clinica`: 2 ok ([log](logs/selftest_clinica_20261122_002736.log)).
  - No he pasado la completa.
- **Visto bueno de Luis (22/11):** «Visto bueno. No renombres. Quita ese azafrán escondido, sigue proponiendolos y yo te digo en cada proyecto si lo añadimos o lo quitamos».
  - La clínica queda aprobada.
  - La calle de abajo no se renombra en el mapa.
  - El azafrán de la clínica, quitado; su cortina cierra el portal entero. **Norma nueva**: en cada proyecto se propone el azafrán y no se pone hasta que Luis lo diga.
- **Pendiente.** Las otras tres esquinas; los semáforos y las señales. Sin commit (lo hace Sistemas).

### La gente de dentro de «Seguros Sopiss» (21–22/11, Claude · Sistemas)

- **Encargo de Luis** (por Pretil, y después en directo): «dos NPCs genéricos hablando de seguros cuando abierto, y una señora de la limpieza cuando cerrado»; «Que se oiga a través del cristal, el seguro lo vende una mujer rubia con americana, el que recibe el seguro cambia cada vez. La de la limpieza va tarareando música».
- **Qué hay** (`godot/scripts/sopiss_gente.gd`, `game.sopiss_gente`; lee `world.sopiss`: `is_open`, `desk_spots`, `clean_spots`).
  - Abierto: la vendedora (rubia, americana azul oscuro con blusa en pico) tras el mostrador y un cliente delante.
  - A menos de 9 m del cristal se oye una charla entera, frase a frase sobre sus cabezas (Loc `sopiss_charla`, 10 charlas).
  - Cuando acaba la charla o te vas, el siguiente cliente se sienta sin que nadie mire. Es otra persona y trae otra charla.
  - Cerrado (también de 14 a 17): la limpiadora, con bata y fregona, hace la ronda de `clean_spots`. Tararea una melodía hecha en el propio juego, sin canción concreta, apagada por el cristal (clase `Hum`), con «♪ la-ra-ra ♪» sobre la cabeza (Loc `sopiss_tarareo`).
  - Hablarles a través del cristal: contestan desde dentro (Loc `sopiss_cristal`, `sopiss_cristal_limpia`).
  - Son vecinos anónimos (`id ""`, `still`) con meta `sopiss`; no entran en `named`, así que no firman ni reciben pedidos.
- **Archivos**: nuevo `sopiss_gente.gd`; añadidos en `game.gd` (preload, var, setup, tick, gancho al principio de `talk_to`), `loc.gd` (las cuatro claves) y `selftest.gd` (`_sopiss_gente_checks`, modos `--sopiss_gente` y `--sopiss_gente_fotos`, llamada en la completa tras `_marciano_checks`).
- **Pruebas.** `sopiss_gente`: 10 ok con la oficina de verdad ([log](logs/selftest_sopiss_gente_20261122_003019.log)). `palabros`: ok. Fotos en `godot/shots/sopiss_gente_*`. No se ha pasado la completa.
- **Visto bueno de Luis a Sopiss (22/11).** Sin commit todavía.

### La casa blanca de Santa Ana 2, tercera pieza del cruce de los semáforos (22/11, Claude · Edificios Especiales)

- **Encargo de Luis**, con una captura de Street View: «Vamos a tratar de terminar el cruce de los semáforos para poner definitivamente los semáforos. El siguiente será Calle Santa Ana, 2».
- **Qué hay** (`godot/scripts/stana2.gd`, `world.stana2`, sobre la casa `constitucion_a1`, sin horneado).
  - La casa encalada de la esquina de Santa Ana con los Arcos: zócalo de mampostería, portón de madera con clavos, ventanas con reja, marcos añil, balconcillos, cornisa blanca con las bocas de las tejas y chimenea.
  - A los Arcos, la ventana con reja, el portal con cortina morada y la placa de la calle.
  - Detrás, la construcción del fondo, lisa.
  - Sin azafrán: propuesto a Luis junto al portón.
- **Reparto.** Texturas pasó `constitucion_a1` a `["obra"]`. No hay personajes ni horario.
- **Archivos.**
  - Nuevos: `godot/scripts/stana2.gd`, `guion/fotos/cruce/stana2_01–02`.
  - Cambiados, míos: `tools/cruce/capturas.py`, `mide.py`, `hojas.py`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`Stana2S`, `var stana2`, paso «the white house of Santa Ana», `_build_stana2()`), `selftest.gd` (`--stana2`, `_stana2_checks()` y su llamada tras `_clinica_checks()`).
- **Pruebas.** `stana2`: 2 ok ([log](logs/selftest_stana2_20261122_004858.log)).
  - `clinica`, ya sin su azafrán: 2 ok ([log](logs/selftest_clinica_20261122_004718.log)).
  - No he pasado la completa.
- **Visto bueno de Luis (22/11):** «No se pone Azafrán. Visto Bueno. Siguiente».
- **Pendiente.** Las dos esquinas que quedan; los semáforos y las señales. Sin commit (lo hace Sistemas).

### La casa crema del mirador, cuarta pieza del cruce de los semáforos (22/11, Claude · Edificios Especiales)

- **Encargo de Luis**, tras aprobar Santa Ana 2: «No se pone Azafrán. Visto Bueno. Siguiente». De las dos esquinas que quedaban he seguido por la del mirador.
- **Qué hay** (`godot/scripts/mirador.gd`, `world.mirador`, sobre la casa `constitucion_2`, sin horneado).
  - La casa de 1925 de la esquina de la avenida con Santa Ana: revoco crema con zócalo, recercos, balcones y cornisa en ocre.
  - En el chaflán, el portal con cortina y el mirador encima.
  - A la avenida y a Santa Ana, ventanas con reja, balcones de antepecho macizo y las placas de las calles.
  - A Santa Ana, además, la parte blanca con el portón de arco y la galería de madera.
  - Un acerado propio ante el chaflán y Santa Ana, porque el del pueblo no llegaba a las paredes. Cada punto sale de la pared hasta el bordillo y no más (`_to_kerb()`).
  - Sin azafrán: propuesto a Luis tras el portón de arco.
- **Reparto.** Texturas pasó `constitucion_2` a `["obra"]`. No hay personajes ni horario.
- **Archivos.**
  - Nuevos: `godot/scripts/mirador.gd`, `godot/assets/clinica/placa_santa_ana.png`, `guion/fotos/cruce/mirador_01–02`.
  - Cambiados, míos: `tools/cruce/capturas.py`, `mide.py`, `hojas.py`, `dibujos_clinica.py`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`MiradorS`, `var mirador`, paso «the house with the bay window», `_build_mirador()`), `selftest.gd` (`--mirador`, `_mirador_checks()` y su llamada tras `_stana2_checks()`).
- **Prueba.** `mirador`: 2 ok ([log](logs/selftest_mirador_20261122_013352.log)).
  - No he pasado la completa.
- **Pendiente.** Nada: aprobada por Luis el 22/11, sin azafrán. Sin commit (lo hace Sistemas).

### La casa beige del Salvador, quinta pieza del cruce de los semáforos (22/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Vamos a tratar de terminar el cruce de los semáforos para poner definitivamente los semáforos». Era la última esquina.
- **Qué hay** (`godot/scripts/beige.gd`, `world.beige`, sobre la casa `salvador_c3`, sin horneado).
  - La casa de dos plantas de 1976 al norte del Salvador, en su esquina con la avenida: dos alas de una crujía alrededor de un patio.
  - A la avenida: revoco beige, portal hondo encalado, dos ventanas con reja y tres arriba con barandilla.
  - Al Salvador: revoco gris, cuatro ventanas con reja (una de buche), trampilla, respiraderos y la placa «Calle Salvador».
  - El testero norte, con el yeso de la casa vecina que tiraron.
  - Tejado a dos aguas en cada ala, hecho con dos tejados que se solapan en la esquina.
  - Las naves del patio y del fondo de la parcela, lisas: con `["obra"]` el mapa deja de dibujar las tres piezas de la casa.
  - La tapia de bloques del solar del norte, con su cancela roja: por la avenida y, doblando, por la calle de Colón.
  - Sin azafrán: propuesto a Luis en el fondo del portal.
- **Arreglos de paso.**
  - `esquina.gd`, `_inset()`: dos aristas casi en línea ya no se cruzan a cientos de metros. Repetidas las pruebas de los otros cuatro edificios, que usan el mismo kit.
  - `mirador.gd`: su acerado propio busca el bordillo punto a punto (`_to_kerb()`); a ojo se metía 0,83 m en la calzada.
  - `selftest.gd`, en mis modos `--mirador` y `--beige`: `g.traffic.clear()` antes de cada captura.
- **Reparto.** Texturas pasó `salvador_c3` a `["obra"]`. No hay personajes ni horario.
- **Archivos.**
  - Nuevos: `godot/scripts/beige.gd`, `godot/assets/clinica/placa_salvador.png`, `guion/fotos/cruce/beige_01–03`.
  - Cambiados, míos: `godot/scripts/esquina.gd`, `mirador.gd`, `tools/cruce/capturas.py`, `mide.py`, `hojas.py`, `dibujos_clinica.py`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`BeigeS`, `var beige`, paso «the house north of the Salvador», `_build_beige()`), `selftest.gd` (`--beige`, `_beige_checks()` y su llamada tras `_mirador_checks()`).
- **Pruebas.** `beige`: 2 ok ([log](logs/selftest_beige_20261122_020647.log)). Tras el cambio del kit: `sopiss` 4 ok; `clinica` 2 ok; `stana2` 2 ok; `mirador` 2 ok.
  - No he pasado la completa.
- **Pendiente.** Nada: Luis aprobó esta casa y la del mirador el 22/11 («Visto bueno. Sin azafrán. Pasamos a semáforos»). Los semáforos están en la entrada siguiente. Sin commit (lo hace Sistemas).

### Semáforos, espejo y señales, sexta pieza del cruce de los semáforos (22/11, Claude · Edificios Especiales)

- **Encargo de Luis**: «Visto bueno. Sin azafrán. Pasamos a semáforos». Con eso aprobó la casa del mirador y la casa beige, sin azafrán en ninguna.
- **Qué hay** (`godot/scripts/cruce.gd`, `world.cruce`, sin horneado y sin casa del mapa).
  - Cinco postes de semáforo y un báculo con brazo sobre Santa Ana: 7 cabezas de tres luces y 7 de peatones, con sus pulsadores.
  - Una cabeza en escuadra y el ceda el paso en la fachada de Sopiss al Salvador.
  - El espejo redondo y un STOP en un poste ante Sopiss; prohibido autobuses a Cervantes.
  - Prohibido el paso al Salvador (con su placa) y a Santa Ana; prohibido girar a la derecha sobre STOP en la esquina de la casa blanca; prohibido parar en la avenida; prohibido aparcar en la pared de la clínica.
  - El armario gris de la casa beige y la papelera de la casa blanca.
  - En la calzada, la línea de detención de cada calle que trae coches y el paso de cebra de la avenida al norte del Salvador.
  - Las lentes brillan con su material: no hay luces nuevas.
- **Se rompen de un golpe** (Luis, 22/11: «Solo añadiría que se puedan romper con un golpe, una vez rotos pasan a funcionar como ámbar. Se arreglan igual que el resto de objetos rompibles»).
  - Los postes, el báculo, el armario y la papelera son 14 cuerpos sueltos que `props.gd` adopta (`adopt()`, nueva): un coche o un puñetazo los tumba como al resto del mobiliario.
  - Sistemas añadió dos ganchos a `_knock` y `cruce.gd` se los pone a sus cuerpos: `on_knock` (avisa en el momento de la caída; los 14) y `keep` (no se borra a los 40 s; los siete que llevan luces o las mandan). Un semáforo caído se queda tirado; una señal o la papelera desaparecen como el resto.
  - Con un semáforo o el armario caídos, `world.cruce.broken` es `true` y todo el cruce parpadea en ámbar; `semaforos.gd` lo trata como su ámbar de madrugada.
  - `world.cruce.repair()` lo levanta todo. Se arreglan al día siguiente, como el resto del mobiliario (decisión de Luis del 22/11, «Al día siguiente», que llegó por Sistemas): `props.gd` (`mend()`, de Sistemas) llama a `world.cruce.repair()` cuando hay algo caído (`broken` o `down > 0`), ya es otro día que el de la última caída y no se ve el punto de parada de la avenida. Hasta entonces el semáforo caído sigue tirado y el cruce en ámbar. Al cargar la partida todo está en pie. `world.cruce.fallen()` da los sitios que el arreglo cambiaría.
  - Lo que cuelga de una pared (ceda el paso y cabeza de Sopiss, prohibido aparcar de la clínica) no se rompe.
- **Cómo se midió.** 42 vistas `x_` de Street View y `tools/cruce/postes.py`, que cruza rumbos desde varias cámaras (±0,7 m). Cada cosa va por su sitio a lo largo de la fachada más cercana; `_stand()` la arrima a la pared donde la acera del juego es más estrecha.
- **Reparto con Sistemas.**
  - `cruce.gd` da `heads`, `walk`, `set_light()`, `set_walk()`, `auto`, `restart()`, `lights()` y `put_back()`.
  - `semaforos.gd` (Sistemas) lleva el ciclo, el ámbar intermitente de 1 a 7 y los coches que paran. Pone `auto` a `false`; sin él, `cruce.gd` lleva un ciclo propio solo de luces.
  - Luis decidió que los semáforos solo paran a los coches del pueblo, y que el último tramo de Santa Ana sea de sentido único hacia el cruce (`ONE_WAY_FIX`, de Sistemas).
  - Los nombres `avenida` y `arcos` de `heads` no se pueden cambiar: Sistemas los usa para el STOP de noche.
- **Archivos.**
  - Nuevos: `godot/scripts/cruce.gd`, `tools/cruce/postes.py`, `guion/fotos/cruce/cruce_01–05`.
  - Cambiados, míos: `tools/cruce/capturas.py`, `hojas.py`, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).
  - Compartidos, solo con añadidos y con aviso: `world.gd` (`CruceS`, `var cruce`, paso «the crossroads' traffic lights», `_build_cruce()`), `selftest.gd` (`--cruce`, `_cruce_checks()` y su llamada tras `_beige_checks()`), `props.gd` (`adopt()`, tras `_knock`).
- **Pruebas.** `cruce`: 5 ok ([log](logs/selftest_cruce_20261122_031520.log)); `arreglos` (la prueba de Sistemas de la regla del día siguiente, con este cruce): 2 ok ([log](logs/selftest_arreglos_20261122_031706.log)).
  - Sistemas ha pasado su prueba `semaforos` sobre este cruce con coches de verdad: 8 ok, con dos coches esperando en la linea de la avenida. No he pasado la completa.
- **Cómo verlo en el juego.** Ir al cruce de la avenida de la Constitución con Santa Ana: los semáforos cambian solos y los coches del pueblo paran en las líneas. Dar un puñetazo a un poste con semáforo, o tumbarlo con un coche: todo el cruce queda en ámbar intermitente.
- **Pendiente.** El visto bueno de Luis. Sin poner: las farolas de brazo de las fachadas, los carteles de dirección y el semáforo siguiente de la avenida. Sin commit (lo hace Sistemas).

### Hoja de relevo de Edificios Especiales (22/11, Claude · Edificios Especiales)

22 de noviembre de 2026. Luis va a pasar el trabajo de Edificios Especiales a otra IA mientras esta sesión está en pausa («Para aliviar carga le voy a pasar tu trabajo a otra IA mientras tanto») y pidió preparar lo necesario para que no se estropee.

- **Hecho.** [RELEVO_EDIFICIOS_ESPECIALES.md](RELEVO_EDIFICIOS_ESPECIALES.md), en la raíz: qué es el papel, qué leer antes, lo que puede estropear el trabajo (git, Godot, horneado, archivos compartidos y de otros, nombres que usan `semaforos.gd` y `props.gd`), las normas de Luis que solo estaban en la memoria de Claude, cómo se hace un lugar, el estado del cruce y qué dejar escrito al terminar.
- **Archivos.** `RELEVO_EDIFICIOS_ESPECIALES.md` (nuevo) y este registro. Sin cambios en el juego: no hay prueba.
- **Pendiente.** Casi todo el cruce son archivos sin seguimiento de git. Conviene un commit de Sistemas antes de que empiece la otra IA; se le ha dicho a Luis, que decide.
- **Para Claude al volver.** Leer las entradas posteriores a esta, con `git status --short` y `git diff`, antes de tocar nada.

### Semáforos que funcionan, el último tramo de Santa Ana y lo roto que vuelve (22/11, Claude · Sistemas)

- **Encargo de Luis**: «Solo paran coches» (qué hacen los semáforos), «Solo el último tramo» (Santa Ana de sentido único), «Al día siguiente» (cuándo se arregla lo roto). El cruce (`cruce.gd`) es de Edificios Especiales.
- **Semáforos** (`godot/scripts/semaforos.gd`, `game.semaforos`):
  - El ciclo: el grupo 0 (avenida y Arcos) tiene 16 s de verde y el 1 (Salvador y Santa Ana) 11 s; después 3 s de ámbar y 1,5 s de rojo en los dos.
  - Ámbar intermitente de 1 a 7, y también mientras `world.cruce.broken`. Entonces solo paran un momento en la línea los de «avenida» y «arcos», que tienen STOP.
  - Manda sobre `cruce.set_light` y `cruce.set_walk` y pone `cruce.auto = false`. Se engancha al tráfico en su primer tick, porque el tráfico se crea después.
  - `traffic.gd`: `lights.gap()` frena el coche a 3 m/s² hasta su línea y lo deja esperando (`at_light`). Los de detrás lo ven como «en marcha» y hacen cola en vez de adelantar. Los de servicio y el piloto automático no paran.
- **Santa Ana**: `map_data.gd` `ONE_WAY_FIX`, del Romero (969) al cruce (974), solo hacia el cruce, sin rehornear. `one_way_says` lo lee primero.
- **Lo roto vuelve al día siguiente** (`props.gd`):
  - `_knock` guarda dónde estaba la pieza. A los 40 s se esconde (`_tidy`) en vez de borrarse.
  - `mend()` la vuelve a poner cada 2 s si ya es otro día y no se ve. Los árboles también (`world.unfell_tree`).
  - Lo que lleva la meta `on_knock` es del dueño: el cruce se arregla entero con `cruce.repair()` cuando no se ve ninguno de los sitios de `cruce.fallen()`. Con `keep` no se borra a los 40 s.
- **Pruebas.** `semaforos`: 9 ok (ciclo, caras, distancia a la línea, noche y STOP, roto, Santa Ana, un coche de verdad que para en rojo y sigue en verde, todo sobre el cruce de verdad). `arreglos`: 2 ok. `sentido` y `grua` ok. Foto: `--semaforos_fotos`.

## Cómo mantener el registro

Añadir una entrada por tarea con la fecha, el motivo y el resultado del cambio, los archivos principales, la prueba ejecutada y su resultado, y cualquier decisión o pendiente que Claude necesite conocer. Si el comportamiento cambia de cara al jugador, incluir cómo reproducirlo en el juego. Indicar las comprobaciones que queden pendientes y anotar el hash si se crea un commit.

Para cambios del juego, seguir las normas de [PROJECT_STATE.md](PROJECT_STATE.md) y ejecutar `python tools/run_tests.py <modo>` desde este repositorio para el modo afectado. Anotar aquí los resultados nuevos y enlazar a la documentación específica de la tarea cuando exista.

### Calles de la Parra, del Descanso y de la Pastora: 26 casas (22/11, Claude · Texturas)

22 de noviembre de 2026, Texturas (Claude). El usuario retomó las calles («Seguimos»).

- **Hecho.** 26 entradas:
  - `par_4`, `par_2`, `par_1`, `par_3`, `par_5`, `par_3b`, `par_7`;
  - `des_14`, `des_12`, `des_10`, `des_8`, `des_6`, `des_4`, `des_13`, `des_11`, `des_9`, `des_aa31`, `des_7d`, `des_3`;
  - `pas_6`, `pas_4`, `pas_2`, `pas_2a`, `pas_3`, `pas_1d`, `pas_1`.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Parcelas partidas.**
  - Parra 3 tiene dos frentes, separados por el 5: `par_3` (dos plantas) y `par_3b` (`only` 1, el trozo junto al 7).
  - El portón verde de Descanso 11 es la parte de una planta de la parcela de Travesía del Santo 8 (4296603). Va en `des_11`, con `only` 1 y `reach` 2; `trsanto_8` se queda con lo de dos plantas.
- **Calle desplazada.** En el lado norte de la Parra, la calle del mapa va unos 2 m al norte de la real. Frentes del muro genérico (`frente_gen.py`), con `clear` 1 (1,4 en `par_1`).
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (26 entradas);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/parra_descanso_pastora_1..4.jpg`;
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Tres horneados, avisando a Pretil antes y después de cada uno.
  - El primero dejó fuera la caja hecha a mano del 11 (3,4 m²: `add_part` quita lo que tiene menos de 5 m²).
  - En la hoja de repaso se vio que ese sitio era de `trsanto_8`. El tercer horneado lo arregló.
  - Frente a la copia: 26 casas nuevas, ninguna quitada. `real_83`, `real_85`, `santo_62`, `santo_80`, `alto_29` y `alto_57` solo cambian en las aristas tapadas.
  - Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 26: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_par_4_par_2_par_1_par_3_par_5_par_3b_par_7_des_14_20261122_010656.log)).
  - Tras arreglar `des_14` y `des_11`: 4 ok ([log](logs/selftest_casas_solo_des_14_des_13_des_11_des_9_20261122_011352.log)).
- **Casas cedidas a Edificios Especiales (21–22/11).** A petición de Pretil, para el cruce de los semáforos, estas casas pasan a `["obra"]` en `casas_calles.gd`:
  - `salvador_24` (Seguros Sopiss);
  - `arcos_2` (la clínica dental);
  - `constitucion_a1` (Santa Ana 2);
  - `constitucion_2` (la casa del mirador);
  - `salvador_c3` (la casa de dos plantas al norte del Salvador, en la esquina de la avenida: la última del cruce, que Pretil hace en `beige.gd`).
  - Sus entradas de `calles.json` no se tocan. Las líneas viejas están en las notas compartidas de las sesiones (`*_antes_de_pretil.md`).
- **Aprobado** por el usuario el 22/11 («Añade la bandera de españa ahí y damos visto bueno»). La bandera cuelga de la ventana de arriba a la izquierda del Descanso 9: `_des_9()` en `godot/scripts/casas.gd`, con `casas` 4 ok ([log](logs/selftest_casas_solo_des_9_20261122_011859.log)).

### Avenida de la Reina Sofía, lo que faltaba: 19 casas (22/11, Claude · Texturas)

22 de noviembre de 2026, Texturas (Claude). El usuario pidió seguir con la siguiente calle («Sí, siguiente»).

- **Hecho.** 19 entradas:
  - lado de los impares (5 a 31): `rsof_31n`, `rsof_31`, `rsof_29`, `rsof_27`, `rsof_25`, `rsof_23`, `rsof_21`, `rsof_19`, `rsof_17`, `rsof_15`, `rsof_13`, `rsof_11`, `rsof_9`, `rsof_7`, `rsof_5`;
  - lado de los pares (4 a 12): `rsof_12`, `rsof_10`, `rsof_6`, `rsof_4`.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Parcelas partidas y retoques de datos.**
  - El 31: la casa de dos plantas son los 8,6 m de la izquierda (`rsof_31`, con `porch` [8,6, 16, 5,6] que corta el resto de la parte del Catastro). La nave blanca de la esquina va en `rsof_31n`, una caja sin referencia (`rc` None, `deep` 5,4, 4 m de alto) con su puerta gris en el costado.
  - El 12: frente en el borde de la parte de dos plantas, `floors` 2 y `strip` 1 para quitar la tira de una planta de delante.
  - El 11: `floors` 1 y `reach` 14 (dos plantas en las fotos).
- **Edificio nuevo.** El 10 es una fachada de celosía de ladrillo claro. Su línea en `casas_calles.gd` pone el portón y las ventanas azules, y `_rsof_10()` en `godot/scripts/casas.gd` dibuja los huecos de la celosía (un damero de cuadros oscuros, con algunos azulejos azules sobre la franja azul).
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (19 entradas);
  - `godot/scripts/casas.gd` (`_rsof_10`);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/reina_sofia_1..4.jpg`;
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Un horneado, avisando a Pretil antes y después. Frente a la copia: 19 casas nuevas, ninguna quitada. `cajal_rs2` solo cambia en las aristas tapadas. Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 19: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_rsof_31n_rsof_31_rsof_29_rsof_27_rsof_25_rsof_23__20261122_014527.log)).
  - Tras los arreglos de color y la puerta de la nave: 4 ok ([log](logs/selftest_casas_solo_rsof_31n_rsof_27_rsof_23_rsof_21_rsof_11_rsof_10_20261122_014823.log)).
- **Aprobado** por el usuario el 22/11 («Visto bueno y siguiente»).

### Calle de las Delicias, primera mitad: 19 casas y el arreglo del 10 (22/11, Claude · Texturas)

22 de noviembre de 2026, Texturas (Claude). El usuario aprobó la Reina Sofía y pidió la siguiente calle («Visto bueno y siguiente»).

- **Hecho.** 19 entradas nuevas:
  - impares: `delicias_3`, `delicias_5`, `delicias_7`, `delicias_17b`, `delicias_19`, `delicias_21`, `delicias_19b` (la nave), y la hilera de atrás `delicias_21r1..5` con el muro de sus patios `delicias_21t`;
  - pares: `delicias_12`, `delicias_28`, `delicias_30`, `delicias_32`, `delicias_32g`, `delicias_36`.
  - `delicias_10` cambia de línea: ahora es crema, con el marco mostaza y el portón de tablas de Street View.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Herramientas nuevas.**
  - `fill` en `tools/casas/calles.json` (lo lee `tools/bake_godot.py`, antes del bucle de las cajas sin `rc`): `[[desde, hasta, fondo], ...]` en metros a lo largo del frente y hacia atrás. Añade una caja al grupo de la casa hecha a mano. Sirve para el suelo que el Catastro deja fuera: el 3, que dibuja 4 m detrás de la calle, y el porche del 17, que tiene 0 plantas. Se avisó a Pretil, porque es una herramienta común.
  - `arc` con `sq=1` (hueco recto: un porche o un portal metido en la casa), `gh=<m>` (cancela baja de hierro) y `bd=<color>` (puerta al fondo). Está en `godot/scripts/casas.gd`.
  - `_sillares(spec, y0, junta)`: juntas claras de sillería sobre el revoco, que dejan libres los huecos (`_holes_of`). La usan `_delicias_28()` y `_delicias_30()`.
  - `_hilera21(lado)` y la tabla `HILERA21` en `casas_calles.gd`: los adosados de 2008, con el lado del porche de cada uno.
- **Ojo (lección).** Primero entró el reparto a `HILERA21` en `casas.gd` y la tabla en `casas_calles.gd` llegó un momento después. La prueba `grua` de Sistemas, a las 02:19, cogió ese hueco y falló («Cannot find member "HILERA21"»). El código y los datos que lee van juntos, en el mismo paso.
- **Archivos.**
  - `tools/casas/calles.json` (19 entradas) y `godot/scripts/casas_calles.gd` (14 líneas, `HILERA21`, la línea del 10);
  - `godot/scripts/casas.gd` (`_hilera21`, `_sillares`, `_holes_of`, `_delicias_28`, `_delicias_30`, las opciones del `arc`);
  - `tools/bake_godot.py` (`fill`);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/delicias_1..4.jpg`;
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Un horneado, avisando a Pretil antes y después. Frente a la copia: 19 casas nuevas, ninguna quitada. `delicias_10` solo cambia en las aristas tapadas. Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 19: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_delicias_3_delicias_5_delicias_7_delicias_17b_del_20261122_022436.log)).
  - Tras los arreglos: 4 ok ([log](logs/selftest_casas_solo_delicias_3_delicias_17b_delicias_19_delicias_21_d_20261122_023203.log), [log](logs/selftest_casas_solo_delicias_12_20261122_023428.log), [log](logs/selftest_casas_solo_delicias_3_delicias_17b_delicias_21_20261122_023601.log)).
- **Aprobado** por el usuario el 22/11 («Visto bueno y siguiente»). La segunda mitad de la calle va en la tanda siguiente.

### Calle de las Delicias, segunda mitad: 17 casas (22/11, Claude · Texturas)

22 de noviembre de 2026, Texturas (Claude). El usuario aprobó la primera mitad y pidió seguir («Visto bueno y siguiente»).

- **Hecho.** El lado sur, del 36 D al 68:
  - `delicias_36d`, `delicias_40`, `delicias_40b`, `delicias_42`, `delicias_44`, `delicias_46`, `delicias_48`, `delicias_50`, `delicias_52`, `delicias_54`;
  - `delicias_56`, `delicias_58`, `delicias_60`, `delicias_62`, `delicias_64`, `delicias_66`, `delicias_68`.
  - Datos del Catastro de 13 parcelas nuevas con `tools/house_data.py`, en `tools/casas/<rc>/`.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **Cajas sin referencia.**
  - `delicias_40`: la tapia del solar, 10 m, de 2,5 m de alto y 0,6 m de fondo.
  - `delicias_40b`: la casa de dos plantas que el Catastro cubre con el solar del 40, de 9 m de fondo.
  - `delicias_54`: el corral entre el 52 y el 56, que no está en el Catastro, de 0,7 m de fondo.
  - Ojo: una caja de menos de 5 m² se pierde en el horneado.
- **Código.** `_delicias_64()` en `godot/scripts/casas.gd`: la galería de madera (suelo volado, cabezas de vigas, barandilla, postes, tabla del alero) y los dinteles de madera. Entró en el mismo paso que su línea en `casas_calles.gd`.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (17 entradas);
  - `godot/scripts/casas.gd` (`_delicias_64`);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/delicias_5..7.jpg`;
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Un horneado, avisando a Pretil antes y después. Frente a la copia: 17 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 17: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_delicias_36d_delicias_40_delicias_42_delicias_44__20261122_030132.log)).
  - Tras los arreglos de color: 4 ok ([log](logs/selftest_casas_solo_delicias_50_delicias_54_delicias_58_delicias_60_d_20261122_030403.log)).
- **Aprobado** por el usuario el 22/11 («Visto bueno y siguiente»). Con esto la Calle de las Delicias queda entera.

### Calle de Tembleque, lo que faltaba: 19 casas (22/11, Claude · Texturas)

22 de noviembre de 2026, Texturas (Claude). El usuario aprobó Delicias entera y pidió la calle siguiente («Visto bueno y siguiente»).

- **Hecho.**
  - Lado oeste: `tembleque_29`, `tembleque_31`, `tembleque_33`, `tembleque_35`, `tembleque_53`, `tembleque_89d`, `tembleque_91`, `tembleque_93`, `tembleque_95`, `tembleque_99`.
  - Lado este: `tembleque_34`, `tembleque_34b`, `tembleque_36`, `tembleque_38`, `tembleque_40`, `tembleque_42`, `tembleque_44`, `tembleque_46`, `tembleque_48d`.
  - Datos del Catastro de 19 parcelas nuevas con `tools/house_data.py`, en `tools/casas/<rc>/`.
  - Fotos del Catastro y Street View de noviembre de 2024. Lo que no se parece está en `guion/repaso_casas.md`.
- **El solar del 48 D.** El Catastro dibuja una tira de casas viejas que ya no están: en Street View hay una tapia de ladrillo.
  - `porch: [10.2, 36, 8]` quita esa tira.
  - `fill: [[10.2, 32.83, 0.5]]` pone en su sitio la tapia, de medio metro.
  - Se queda el cobertizo viejo de la punta norte; todo a 2,6 m.
- **Fuera.**
  - El 57: en el Catastro solo tiene una franja de 2 m en la calle, y su casa queda detrás de la fachada del 59.
  - Tembleque 2: un solar sin plantas que da a otra calle.
  - Consuegra 1 y 2: dan a la Calle de Consuegra.
- **Archivos.**
  - `tools/casas/calles.json` y `godot/scripts/casas_calles.gd` (19 entradas);
  - `godot/data/map.json`;
  - las hojas `guion/fotos/tanda34/tembleque_10..14.jpg` (las 1..9 son de la tanda del 16/11 y siguen como estaban);
  - `PROJECT_STATE.md` y `guion/repaso_casas.md`.
- **Mapa.** Un horneado, avisando a Pretil antes y después. Frente a la copia: 19 casas nuevas, ninguna quitada; de `rsm_26` y `rsm_28` solo cambian las aristas tapadas. Calles, nodos, relieve y árboles (2954), iguales.
- **Pruebas.**
  - `casas` de las 19: 4 ok, 0 fallos ([log](logs/selftest_casas_solo_tembleque_29_tembleque_31_tembleque_33_tembleque__20261122_032755.log)).
  - Tras los arreglos de color del 35 (`brick_dark`) y del 95 (`brick_red`): 4 ok ([log](logs/selftest_casas_solo_tembleque_35_tembleque_95_20261122_033052.log)).
- **Aprobado** por el usuario el 22/11 («Visto bueno y paramos de momento»). Las calles quedan en pausa hasta nueva orden.

### La prueba completa de la 0.0.21: siete fallos de las pruebas, no del juego (22/11, Claude · Sistemas)

22 de noviembre de 2026. La primera prueba completa de la 0.0.21 dio 976 ok y 7 fallos. Ninguno era un error del juego. Todos se arreglaron en `godot/scripts/selftest.gd`:
- **Muros y fachadas.** Las comprobaciones pedían más de 25.000 muros y más de 4.000 fachadas genéricas. Hay menos porque los sitios hechos a mano las sustituyen. Ahora piden más de 24.000 y más de 3.500.
  - **Ojo, Pretil y Texturas:** quedan unos 770 muros de margen (hay 24.770) y unas 360 fachadas (hay 3.863). Cada sitio hecho a mano los baja; si salta, bajad el umbral, no es un error.
- **Mobiliario «fuera de sitio» (14).** Los semáforos, señales y papelera del cruce cuelgan de `world.cruce`, que va desplazado `level` en altura. La comprobación usaba `position.y` (local); ahora usa `global_position.y`.
- **Robar el coche de un vecino** (fallaba a veces). La prueba cogía el primer coche de la lista, que podía ir «sobre raíles» (lejos, sin física). Al ponerlo junto a ti volvía a la física a su velocidad de antes (8 m/s) y ya no estaba «parado». Ahora se le quitan los raíles, se le pone `halt` y velocidad cero.
- **La cama** («dos horas después de acostarte no puedes volver a dormir»). En medio de la prueba sonaba la llamada de la Tía Paca por la casa (`casa_paca_call`, dos horas de juego después del puente). `_casa_checks` deja al acabar «una casa tranquila», pero solo si antes no había estado de casa, y el tick de `fondo_casa.gd` crea `{"st": ""}` al principio. Ahora también lo hace si el estado guardado está sin empezar.
- **Los días en `_mend_checks`.** La prueba de lo roto adelantaba `day_n` durante dos fotogramas, y `llamadas.now()` cuenta los días. Ahora lo devuelve antes de esperar ningún fotograma.
- **El semáforo con coche real.** A veces un peatón cruzaba delante del coche de la prueba y lo paraba antes de la línea. Los vecinos a menos de 70 m se apartan (`away`) mientras dura.
- **El pedido de Henry** (fallaba a veces en la completa, nunca solo). Ahora la comprobación acepta el tope de confianza (100) y su mensaje dice qué condición falla. Puede que la causa fuera ese tope, pero **no está confirmado**: si vuelve a fallar, el mensaje lo dirá.
- **Finales de línea.** `game.gd`, `world.gd`, `props.gd`, `selftest.gd`, `traffic.gd`, `map_data.gd` y `semaforos.gd` habían pasado a CRLF por ediciones con Python. Vuelven a LF, como en el repositorio. `loc.gd` sigue en CRLF, como estaba. **Pretil y Texturas:** releed esos ficheros antes de editarlos.
- **Prueba completa:** 983 ok, 0 fallos ([log](logs/selftest_full_20261122_051320.log)).
- **Memoria con el renderizador de móvil** (`--rendering-method mobile -- --timing`): 752 MB al acabar la carga (893 en la 0.0.11) y 1.988 MB de vídeo; carga de 42 s en este PC.
