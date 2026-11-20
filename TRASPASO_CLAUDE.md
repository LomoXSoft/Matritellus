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
- **Pendiente:** la casa de Matías Pérez 16 sale como hueco hasta que Pretil la haga a mano (aviso de Texturas).

## Cómo mantener el registro

Añadir una entrada por tarea con la fecha, el motivo y el resultado del cambio, los archivos principales, la prueba ejecutada y su resultado, y cualquier decisión o pendiente que Claude necesite conocer. Si el comportamiento cambia de cara al jugador, incluir cómo reproducirlo en el juego. Indicar las comprobaciones que queden pendientes y anotar el hash si se crea un commit.

Para cambios del juego, seguir las normas de [PROJECT_STATE.md](PROJECT_STATE.md) y ejecutar `python tools/run_tests.py <modo>` desde este repositorio para el modo afectado. Anotar aquí los resultados nuevos y enlazar a la documentación específica de la tarea cuando exista.
