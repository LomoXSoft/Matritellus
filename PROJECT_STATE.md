# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Sin publicar

El detalle de cada pieza está en su LEEME de `referencias/` o `tools/`, en `guion/` y en el historial de git.

- **Sistemas — Brillo y el plazo de Alberto** (17/11):
  - El usuario vio la pantalla del título «un poco quemada» por la mañana en la tele de la Steam Machine. En el PC sale igual con y sin las casas fundidas, y sin quemar (solo un 0,6 % del rojo toca el máximo). El juego no pide salida HDR (`request_hdr_output = false`), así que seguramente es la tele o el HDR de SteamOS estirando la imagen SDR.
  - Nueva opción **Brillo** en Gráficos (`Settings.BRIGHT`, de 70 % a 110 % de 5 en 5, 100 % por defecto): multiplica la imagen final (`env.adjustment_brightness`), no la exposición, porque la curva de tono se comía casi todo el cambio. No forma parte de los ajustes predefinidos. `--titulo --brillo=N` para fotos.
  - Alberto ya no explica la regla («si es de día, antes de la noche; si es de noche…»): dice solo «antes de que anochezca» o «antes de que amanezca», el mismo plazo que pone la misión (`game.firmas_deadline`, también con el salto cuando quedan menos de cinco horas de luz). En el discurso y en el «otra vez».
  - Pruebas `reglas` (21 filas en Gráficos, Brillo) y `firmas` (el plazo a las 10, 18, 23 y 3).
- **Sistemas — la ruta del colesterol** (17/11; el usuario, por Worldbuilding: «Muy buena idea, pídeselo»; `ruta.gd`): paseantes en chándal por la Carretera Antigua de Madrid a Cádiz.
  - De 7:00 a 10:30 y de 18:00 a 21:30, y nunca con lluvia. Hay hasta 12 a la vez, solo en el tramo cercano a ti (de 70 a 300 m); aparecen y se van donde no los ves.
  - Van solos o de dos en dos, a veces con perro (el shiba de Quaternius, con su animación de andar) y algunos mayores con una botella de agua en cada mano. Nunca hay niños.
  - Se quedan en la carretera (su `beat`), por la acera y dando la vuelta en los extremos. El reparto de gente cercana (`_keep_crowd_near`) ya no mueve a quien tiene una calle fija.
  - Hablan con el repertorio `ruta_colesterol` de Worldbuilding.
  - Prueba `--colesterol` (`--ruta` ya era el de las rutas de reparto) y en la completa; foto `ruta_colesterol`.
- **Sistemas — la lista de mejoras y fallos del 17/11** (lo de los recreativos lo lleva Recreativos y el grafiti del creador, Creador):
  - **Pausa:** cuanto más larga, más salían volando los coches; con más de un minuto, todos contra una pared. La pausa para la física, pero el muelle de los coches aparcados y la barra estabilizadora seguían empujando cada tick, y todo se soltaba de golpe al volver. Ahora, mientras el mundo está parado (pausa o mapa grande), los coches no se empujan (`car.gd held`). Prueba `pausa`: 70 s de pausa con coches aparcados al lado. Sin el arreglo saltan 10 m; con él, 0.
  - **Stick del mando** (Steam Controller): en menús y en el ajedrez cada movimiento contaba como una pulsación. Ahora el stick llega como pasos (`controls.gd _stick`): uno al empujar y, si se mantiene, uno a los 0,4 s y luego cada 0,13 s, como una tecla. El stick ya no está atado a `m_*` ni a `ui_*`; andar y conducir lo leen como antes. El ajedrez y la elección de Tokken 9 usan `left/right/forward` solo con teclado. Prueba `mando`.
  - **Niños:** ninguno conduce (`driver_look`). Los de la calle y el Niño Negro Gordo se van a casa en horario de colegio (lunes a viernes de 9:00 a 14:00) y de 23:00 a 8:00, sin que se les vea irse (`ninos.gd street_time`). El parque de la plaza ya tenía su horario. Kevin-José no entra en esta regla: va con las rondas. Prueba en `ninos`.
  - **Flecha de misión** sobre la cabeza: sus dos caras estaban al revés (se veía la de atrás por dentro) y era transparente siempre. Arreglado el sentido de las caras y la transparencia con prepaso de profundidad. Prueba en `marcas`.
  - **Colores en los diálogos** (`Loc.rich`): personajes únicos en rojo (lista ampliada), lugares en azul (`PLACES`) y objetos de misión en verde (`OBJECTS`, como las marcas *…*), siempre como palabra entera. Le he pedido a Worldbuilding que repase las listas. Prueba `colores`.
  - **Rondas de los personajes únicos** sin misión (`rondas.gd`):
    - Tía Paca y la Josefa (mayores): por la mañana a la iglesia (parroquia, Caridad, clarisas, San Sebastián), al mediodía en casa y por la tarde a la plaza o a la iglesia.
    - La Maruja: plaza y bares. El Alberto y la Chiki, cuando acaba la manifestación: plaza y bares.
    - Kevin-José: los parques cuando los niños pueden salir.
    - Si tienen misión para ti, si los pide el paso en curso o si van contigo, vuelven a su sitio. Solo se les mueve donde no se ve.
    - Los tenderos, el cura, el molinero y los del Recress se quedan donde están.
    - Prueba `rondas`.
  - **Ajedrez:** el cursor con la cruceta (y el stick por pasos); vista con Y (H o R en teclado); tercera vista «cine», a vista de helicóptero dando vueltas despacio sobre el tablero. Prueba en `ajedrez` y foto `aj_cine`.
