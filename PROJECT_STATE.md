# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Sin publicar

El detalle de cada pieza está en su LEEME de `referencias/` o `tools/`, en `guion/` y en el historial de git.

- **Sistemas — rendimiento al girar la cámara, el bate, las armas de la riña y el teclado QWERTY** (17/11; el usuario, en una Steam Machine: «te pones en cualquier punto del pueblo y mueves la cámara 360°: habrá zonas con muchos fps pero otras caerán a los 30 y pocos»):
  - Medido con `--giro` (nuevo: 9 sitios, 16 direcciones, fps, GPU, CPU, llamadas, triángulos) y `--quien` (qué hay en la imagen). En las peores direcciones, mirando el pueblo desde un borde, se dibujaban 27.000 mallas: 26.000 eran piezas de las casas a mano, una por material y casa (40.766 en total). La CPU tardaba 50 ms por fotograma solo en mandarlas. Sombras, MSAA, SSAO, gente y coches no influían.
  - Ahora las casas de `casas.gd` entregan sus piezas a `lotes.gd`, que las funde por material en cuadros: 1.892 mallas en vez de 40.766.
    - Los colores lisos (marcos, rejas, puertas) van en una sola malla con el color en cada vértice.
    - Las piezas finas o pequeñas (barrotes, varillas, pomos: 5 de los 7 millones de triángulos de las casas) van aparte y solo se dibujan hasta 120 m (con la opción de distancia de dibujo).
    - Los revocos y la madera de cualquier color comparten un shader que reproduce el material de siempre con el color en el vértice; comprobado con fotos antes y después: el mismo color medio, solo cambia la fase de la textura.
    - Las texturas de foto siguen los ejes de cada casa, así que esas piezas solo se juntan con casas giradas igual (ladrillo 0,1°, madera 0,6°, revoco 3°): sin eso se emborronaban en las calles en diagonal.
    - `--casas-sueltas` lo deja como antes. Las casas siguen siendo nodos con sus colisiones, carteles y tela. Carga de las casas: +1,2 s. Memoria: 1.236 → 1.127 MB.
  - Resultado en el PC del usuario (RX 9060 XT, 1280×720): la peor dirección pasa de 10 a 53 fps y la media de 54 a 94; CPU de render en la peor de 50 a 6 ms. Sin probar en la Steam Machine.
  - La primera vez tras instalar: la carga espera ahora a que Godot termine los pipelines que compila en segundo plano (`game.gd _settle_pipelines`, hasta 30 s; con la caché, 1 s).
  - El bate en la riña del jamón: tu golpe era un puñetazo con el bate en la mano; ahora es el swing de verdad (como fuera de la misión), un poco más lento (0,7 s, golpea a los 0,4 s).
  - Las armas de la riña: modelos libres en `godot/assets/motin/armas.glb` (`tools/blender/armas.py`): bate de CreativeTrio (CC0) con clavos hechos en el script, cuchillo de carnicero de Kenney (CC0), puño americano de Qubzy (CC-BY 3.0, en latón). Créditos en `godot/assets/motin/CREDITOS.txt`. En el plano detalle el vecino alza el arma junto a la cara y la cámara encuadra cara y arma; quien se cruza delante o está pegado al objetivo no se dibuja en ese plano. El usuario vio el bate al revés y luego el cuchillo «al revés» (el filo hacia su propia cabeza): `armas.py` ahora decide qué punta es la gruesa comparando los extremos, y centra el arma en el mango, no en la caja (el mango del cuchillo va pegado al lomo). El puño americano, delante del puño y no dentro: las manos son bolas y lo pequeño se perdía («los alargados quedan bien que clippeen las manos»).
  - Teclado del juego en QWERTY (Padrón y cartas), con la Ñ tras la L.
