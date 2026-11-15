# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Versión

- **Publicada:** 0.0.6 (15/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.6 — completa de las 04:15: 610 ok, 0 fallos. Lleva:
  - Hechos a mano sobre `obra.gd` (Pretil): la Plaza del Ayuntamiento (`plaza.gd`; el reloj marca la hora del juego; seis niños en el parque, siempre en `npcs`, en casa = `away`), el Molino del Tío Gerardo (`molino.gd`; el molinero espera en la era, `MILLER_AT` en `game.gd`) y la Antigua Plaza de Toros (`toros.gd`). La plaza de toros empieza en ruina: `world.toros.set_restored(true)` la deja restaurada, para la futura actividad cívica, y `--toros-restaurada` la arranca así.
  - Calles peatonales y empedradas (Texturas): la calle Real (`PAVED` en `bake_godot.py`) y la del Salvador hasta pasado el 19 (`PAVED_SPANS`); el dibujo lo hace `empedrado.gd`. Casas nuevas de Colón (16) y del Salvador (21), con el ladrillo `brick_buff` y la opción `"strip"` del horneado. Las hojas están en `guion/fotos/tanda6/` y `tanda7/`; el usuario no ha dado su veredicto sobre las casas (el paseo del Salvador sí lo aprobó).
  - La lista grande del usuario del 15/11 (Sistemas): La Chiki y las pintadas (`pintadas.gd`), el mapa grande con joysticks, los ajustes en tres páginas con las opciones gráficas nuevas, el modo desarrollador, el título, el bate, el salto, la madrugada, la flecha y las luces de misión, el sentido único en calles estrechas, la ruta del sabotaje cerrada al tráfico, los nombres nuevos (Nietos de Marzo, Torrezón, Tío Gerardo) y los arreglos de coches, vallas, sillas y pantallas.
- **Sin publicar:** nada.

- **Sin publicar (Texturas, 15/11):** calle de la Palma y primer tramo de la calle de Cervantes, 21 casas descritas (`casas_calles.gd`, `tools/casas/calles.json`, `map.json` horneado; aparte de las nuevas, solo cambian por las paredes compartidas salvador_12, zaragoza_24 y zaragoza_5). La casa sobre la que va La Cocina de Henry (Palma 5) no se toca. `run_tests.py casas "solo=palma_"` y `"solo=cervantes_"`: OK. Hojas en `guion/fotos/tanda8/`. El usuario dio su visto bueno («Eso es»). Después, con una foto suya de Street View: La Cocina de Henry es la casa rosa pegada al estanco (Palma 3 B), no la del 5. `henry.gd` se mueve allí (WALL_A/B/STREET; el escaparate se estrecha para caber) y la comprobación de suelo llano de `selftest.gd` («Henry's») también. La terraza de `bake_godot.py` se queda donde estaba porque ya allana el sitio nuevo: el relieve no cambia. La casa del 5 vuelve a tener su fachada. `motin` 36/36, `comida` 23/23 y `civicos` 39/39: OK. Falta la prueba completa.

- **Sin publicar (Pretil, 15/11):** el puente de Arroyuelo Medio rehecho a mano (`puente.gd` sobre `obra.gd`; `referencias/puente_arroyuelo/`, `tools/puente/`), con el visto bueno del usuario («El puente está de 10, y las aceras y los carteles son un detallazo»; sin obreros: no quiere personajes nuevos por ahora). Está en su sitio real (centro en (-149,61, -261,23)): cauce de hormigón de la calle del Santo al cruce con Matías Pérez, aceras altas de damero sobre muro de piedra a los dos lados, puente con pretiles de ladrillo y pila, escalones, la esquina empedrada con su árbol. Para el resto del juego es el de antes (`p`, `u`, `across`, `hw`, `half`, `open`, `seg`, `top`, `spot()`, `kerb()`, `dress()`, `close_off()`, `placard()`). Nuevo: la obra de demolición, `bridge.set_works(true/false)` (máquinas CC0 en `godot/assets/obra/`); empieza puesta y se va sola la primera mañana tras entregar las firmas, con el jugador a más de 140 m y sin mirar (`_process` de `puente.gd`; `stats["obra_h"]`, `stats["obra_fuera"]`; antes de ese paso siempre vuelve). `--puente-limpio` arranca sin obra ni pancarta. Compartidos tocados: `map_data.gd` (`puente`; `grad` en los suelos `poly`), `bake_godot.py` (bloque `PUENTE`: sube a la acera las casas de la fila este que quedaban bajas, entre ellas `arroyuelo_34`), `map.json`, `selftest.gd` (modo `--puente`, `_arroyuelo_checks` en la completa), `casas.gd` (`_in_old_bed`: las losas de las casas no entran en el cauce) y `casas_calles.gd` (la cochera de `arroyuelo_34` es un hueco: la puerta, desde la calle, es del puente). `puente` 5/5, `firmas` 19/19, `civicos` 39/39, `relief` 19/19, `sabotaje` 45/45 y `grua` 29/29: OK. Falta la prueba completa. Sin commit.

- **Sin publicar (Pretil, 15/11):** la escuela infantil de la calle del Palo, «S. José de Calasanz» (`calasanz.gd` sobre `obra.gd`, `world.calasanz`; `referencias/escuela_calasanz/`, `tools/calasanz/`), enseñada al usuario y pendiente de su veredicto. Edificio de dos plantas de ladrillo y blanco con su arco pintado y su rótulo, murete de piedra con verja de colores, puerta verde, árboles, patio de juegos (torre con tobogán, neumáticos, casita), caseta y murales. No se entra; sin personajes. Compartidos tocados: `bake_godot.py` (bloque `CALASANZ`: la parcela `4194305VJ5649S` no se levanta como casa genérica, se allana a la altura de la calle ante su puerta y queda sin árboles del mapa), `map.json`, `map_data.gd` (`calasanz`), `world.gd` (paso «the nursery school») y `selftest.gd` (modo `--calasanz`, `_calasanz_checks` en la completa, vistas `cz_`). El allanado cambia el suelo alrededor: el cruce del Arroyuelo sube 1,9 m, el de Zaragoza con el Palo baja otro tanto, y el tablero del puente pasa de 1,25 a 1,31. Con el mapa nuevo: `calasanz` 3/3, `puente` 5/5, `firmas` 19/19, `civicos` 39/39 y `relief` 19/19: OK. Falta la prueba completa.

- **Sin publicar (Texturas, 15/11):** calle de Ramón y Cajal, 25 casas (`cajal_*`). Calle elegida por no haberla tocado nadie (sin casas descritas ni sitios hechos a mano cerca). Toca `casas_calles.gd`, `calles.json` y `map.json`; ninguna casa vieja cambia. `run_tests.py casas "solo=cajal_"`: OK. Hojas en `guion/fotos/tanda9/`; falta el veredicto del usuario.

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
