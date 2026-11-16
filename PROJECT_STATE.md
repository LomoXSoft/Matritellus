# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Sin publicar

Lo detallado de cada pieza está en su LEEME de `referencias/` o `tools/`, en `guion/` y en el historial de git.

- **Sistemas (16/11, sin veredicto): entrar en las tiendas pequeñas y «verde = objetivo».**
  - **La flecha:** delante de la puerta de cada tienda pequeña hay una flecha verde que gira, con un aro de luz en el suelo (`entradas.gd`). Al pisarla entras en el decorado aparte; dentro, otra flecha te saca.
  - **Cuándo se ve:** la de entrar, solo con la tienda abierta y a pie. La de salir, siempre, aunque la tienda cierre contigo dentro.
  - **Qué tiendas:** el V.I.P. y la Papelería Rocas de Pretil (`world.comunal.tienda`). Para añadir otra basta un objeto con `door_out`, `out_spawn`, `out_h`, `in_door`, `in_spawn` y `open`. El Recress, por grande, sigue con su puerta.
  - **En verde:** la flecha guía, la columna de luz de las misiones, y el camino y el punto de destino del mapa (`game.gd`, `minimap.gd`). Sustituye la norma del 15/11 de «luz amarilla para el coche».
  - **Retoques del usuario:**
    - La flecha va al 80 % de opacidad: se dibuja primero la profundidad, con los lados iluminados y un contorno oscuro.
    - «Tienda pequeña» quiere decir cualquier sitio que te lleve a otro: también los recreativos, que ya no tienen puerta en la que meterse andando.
  - **Para salir hay que pulsar la acción** sobre la flecha de dentro: el aviso dice «Salir» (`entradas.exit_here`/`leave`). Para entrar basta con pisar la de fuera.
  - **En escenas, conversaciones y menús no se ven las flechas.** Los avisos se ven también dentro, sobre el jugador.
  - **Al cruzar una puerta** (o si una escena te saca), la flecha que tengas al lado no actúa hasta que te apartes. `recress.gd` pone `_door_cool` al dejarte en la puerta al final de su misión.
  - **Cámara en los interiores** (V.I.P., Recress, Rocas): se quita la primera persona.
    - Andando por la sala: fija en una esquina de la pared de la puerta, bajo el techo, inclinada.
    - Al hablar: por encima del hombro, con la cara de quien habla delante (`entradas.camera`).
    - Las medidas de cada sala salen de sus constantes.
    - También el Kebab Luis (`entradas.town_room`): «Aplicar en todos los recintos pequeños o cerrados. Mejor que la primera persona». Ya no queda primera persona en el juego. `kebab shots` 21/21, con su comprobación de cámara cambiada a la nueva.
  - **Pruebas:** `entradas` 4/4 y `recress` 14/14; esta última ajustada para entrar por la flecha. La comprobación del V.I.P. de la completa pasa por la flecha y queda para la próxima completa.

- **Texturas (16/11): calle del Santo, 66 casas (`santo_*`) en tres tramos, desde la Plazuela del Toledano hasta el 74. «Visto bueno» (16/11).**
  - Hojas en `guion/fotos/tanda26/santo_1..14.jpg`.
  - Del 31 al 37, retranqueadas tras una acera ancha. Los impares del 45 al 73 dan al ramal estrecho. Del 59 al 63 se ponen a 2,7 m de la línea, con `clear`.
  - El 62 queda solo con su casa de esquina: su parcela rodea al 60 (`reach` 6). El 54 lleva `reach` 8.
  - Fuera: los solares 8, 15 D, 17, 19 y 66, y el 40, que da a otra calle.
  - El nº 5, una casona de 1920, podría merecer hacerse a mano: lo decide el usuario.
  - Bake: 66 casas nuevas; cambian las piezas de cuatro vecinas (`arroyuelo_42`, `matias_9`, `trsanto_9d`, `trsanto_11`) y el `clr` de 3 nudos. Calles, relieve y aceras, iguales.
  - `casas solo=santo_`: OK.
  - Último tramo (16/11), 15 casas: del 77 al 95 y del 76 al 86. «Visto bueno» (16/11): calle completa.
    - Hojas en `tanda26/santo_15..17.jpg`. Bake: 15 casas nuevas y nada más cambia. `casas` OK.
    - El 75 es la ermita: queda fuera, para hacerla a mano si el usuario quiere. El 87 da a otra calle.