- **Sistemas — Feliciano** (17/11, a petición del usuario; `feliciano.gd`): vecino obsesionado con el jamón asao de los jueves. Piel algo morena, cejas gruesas, pelo negro, ojos marrones, sin barba.
  - Está siempre en la riña del jamón: es el segundo de la gente y el primero que saca el arma (el cuchillo), con su plano detalle. Tras la riña vuelve a su vida, no se va con los demás.
  - El resto del tiempo da vueltas por tres puntos de las calles del convento de las clarisas (Santa Ana), 75 s en cada uno. Los jueves de 8:00 a 21:00, mientras no haya jamón ese día, espera a la puerta del Henry. Solo se le cambia de sitio donde no se ve.
  - Habla: los jueves eufórico (`feliciano_jueves`), los demás días triste contando los días que faltan (`feliciano_semana`, «un día», «seis días»), y una vez de cada cuatro se queja de la campana del convento, que toca cada hora (`feliciano_campana`). También sus llamadas tras una carta, sus frases de la firma del puente, su figura en las máquinas de bolas (28 en total) y su sitio en el árbol de relaciones (`guion/relaciones.json`, foto en `guion/fotos/feliciano.png`).
  - La campana no suena de verdad en el juego: solo lo dice él.
  - Prueba `feliciano` (y en la completa); `motin` comprueba que está en la riña con el cuchillo y que sigue después.
  - Pruebas: `motin` (37, con el swing y las armas), `padron`, `cartas`; fotos `motin_4_arma_0..2`, `padron_teclas`, `cartas_teclas`.
- **Pretil (17/11): la ermita de San Sebastián y su parque** («La hermita de san Sebastián y el parque que la rodea»).
  - `sebastian.gd`: la ermita con su pórtico, la espadaña, la capillita y la terraza sobre la Calle del Santo; la pérgola; la plaza redonda con su fuente; el parque con sus árboles, farolas, bancos, la fuente de piedra, el monumento y la bandera.
  - Rehorneado con el OK de Sistemas y Texturas (`SEBASTIAN_RC`): ninguna casa cambia; solo se quitan la ermita genérica y 7 árboles del parque.
  - El usuario: «Aquí el césped clippea un poco, quitando eso de 10». La plaza redonda ya no queda enterrada: su suelo cae menos que el terreno y va siempre por encima, con borde de granito y escalones. `sebastian` 2/2 (ahora comprueba también que el terreno no asome). Hojas en `guion/fotos/sebastian/`. Visto bueno a todo (17/11: «Perfecto. Visto bueno»).

## Versión