- **Creador (17/11): la pintada de la peña vuelve a verse en el creador** (el usuario, por Sistemas: «el grafiti de la peña no sale durante el creador de personajes»). Sin veredicto todavía.
  - Desde que se fusionaron las mallas de las casas (`lotes.gd`), la pintada de la fachada de Alemania 5 caía justo en la cara de la pared dibujada y la pared la tapaba. Ahora va 4 cm por delante de la pared tal como se dibuja (su `fly` de `casas.gd`) y de lo sólido.
  - La prueba `creador` comprueba además que esté delante de la pared dibujada y a la izquierda del panel. Ficheros: `casa_dentro.gd`, `selftest.gd`. `creador` 19/19 (foto `creador_1_lustre`), `padron` 9/9 (foto `padron_casa`: pegada a la pared, sobre el azulejo).

- **Pretil (17/11): la ermita de San Cristóbal** («Una pequeña hermita hecha por ciudadanos del pueblo que hace esquina con Ortega y Gasset y Carretera antigua Madrid Cádiz»).
  - `cristobal.gd`: la casita encalada con su tejado de teja vieja y la cupulita, la puerta con su reja verde y el azulejo, el patinillo con verja, el muro blanco de la acera, la valla del solar de al lado, los árboles, el poste de los focos, la torreta y la farola.
  - Rehorneado con el OK de Sistemas y Texturas (`CRISTOBAL_RC`): solo se quita el bloque genérico de 5,5 m que había ahí.
  - El usuario: «Le falta una puerta en este lado». Añadida la puerta del lado oeste, con su reja y su patinillo. `cristobal` 2/2. Hojas en `guion/fotos/cristobal/`. Visto bueno (17/11: «Visto bueno»).

## Versión