- **Texturas (16/11): calle de San Rafael, primer tramo, 26 casas (`rafael_*`): del 7 al 29 D y del 4 al 30. «Visto bueno» (16/11).**
  - Hojas en `guion/fotos/tanda27/rafael_1..6.jpg`.
  - Calle estrecha: en la acera par (del 4 al 12, el 26) y en el 29 D, la línea del mapa pasa por encima de las fachadas reales. Esas casas van a 2,7 m del eje, con `clear` 1,0.
  - Fuera: el 1, el 3, el 7 A, el 24 y el 27 no dan a esta calle. Son solares el 7 B, el 9 D y el 28. El 25 es un trozo de tapia vieja que se queda como estaba.
  - Bake: 26 casas nuevas y ninguna otra cambia; cambia el `clr` por las fachadas retiradas. `casas solo=rafael_`: OK.
  - Segundo tramo (16/11), 24 casas: del 31 al 55 y del 32 al 52. «Visto bueno» (16/11).
    - Hojas en `tanda27/rafael_7..11.jpg`. La acera par, otra vez a 2,7 m con `clear`; el 50 D es solar.
    - Bake: 24 casas nuevas y nada más cambia. `casas` OK.
  - Último tramo (16/11), 29 casas: del 59 al 81 y del 56 al 78. «Visto bueno» (16/11): calle completa.
    - Hojas en `tanda27/rafael_12..17.jpg`. El 67, el 68 C, el 70 B, el 76 y el 78 no tienen foto en el Catastro: van por el Street View de 2024.
    - Fuera: el 54 y el 57 no existen; el 68 B, el 71 y el 71 B son solares; el 74 no da a esta calle.
    - Bake: 29 casas nuevas y nada más cambia. `casas` OK. Con esto la calle está completa.
- **Texturas (16/11): Plaza del Toledano, 17 casas (`toledano_*`). «Visto bueno» (16/11).**
  - En el Catastro es «PZ TOLEDANO DEL». Las casas dan a tres líneas del mapa: la plaza, el callejón sin nombre del oeste y el arranque de la calle del Santo.
  - Fuera: el 1 y el 3 dan a la Amargura; el 8 y el 17 son solares; el 11, el 15, el 19 y el 23 quedan atrás, sin dar a ninguna calle.
  - Bake: 17 casas nuevas; solo cambian las piezas de `santo_1` y `amargura_4`, porque ahora tienen vecinas hechas a mano. `casas` OK.
  - Hojas en `guion/fotos/tanda28/toledano_1..4.jpg`.
- **Texturas (16/11): calle Santa Clara, 27 casas (`clara_*`, con el 1 B). «Visto bueno» (16/11), con los arreglos.**
  - En el Catastro es «CL ST CLARA». Las fotos de los impares salen amarillentas y las de los pares, anaranjadas por la luz de tarde: los colores van rebajados.
  - El 4, el 6, el 9 y el 30 van a 2,7 m del eje, con `clear`. Fuera: el 1 B y el 13 quedan atrás; el 7, 12, 23, 25, 27 y 29 no existen.
  - Bake: 26 casas nuevas; solo cambian las piezas de `amargura_1` y el `clr` de las fachadas retiradas. `casas solo=clara_,amargura_1`: OK.
  - Hojas en `guion/fotos/tanda29/clara_1..6.jpg`.
  - Arreglos tras ver el usuario las hojas (16/11):
    - Añadido el 1 B, el edificio amarillo: el Catastro tiene su ficha pero no su contorno. Va como `clara_1b`, con `rc` null, en el hueco de 9,8 m.
    - Rehecho el 28: puerta oscura y terraza con reja.
    - La valla junto al 30 es del viejo colegio (`colegio.gd`): se la he pasado a Pretil.
    - Hoja `tanda29/clara_arreglo.jpg`.
