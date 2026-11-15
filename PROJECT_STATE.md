# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Versión

- **Publicada:** 0.0.5 (14/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.5
- **Con commit, sin publicar:** `3b0a931` (15/11, en `main`, sin subir), la Plaza del Ayuntamiento:
  - Plaza del Ayuntamiento rehecha a mano (Pretil: `plaza.gd` sobre `obra.gd`). El usuario la vio el 15/11: «un trabajo muy bueno… es un gran avance», con commit pedido por él. Lleva solo lo de la plaza: de `props.gd`, `selftest.gd`, `world.gd`, `bake_godot.py` y `map.json`, únicamente sus partes (la valla con `_reach`, el empedrado de la calle Real, las pruebas de sabotaje y menús siguen en la carpeta sin commit). También van dos retoques: los juegos del parque infantil son modelos libres (`godot/assets/parque/`, CC0) y la terraza del bar tiene seis toldos altos que coloca la plaza (`props.gd`: `_make_terraza_as`, `_prop(..., on_floor)`, toldo cuadrado con `variant >= 100`). Por orden suya, esos dos retoques NO han pasado ni `--plaza` ni la prueba completa: solo compilación y fotos. Después, pedido por el usuario a través de Sistemas: el reloj del ayuntamiento se ve de lejos (sus agujas ya marcaban la hora, pero dejaban de dibujarse a 32 m) y seis niños juegan en el parque (fin de semana de día; de lunes a viernes desde la tarde hasta que anochece; con lluvia no). Los niños están siempre en `npcs` (en casa = `away`), para que el número de vecinos no cambie a mitad de una prueba. `run_tests.py plaza`: OK (8 de 8).
- **Con commit, sin publicar** (15/11, en `main`, sin subir), el commit «Mejoras del 15/11», pedido por el usuario si la prueba completa salía bien. Lleva todo lo que había en la carpeta, menos la plaza de toros de Pretil (`toros.gd`, `tools/toros/`, a medias). La completa de las 03:50 dio 606 ok; su único fallo era la comprobación de la plaza de toros, enganchada y desenganchada a mitad de la prueba. Las casas de la calle del Salvador (Texturas, cambiadas a las 03:58) entran sin haber pasado la completa:
  - Molino del Tío Gerardo (Pretil, 15/11, pedido por el usuario; el nombre real no se usa): el molino y su recinto hechos a mano en `molino.gd` sobre `obra.gd`. Toca `world.gd` (`_windmill`, `var molino`), `map_data.gd` (`var molino`), `tools/bake_godot.py` (`MOLINO_RC`, terraza, zona) con `map.json` horneado de nuevo, y `selftest.gd` (modo `--molino`, `_molino_checks()` en la completa, vistas `ml_`). `run_tests.py molino --window`: OK (6 de 6). Enseñado al usuario el 15/11: «Está increíble». **Con commit `83249f0` (15/11, en `main`, sin subir)**, pedido por él: lleva solo lo del molino (de `world.gd`, `selftest.gd`, `bake_godot.py` y `map.json`, únicamente sus partes; el mapa del commit se horneó en una copia limpia, sin el PAVED de la calle Real). Fuera del commit, en la carpeta: el molinero dentro del recinto y su comprobación, y el nombre «Tío Gerardo» (Sistemas). El molinero ya se llama «Tío Gerardo» en los textos (Sistemas).
  - Sabotaje: la ruta de la furgoneta queda cerrada al tráfico mientras dura la misión (`traffic.closed`, `sabotaje._close_route`), con 4 s de gracia tras recular.
  - Grúa y tráfico: protegidos ante coches borrados por otro lado; los vehículos de servicio quitan el aparcado que no les deja pasar, si nadie mira (`traffic._clear_parked`).
  - Calle Real peatonal y empedrada (Texturas, 15/11), desde el cruce con Colón y La Palma hasta el final, la zona de los comercios. En `bake_godot.py` (PAVED) es un paseo (k 2, w 7.5): sin tráfico ni aparcados y sin mover casas. `empedrado.gd` pone el adoquín gris en el centro y el ladrillo a los lados; los dibujos los hace `tools/empedrado_tex.py`. Pasa la completa (15/11, 03:50).
  - Calle de Colón (Texturas, 15/11, pedida por el usuario): 16 casas descritas una a una (`casas_calles.gd`, `tools/casas/calles.json`, `map.json` horneado de nuevo; solo cambian casas `colon_*`). Un ladrillo nuevo, `brick_buff` (`casas.gd` y `texturas.gd`). `run_tests.py casas "solo=colon_" --window`: OK. Hojas en `guion/fotos/tanda6/`, enseñadas al usuario; falta su veredicto.
  - Calle del Salvador (Texturas, 15/11, pedida por el usuario): 21 casas descritas con Street View (las fotos del Catastro son viejas). Toca `casas_calles.gd`, `calles.json`, `map.json` y una opción nueva en `bake_godot.py` (`"strip"`: quita las tiras bajas que el Catastro pinta pegadas a una fachada). `run_tests.py casas "solo=salvador_" --window`: OK. Hojas en `guion/fotos/tanda7/`; falta su veredicto. El tramo al oeste de la calle Real también es peatonal en Street View: sin cambiar, pendiente de que lo diga el usuario.
  - Lista grande del usuario del 15/11 (Sistemas), con prueba de cada modo:
    - **La Chiki y las pintadas** (`pintadas.gd`; prueba `pintadas`):
      - tu peña empieza sin paredes;
      - no se pinta hasta hablar con ella tras la protesta, en una charla con escena por las paredes;
      - una pista al día, que se marca en el minimapa;
      - ±1 de confianza con ella al pintar o tapar a los Nietos;
      - al acabar te llama y te da +50;
      - con 100 de confianza, su confesión: se llama María y es hermana de Don Luis.
    - **Mapa grande:** pausa el juego y se mueve y acerca con los joysticks (`_set_map`, `_map_nav`).
    - **Ajustes:**
      - modo desarrollador en Gameplay, cuya página sale en la pausa (`_dev_*`);
      - Modo Silent Hill en Gráficos.
    - **Hoja del calendario:** dice «madrugada» de 00:00 al amanecer (`moment_name`; la lógica sigue con `night`).
    - **Flecha y luces de misión:**
      - la flecha apunta recta y a ras de suelo;
      - luz amarilla solo para lo que se hace con coche (`_by_car`), flecha verde para la gente (`marcas.givers`).
    - **Coches:**
      - el Julietta con motor de ralentí (`ENGINE_PITCH`);
      - rueda trasera del Yondir rehecha (`wheel_copy`).
    - **Choques:** la valla se golpea solo cerca de su propia línea (`props._reach`); «Subir» gana a «Hablar» a menos de 3 m.
    - **En Android:** el nitro se queda puesto con un toque; el salto sube según cuánto lo mantengas.
    - **Calles estrechas:** sentido único para el tráfico (`one_way_ok`).
    - **Pantallas:**
      - «Cargando…» sobre la barra y la versión en una esquina;
      - en la Steam Machine (gamescope), siempre pantalla completa.
    - **Aspecto:**
      - bandas negras a la mitad;
      - contorno negro;
      - el título y el creador a las 9:00 (el precalentado dejaba el pueblo a las 5 de la madrugada);
      - sillas del Kebab Luis giradas.
    - **Nombres:**
      - el molinero se llama Tío Gerardo, y con el molino hecho a mano espera dentro de la era, junto a la puerta (`MILLER_AT`); el tractor sigue en la calle;
      - Nietos de Marzo, con su logo nuevo;
      - el cabo Ramírez pasa a ser el teniente Torrezón, con su historia;
      - «riñones» en el vocabulario.

## Cómo trabajar (normas del usuario, 15/11/2026)

- **Pruebas:** siempre con `python tools/run_tests.py <modo>`. Es una sola llamada que espera al final, con tiempo límite. Guarda el registro en `logs/` y devuelve un resumen.
  - Tras cada cambio, la prueba del modo afectado (`--selftest --<modo>`; la lista está en `selftest.gd`, `_run`).
  - La prueba completa (`python tools/run_tests.py`), solo en los hitos, antes de publicar o si lo piden.
  - Nada de vigilar pruebas largas a base de llamadas repetidas.
  - Los modos de fotos (`firmas`, `petril`, `molino`…) van con `--window`: sin ventana no escriben nada y se quedan esperando. El lanzador los corta al llegar a su tiempo límite, aunque Godot no escriba nada (lee en un hilo aparte).
- **Fallos intermitentes:** se investigan uno a uno, con el modo y su `--traza`, y `--repeat N` si hace falta.
- **No releer** archivos ni fotos que no han cambiado.
- **Sesiones a la vez:** cada una toca sus archivos. Se avisa antes de una prueba completa. Para publicar se congela la carpeta.
  - Todas las sesiones trabajan en la misma carpeta, sin carpetas de trabajo (git worktree) separadas: lo decidió el usuario el 15/11. Cada una toca sus archivos y avisa antes de tocar los de otra.

## Fallos conocidos

- **Grúa:** a veces se queda parada a unos 130 m del coche, en la esquina de (871, 254) o (880, 247), detrás de un coche aparcado. Está atenuado con `_room_at` y `_clear_parked`; vigilarlo.
- **Sabotaje:** la furgoneta se atascaba en calles estrechas, sobre todo en (-472, -340), tramos 856-858. Ahora tiene la ruta cerrada; vigilarlo en las completas.
- **Turbo del Julietta:** la segunda pasada se quedaba a 0 km/h de vez en cuando; ahora la prueba usa un coche nuevo.
- **Pruebas con ventana:** `--menu`, `--titulo --shots`, etc. La ventana ya no coge el teclado (`WINDOW_FLAG_NO_FOCUS`).
- **Mirada, «talk to them and they stand still to answer»:** falló una vez en una completa (14/11) y no se ha repetido (`mirada`, `mirada viejo`, `mirada antes` y la completa de la 0.0.3 pasan). Si vuelve, el mensaje dice voz, estado, si el diálogo sigue abierto y cuánto se movió; con «dialogue none», mirar las llamadas de la centralita (desde la 0.0.3 una llamada ya no corta una conversación, que seguramente era la causa).
- **Sin probar en dispositivos reales:** móvil y Steam Machine. Si hay tirones en la Steam Machine, pedir `tirones.txt`.
- **Tokken 9** (publicado desde la 0.0.3; `guion/tokken9.md`): nadie lo ha jugado con las manos. La dificultad del alcalde y de Katakumba69 sale solo de la simulación (`python tools/run_tests.py tokken balance`); cuando el usuario diga cómo lo nota, se retoca `AI["alcalde"]` en `tokken.gd`, sin quitarle que baje la guardia tras el primer golpe. Los botones del móvil y el mando, sin probar.

## Decisiones recientes

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
- Habla (desde la 0.0.3): los mancheguismos, sobre todo para los mayores (`generic_old`, `whisper_old`, `ouch_old`). «Apretar» sin diptongo: apreta, apretes. Todo en `guion/palabros.md`, contado con nuestras palabras porque su web es CC BY-NC-ND. José-María Moreno García va en los créditos. Lo comprueba `python tools/run_tests.py palabros`.