- **Publicada:** 0.0.16 (17/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.16 — completa: 798 ok, 0 fallos.
  - **Sistemas:**
    - Las mallas de las casas a mano, fundidas por cuadros (`lotes.gd`): 40.766 → 1.892. En el PC del usuario, al girar la cámara la peor dirección pasa de 10 a 53 fps y la media de 54 a 94 (modos `--giro` y `--quien`). Colores lisos con color de vértice, piezas finas solo hasta 120 m, revoco y madera con un shader que copia su material, texturas de foto con los ejes de cada casa. `--casas-sueltas` lo deja como antes.
    - La carga espera a que acaben los pipelines que Godot compila en segundo plano (`_settle_pipelines`): para los tirones de la primera vez tras instalar.
    - La riña del jamón: el swing de verdad del bate; armas de modelos libres (`assets/motin/`, `tools/blender/armas.py`, bate y cuchillo por el mango, puño americano delante del puño), alzadas junto a la cara en los planos detalle, sin nadie tapando.
    - Feliciano (`feliciano.gd`): siempre en la riña, el primero en sacar el arma; por el convento de las clarisas el resto de la semana, a la puerta del Henry los jueves; eufórico los jueves, contando los días los demás, quejándose de la campana.
    - Teclado del juego QWERTY en el Padrón y las cartas.
  - **Pretil:** la ermita de San Sebastián y su parque (`sebastian.gd`, rehorneado).
  - **Texturas:** la Calle del Buen Suceso entera y la Travesía de las Cruces.
  - El detalle de cada pieza está en el historial de git (este archivo, antes de la 0.0.16).
- **Publicada antes:** 0.0.15 (17/11/2026): escribir con mando, en el móvil y bajo Steam (el Padrón ya no se queda atascado), la A del mando pulsa, el tres en raya con mando.
- **Sin publicar (Texturas, 17/11): calle del Molino, tramo oeste, 19 entradas (`mol_*`; aprobadas: «Visto bueno y siguiente»).** Va del 1 al 25. La acera sur son las traseras y patios de las casas de la calle de Granada (`mol_g*`), y hay dos bloques sin dirección (`mol_b301`, `mol_b040`).
  - La acera norte, comparada con las fotos del Catastro. Las traseras de Granada, con Street View 2024, porque la foto del Catastro es de su fachada a Granada. La de Granada 7 (`mol_g7`) casi no se ve en Street View.
  - En la acera norte la calle del mapa pisa los frentes del Catastro: van por la línea de las paredes que deja el horno (`frente_gen`).
  - Bake (en X:, avisando a Pretil): 19 casas nuevas. Dos clr del Molino suben de 2,3–2,4 a 2,6 m. Lo demás igual.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/molino_1..4.jpg`.
- **Sin publicar (Texturas, 17/11): calle del Molino, tramo este, 14 entradas (`mol_*`; aprobadas: «Visto bueno y siguiente»).** Con esto la calle queda entera. Del 27 al 43, más las traseras de Granada 29, 33 y 35 y el costado de Cristo 28.
  - Comparadas con las fotos del Catastro. Las traseras de Granada 29 y 35, con Street View 2024.
  - Granada 29 va por la cara a la calle (la del Catastro queda 8 m dentro). De Granada 33 va solo el cuerpo de tres plantas (`floors: 3`).
  - Sin hacer: Cristo 24 (sus 36 m a esta calle se pisan con el 43) y la trasera de Granada 39 (4,4 m, sin ver en Street View).
  - Bake (en X:, avisando a Pretil, antes de su San Cristóbal): 14 casas nuevas. En `mol_g27` solo cambian las marcas de medianera. Lo demás igual.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/molino_5..7.jpg`.
- **Sin publicar (Texturas, 17/11): Travesía de las Viñas, 7 entradas (`tvi_*`; aprobadas: «Visto bueno y siguiente»).** Incluye el costado largo de Reina Sofía 1 (`tvi_r1`) y la tienda de la esquina con la calle de las Viñas (`tvi_v10a`). Su rótulo dice solo ELECTRODOMESTICOS.
  - Comparadas con las fotos del Catastro (las de Viñas 3 y 5 son la misma foto).
  - Bake (en X:, avisando a Pretil, después de su San Cristóbal): 7 casas nuevas. En `rsof_3` solo cambian dos marcas de pared lateral; su hoja sale como antes. Lo demás igual.
  - `casas`: OK, tras esperar a que el nuevo `ruta.gd` de otra sesión volviera a compilar. Hojas en `guion/fotos/tanda34/tvinas_1..2.jpg`.
- **Sin publicar (Texturas, 17/11): Travesía de Portugal, 10 entradas (`tpo_*`; aprobadas: «Visto bueno y siguiente»).** La calle queda entera.
  - Comparadas con las fotos del Catastro. El 4 no tiene foto; va con Street View 2024 (2017 en esta calle).
  - El Catastro llama solar al 12 y casa al 14. Las fotos y Street View muestran lo contrario: el 12 es casa y el 14 un solar con tapias medio caídas. Van como en las fotos.
  - El solar del 14 lleva sus remiendos de barro y revoco; sin ellos no llegaba al mínimo de piezas del test.
  - Bake (en X:, avisando a Pretil): 10 casas nuevas. En `extre_16` solo cambian dos marcas de medianera. Lo demás igual.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/tportugal_1..2.jpg`.
- **Sin publicar (Texturas, 17/11): calle del Comisario, tramo oeste, 19 entradas (`com_*`; aprobadas: «Visto bueno»).** Del 44 B al 17. Incluye el costado de Monjas 92 (`com_m92`), la esquina de Don Quijote 2 (`com_q2`) y una casa sin dirección (`com_b721`).
  - Comparadas con las fotos del Catastro.
  - El 25 tiene en el Catastro una planta (más sótano): va con `floors: 1` y la altura de la foto. Con `floors: 2` el horno no lo levantaba y hubo que hornear otra vez.
  - Bake (en X:, avisando a Pretil): 19 casas nuevas. Lo demás igual.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/comisario_1..4.jpg`.
  - Queda el tramo este, unos 18 edificios del 15 hacia la Avenida de la Constitución.
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