- **Texturas (16/11): calle de Nalda, 17 casas (`nalda_*`). «Visto bueno» (16/11).**
  - El 2, el 3, el 4 y el 9 van a 2,7 m del eje, con `clear`. El 12 y el 14 se pisaban 2 m: se parten por la mitad.
  - El 17 figura como solar en el Catastro, pero está construido (sale en la foto del 15): va como `nalda_17`, con `rc` null.
  - El 18 se queda como estaba: su parcela solo llega a la calle por detrás de una pieza del 20.
  - Fuera: el 1 y el 11 no existen; el 13 es solar; el 21 y el 23 dan a la calle de las Monjas.
  - Bake: 17 casas nuevas; cambian las piezas de `clara_10`, `clara_14` y `nalda_20`, y el `clr`. `casas` OK.
  - Hojas en `guion/fotos/tanda30/nalda_1..4.jpg`.
- **Texturas (16/11): calle del Arroyuelo Alto, primer tramo, 29 casas (`alto_*`): del 1 al 29 y del 2 al 32. «Visto bueno» (16/11), con el 19 y el 7 corregidos.**
  - El 4, el 6, el 8, el 10 y el 16 van a 2,7 m del eje, con `clear`. El 9 lleva `reach` 8: tenía un cuerpo atrás, cuesta arriba.
  - El 31 se queda como estaba: su parcela da a la calle por un cuello estrecho entre corrales y salía roto. El 33 tiene ficha sin contorno. El 24 y el 26 no existen.
  - Bake: 29 casas nuevas; cambian las piezas de `zaragoza_17`, `zaragoza_19`, `alameda_5` y `trsanto_1`, y el `clr`. `casas` OK.
  - El usuario vio ventanas flotando en el 19: el Catastro le da una planta y su altura era de una, pero está descrito con dos. Subido a 6,4 m (`tanda31/alto_19_arreglo.jpg`). El resto de casas está revisado con `flotantes.py`: solo quedan casas bajas con ventanucos de cámara, ya aprobadas.
  - Hojas en `guion/fotos/tanda31/alto_1..7.jpg`. Falta el segundo tramo: del 35 al 63 y del 34 al 50.
  - Pretil pasa `castilla_17` a `["obra"]` para su Kebab Deluxe (`kebabdeluxe.gd`), con el OK de Texturas.

- **Pretil (16/11): el interior de la Papelería Rocas, un decorado aparte** (`rocas.gd`, en `world.comunal.tienda`; lo crea `comunal.gd`). «Visto bueno» (16/11).
  - Está en (-1800, -1800), a 330 m de cualquier cosa del mapa. 7,6 × 12 m: prensa y mochilas junto a la puerta, libros a un lado, papelería al otro, dos mesas, mostrador con su trampilla, fotocopiadora.
  - Da lo que pide `_use_door`: `door_out`, `out_spawn`, `out_h`, `in_door`, `in_spawn` y `open` (lo pone `comunal.set_open`: sigue el horario). También `counter_front` y `keeper_spot`, por si un día alguien la atiende.
  - Muebles del Furniture Kit de Kenney (CC0), el del Kebab: `godot/assets/rocas/`, `tools/rocas/muebles.py`.
  - No toca `world.gd` ni `game.gd`. En `selftest.gd`: una comprobación más en `_comunal_checks` y ocho fotos en `--comunal`. `comunal`: 5/5.
  - La flecha y el paso los hace Sistemas (`entradas.gd`).