- **Publicada:** 0.0.15 (17/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.15 — completa: 788 ok, 0 fallos.
  - **Sistemas — escribir con mando, en el móvil y bajo Steam** (el usuario: en el móvil y con mando en el game mode de Linux no se podía pasar del Padrón, «el teclado queda fuera de pantalla y no se sabe que tecla se usa», y el tres en raya no iba con mando):
    - La causa con mando: el «aceptar» de Godot (`ui_accept`) es solo Intro y Espacio, sin botón del mando, así que la A no pulsaba la tecla elegida. Ahora la A la pulsa en el Padrón, en la carta de Correa y en el tres en raya (`padron.gd press_focused`).
    - En el móvil sale su propio teclado al abrir la hoja (y su Intro firma); las teclas de la hoja ya no salen (un toque en la pantalla contaba como mando). La hoja sube si el teclado tapa el nombre o la carta.
    - En Linux bajo Steam (variables SteamDeck/SteamGameId/SteamAppId) con mando se abre el teclado de Steam (`steam://open/keyboard`) sobre el nombre o la carta; Y lo vuelve a abrir, y A sobre el nombre también. Sin probar en una Steam Machine de verdad.
    - Las teclas de la hoja, para el mando, siempre caben: la hoja entera se encoge (×0,72 a 720 px de alto), la tecla elegida va en amarillo y una línea dice qué hace cada botón.
    - El tres en raya: el primer toque del mando te pone en una casilla libre y la A juega ahí.
  - El detalle está en el historial de git (este archivo, antes de la 0.0.15).
- **Publicada antes:** 0.0.14 (17/11/2026): la carga de 45 a 32 s con el tres en raya, los gráficos preparados tras cada actualización, tráfico y noches más ligeros, subirse de un salto a coches y muretes, la Pizzería Toti, la Casa Grande y muchas calles.
- **Sin publicar (Texturas, 17/11): calle del Buen Suceso, tramo este, 21 entradas (`bs_*`; aprobadas: «Visto bueno y siguiente»).** Va de la Avenida de Europa hasta el 18. Incluye casas con número de la Avenida de Europa (`bs_e85`, `bs_e83`), de Juan XXIII (`bs_j46`, `bs_j61`), del Camino Hondo (`bs_h20`) y una sin dirección (`bs_b012`).
  - Comparadas con las fotos del Catastro; las dos naves de la Avenida de Europa, con Street View 2024. Sus letreros pintados no se ponen: llevan nombre de negocio.
  - En dos: Juan XXIII 61 (la casa de dos plantas `bs_j61` y su tramo de una, `bs_j61p`, `only: 1`) y el 20 (la casa baja `bs_20` y su cuerpo de dos plantas `bs_20u`).
  - La tapia larga de la nave `bs_e83` lleva sus remiendos y las juntas de la franja de arriba; sin ellos no llegaba al mínimo de piezas del test.
  - Sin hacer: Concordia 9 (3,4 m a esta calle) y la tapia de ladrillo de la esquina del 37.
  - Bake (en X:, avisando a Pretil): 21 casas nuevas. Nada más cambia.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/bsuceso_1..4.jpg`.
- **Sin publicar (Texturas, 17/11): calle del Buen Suceso, tramo oeste, 13 entradas (`bs_*`; aprobadas: «Visto bueno y siguiente»).** Con esto la calle queda entera. Incluye la casa de Delicias 34 (`bs_d34`), la de Romero 24 D en la esquina (`bs_r24d`) y un bloque sin dirección (`bs_b316`).
  - Comparadas con las fotos del Catastro.
  - El bajo de `bs_b316` es una tienda de comestibles con marca de cadena: su rótulo dice solo ALIMENTACION.
  - Sin hacer: Delicias 36 y 36 D, con 3 y 1,1 m a esta calle.
  - Bake (en X:, avisando a Pretil, antes de su ermita): 13 casas nuevas. Nada más cambia.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/bsuceso_5..7.jpg`.
- **Sin publicar (Texturas, 17/11): Travesía de las Cruces, 10 entradas (`trc_*`; aprobadas: «Visto bueno y paramos un momento»).** Incluye los costados del 16 y el 18 de la calle de las Cruces (`trc_c16`, `trc_c18`) y un bloque de esquina sin dirección (`trc_b015`).
  - Comparadas con las fotos del Catastro; los dos costados, también con Street View 2024. El 3 lleva su pintada, que es una de las peñas del juego.
  - El 3 va por su cara a la calle (la de `frente_gen`), no por la del Catastro, que queda 9 m dentro.
  - Sin hacer: el 14 de las Cruces, cuyo costado a la travesía queda 9 m detrás del 16.
  - Bake (en X:, avisando a Pretil, después de su ermita): 10 casas nuevas. Nada más cambia (2956 árboles desde la ermita).
  - `casas`: OK. Hojas en `guion/fotos/tanda34/trcruces_1..2.jpg`.
- **Pendiente:**
  - Texturas:
    - **La calle de la Cruz (`cruz_*`) salió en la 0.0.13 con 31 casas.** Después, ya en X:, quité `cruz_13` y `cruz_17`, cuyo frente quedaba metido en la manzana, y quedaron 29. A `cruz_vg9` y `cruz_21` les puse alero de teja. Rehorneado sin más cambios, y `casas` OK. Las hojas `guion/fotos/tanda34/cruz_1..5.jpg` se mandaron al usuario el 17/11, que dio su «Visto bueno».
    - La travesía del Clavel, que hay que hacer a mano.
    - El repaso de lo que aún no se parece: `guion/repaso_casas.md`.
  - Creador: el resto de la criba de piezas (ropa, sombreros, lo que quiera quitar), cuando el usuario quiera. Lo hecho hasta ahora tiene su visto bueno (17/11).
  - Sistemas: `sentido` falla a veces (coches en contra al dejar conducir al tráfico); ya pasaba antes de los cambios de rendimiento.

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
- Habla (desde la 0.0.3): los mancheguismos, sobre todo para los mayores (`generic_old`, `whisper_old`, `ouch_old`). «Apretar» sin diptongo: apreta, apretes. Y en boca de todos (desde la 0.0.9): «tiés» por «tienes» y «ande» por «dónde/donde» («por donde» también: «ande puedas»). Desde el 17/11 (sin publicar) la prueba vigila todas las reglas de la casa (lé, la'é, l'á, -ao/-ío, pa, to, na, vía, cá, semos, entoavía, enga, mu) en lo que dice cualquiera, salvo `HABLA_FINA` (el alcalde, menús, pantallas, carteles) y lo que va entre «». Todo en `guion/palabros.md`, contado con nuestras palabras porque su web es CC BY-NC-ND. José-María Moreno García va en los créditos. Lo comprueba `python tools/run_tests.py palabros`.