- **Pretil (16/11): la Plazuela del Toledano, a mano y sin rehorneado** (`toledano.gd`, `world.toledano`). «Visto bueno» (16/11).
  - La isleta es el anillo peatonal del mapa, recortado a 3,9 m de cada calle del juego; un faldón de asfalto tapa el camino claro de antes.
  - El suelo sigue el relieve (corta cada pieza por las facetas) y se pisa por decks inclinados; el bordillo, con chaflán para los coches.
  - Losas de pizarra entre franjas claras, alcorques, cipreses, árbol, pino, arbolito, cuatro bancos de forja, farola, papeleras, señales y el lápiz.
  - Toca `world.gd` (constante, variable, paso, `_build_toledano`) y `selftest.gd` (modo `toledano`, `_toledano_checks` tras `_comunal_checks`). `toledano`: 4/4.
  - Detalles: `referencias/plazuela_toledano/LEEME.md`.

- **Pretil (16/11): Kebab Deluxe, a mano y sin rehorneado** (`kebabdeluxe.gd`, `world.kebabdeluxe`, sobre `castilla_17`, ahora `["obra"]` con el OK de Texturas). «Ambos visto bueno» (16/11).
  - Fachada azul marino, escaparate blanco, rótulo luminoso y banderola dibujados (`tools/kebabdeluxe/rotulo.py`, teléfonos en garabatos), ventanal de medio punto, terraza y torreón; el comedor y la escalera, por el cristal.
  - Es la primera parada del sabotaje: `sabotaje` entero 45/45. `kebabdeluxe`: 2/2.
  - Toca `world.gd` (constante, variable, paso, `_build_kebabdeluxe`) y `selftest.gd` (modo `kebabdeluxe`, `_kebabdeluxe_checks` tras `_toledano_checks`).
  - Horario del usuario: desde las 13:00 todos los días hasta la 1:30 (lunes a jueves) o las 2:00 (viernes a domingo); abierto, hoja abierta y luces; cerrado, todo apagado. `kebabdeluxe` 3/3. Sin interior. Detalles: `referencias/kebab_deluxe/LEEME.md`.
- **Pretil (16/11): la tapia del viejo colegio en la calle Santa Clara** (`colegio.gd`, `_tapia`), que el usuario echó en falta: ladrillo, reja de forja, puerta oscura y machón, por la foto del Catastro de la casa de al lado. `colegio` 3/3. «Ambos visto bueno» (16/11).

Veredictos: el usuario dio el visto bueno al cuartel de los Tricornios (con su logo y las marcas de sus coches), a la Universidad Comunal con la Papelería Rocas (por fuera y por dentro) y a la Plazuela del Toledano: «Visto bueno a todo. Pensaba que ya lo había dado» (16/11).

## Versión

- **Publicada:** 0.0.9 (16/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.9 — completa de las 04:30: 680 ok, 0 fallos.
  - **Sistemas:**
    - El gacha (`gacha.gd`): 1 € en la máquina del Tele Dürum, figuras de los 24 vecinos con nombre, la página «Colección» de la Agenda (que ya tiene 6 páginas), confeti y trombón triste.
    - El sentido único de OpenStreetMap: `"ow"` en el bake, `traffic.one_way_ok`.
    - Dolores Fuertes D'Varriga en la calle de la Amargura (`walker` con `beat`), con su confesión a 100 de confianza.
    - El coche de los Tricornios en la puerta del cuartel (`cuartel_coche.gd`).
    - El reloj sigue corriendo mientras se juega al ajedrez.
    - Modos de prueba nuevos: `gacha`, `sentido`, `tricornio`, `dolores` y `conduccion`.
  - **Ajedrez humano** (su propia sesión; `ajedrez.gd`, `ajedrez_humano.gd`, `guion/ajedrez.md`): la misión del alcalde y el minijuego, con cuatro niveles que dan 4, 6, 8 y 12 PC, sin límite diario.
  - **Pretil (sobre `obra.gd`):**
    - el Tele Dürum, con horario;
    - los chinos del Arroyuelo;
    - el viejo colegio, con la placa «Instituto Garcilaso de la Vega» como única excepción de nombre real;
    - el cuartel de los Tricornios y las marcas de sus coches;
    - la Universidad Comunal y la Papelería Rocas.
    - En los carteles se escribe «La Mancha».
  - **Texturas:**
    - calles enteras: Valencia, Regidor, Roma, Portugal, Argentina, San Isidro y los Arcos;
    - además, la Rosa de Santa María, la Amargura y la Travesía del Santo.
  - **Worldbuilding:** «tiés» y «ande» (prueba `palabros`).
- **Publicada antes:** 0.0.8 (15/11/2026): farmacia, Caridad, convento de Santa Ana, Mercamona y Todopizza, más las calles de Texturas de ese día.
- **Pendiente (después de la 0.0.9):**
  - **Sistemas:**
    - la flecha verde de entrada a tiendas pequeñas: al pisarla, entras a un interior aparte (`places_in`), empezando por el V.I.P. y la Papelería Rocas;
    - verde = objetivo: la flecha de objetivo y los círculos de misión, en tonos verdes.
  - **Texturas:** la calle del Santo.

## Cómo trabajar (normas del usuario, 15/11/2026)

- **Pruebas:** siempre con `python tools/run_tests.py <modo>`. Es una sola llamada que espera al final, con tiempo límite. Guarda el registro en `logs/` y devuelve un resumen.
  - Tras cada cambio, la prueba del modo afectado (`--selftest --<modo>`; la lista está en `selftest.gd`, `_run`).
  - La prueba completa (`python tools/run_tests.py`), solo en los hitos, antes de publicar o si lo piden.
  - Nada de vigilar pruebas largas a base de llamadas repetidas.
  - Los modos de fotos (`firmas`, `relief`, `casas`, `caridad`…) necesitan ventana: sin ella no escriben nada y se quedan esperando. Desde el 15/11 por la tarde el lanzador la pone solo: si el bloque del modo en `selftest.gd` empieza con `shots = true`, o si se pide `shots` o `vistas=`. `--headless` lo fuerza sin ventana. El tiempo límite corta aunque Godot no escriba nada.
- **Fallos intermitentes:** se investigan uno a uno, con el modo y su `--traza`, y `--repeat N` si hace falta.
- **No releer** archivos ni fotos que no han cambiado.
- **Sesiones a la vez:** cada una toca sus archivos. Se avisa antes de una prueba completa. Para publicar se congela la carpeta.
  - Todas las sesiones trabajan en la misma carpeta, sin carpetas de trabajo (git worktree) separadas: lo decidió el usuario el 15/11. Cada una toca sus archivos y avisa antes de tocar los de otra.

## Fallos conocidos

- **Límite, «everybody comes after you»:** intermitente. A veces el calor sale 98 cuando se pide ≥ 99: baja un poco si el juego va lento, por ejemplo con otro Godot abierto. Falló una vez el 16/11 y pasó 3/3 con `--repeat` justo después.
- **Grúa:** a veces se queda parada a unos 130 m del coche, en la esquina de (871, 254) o (880, 247), detrás de un coche aparcado. Está atenuado con `_room_at` y `_clear_parked`; vigilarlo.
- **Sabotaje:** la furgoneta se atascaba en calles estrechas, sobre todo en (-472, -340), tramos 856-858. Ahora tiene la ruta cerrada; vigilarlo en las completas.
- **Turbo del Julietta:** la segunda pasada se quedaba a 0 km/h de vez en cuando; ahora la prueba usa un coche nuevo.
- **Pruebas con ventana:** `--menu`, `--titulo --shots`, etc. La ventana ya no coge el teclado (`WINDOW_FLAG_NO_FOCUS`).
- **Mirada, «talk to them and they stand still to answer»:** falló una vez en una completa (14/11) y no se ha repetido (`mirada`, `mirada viejo`, `mirada antes` y la completa de la 0.0.3 pasan). Si vuelve, el mensaje dice voz, estado, si el diálogo sigue abierto y cuánto se movió; con «dialogue none», mirar las llamadas de la centralita (desde la 0.0.3 una llamada ya no corta una conversación, que seguramente era la causa).
- **Sin probar en dispositivos reales:** móvil y Steam Machine. Si hay tirones en la Steam Machine, pedir `tirones.txt`.
- **Tokken 9** (publicado desde la 0.0.3; `guion/tokken9.md`): nadie lo ha jugado con las manos. La dificultad del alcalde y de Katakumba69 sale solo de la simulación (`python tools/run_tests.py tokken balance`); cuando el usuario diga cómo lo nota, se retoca `AI["alcalde"]` en `tokken.gd`, sin quitarle que baje la guardia tras el primer golpe. Los botones del móvil y el mando, sin probar.

## Decisiones recientes

- **Pendiente apuntado por el usuario (15/11): niños en la escuela «S. José de Calasanz» en horario escolar.** Preguntó «Habrá niños en Calasanz en horario escolar?» y pidió dejarlo anotado. Hoy el patio está vacío. Para cuando pula los personajes (no antes: no quiere personajes nuevos por ahora): niños solo de lunes a viernes en horario de clase, siempre dentro del patio cerrado (ni en la calle ni atropellables), jugando en el recreo en la torre, el tobogán, los caballitos y la rayuela, y oyéndose al pasar el resto del horario. Falta el modelo de niño y el sistema que los saque y los guarde según la hora (Sistemas). Lo propuesto es idea de Pretil; el usuario solo ha dicho que se anote.
- Misión cumplida: solo el sello ¡APAÑAO! y el dinero en la pizarra, sin cartel.
- Galaxy Recress: el alcalde pide 100 € y devuelve 200 € (lo dijo el usuario). En Tokken 9, por confirmar con él: el alcalde lleva a El Monstruo y Katakumba69 a Drácula, la partida libre es gratis y los nombres de los poderes.
- Límite del mapa: 1950 m, recortado al borde del mapa construido.
- Cristales del Edison: opacos (al usuario no le gustaron los tintados).
- El sol sale por el este desde la 0.0.5.
- Blanco en sombra (desde la 0.0.5): de día la luz ambiente se mezcla más con blanco (`game.gd`, `_apply_sky`), para que el enfoscado blanco se lea blanco en sombra. De noche sigue azul.
- Toro de Osborne (desde la 0.0.5): en la A-4, km 120, pasado el borde sur del mapa; se ve desde la autovía (`toro.gd`, `data/toro.json`, `tools/toro/`).
- Costados de las casas que dan a otra calle: terminados. 42 de 71 descritos (y 5 más de los cortos, de 6 a 8 m) con Street View (líneas `lado` en `casas_calles.gd`, `"flank"` en `casas.gd`); los otros 29 se quedan lisos porque no se ven desde ninguna calle (dan a patios o tienen otra casa pegada delante) o no hay foto.
- Música «urbana»: en Rap-A-Polvo. El usuario no ha dicho nada en contra.
- Galaxy Recress (desde la 0.0.3; diseño en `guion/recress.md`, prueba `recress`): abre de 15:00 a 2:00 y, si estás dentro a la hora de cierre, espera a que salgas. El alcalde pide 100 € y devuelve 200 €. Una llamada no corta una conversación ni una escena (`llamadas.gd`). Pendiente del usuario: los nombres provisionales (el alcalde, la de la copistería, la mujer y la madre del alcalde, el comentarista).
- Habla (desde la 0.0.3): los mancheguismos, sobre todo para los mayores (`generic_old`, `whisper_old`, `ouch_old`). «Apretar» sin diptongo: apreta, apretes. Y en boca de todos (desde la 0.0.9): «tiés» por «tienes» y «ande» por «dónde/donde» («por donde» también: «ande puedas»). Todo en `guion/palabros.md`, contado con nuestras palabras porque su web es CC BY-NC-ND. José-María Moreno García va en los créditos. Lo comprueba `python tools/run_tests.py palabros`.
