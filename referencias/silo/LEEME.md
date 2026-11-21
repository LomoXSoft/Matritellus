# El Silo del Tío Anaranjao

Luis, 21/11/2026, tras aprobar el parque del Paseo del Cristo: «Pasamos al siguiente proyecto que es algo más complejo. […] el silo del tío colorao (que lo llamaremos silo del tío anaranjao). Aparte de la fachada quiero que se pueda visitar por dentro (hay varias fotos 360 por dentro), con sus muebles y utensilios de como vivía antes la gente bajo tierra en la mancha».

Es el Silo del Tío Colorao real, un museo de las viviendas excavadas de La Mancha, en la C. San Agustín 9 (Catastro 4789012VJ5648N). Está en la punta de la manzana, entre San Agustín, la calle de la Paz y las Navas de Tolosa. **En el juego se llama siempre «Silo del Tío Anaranjao».**

## Scripts

- `godot/scripts/silo.gd` (paso «the Silo del Tío Anaranjao» de `world.gd`, tras el parque): lo que se ve desde la calle. **Sin horneado**: el solar no tenía casa en el mapa.
  - La tapia blanca con albardilla de teja, el portón claveteado, el cartel y cinco rejas.
  - Dentro, el patio de tierra con el caño (visto desde arriba: dos muretes blancos, los escalones y lo oscuro) y dos chimeneas.
- `godot/scripts/silo_dentro.gd`: el interior, un decorado aparte en (1560, −1120) al que se entra por la flecha verde del portón (`entradas.gd`).

## Trampas

- **La calle de San Agustín del juego es más ancha que la real**: el portón real caería sobre el asfalto. La tapia se busca al cargar: desde un punto del patio (`C0`), un rayo cada 5° hasta donde acaba la acera (1,75 m pasado el asfalto) o hasta la pared de un vecino.
- **El suelo del mapa no se puede excavar** (rejilla de 12 m). Por eso el caño de fuera es solo su vista desde arriba, y el de verdad está en el decorado.
- **La cueva es más honda que la real**, a petición de Luis: el patio está 4,6 m bajo el corral y las estancias miden unos 4 m de alto, con bóveda. Así la cámara de esquina cuelga a 3,6 m por debajo del techo y no se ve nada de fuera.
  - Con techos a 2,4 m la cámara quedaba pegada a la cabeza. La primera solución (quitar la tierra de encima y mirar desde arriba) no gustó: «no me gusta que parezca que está al aire libre».
  - En la escalera, `room_at` mueve el punto de la cámara unos peldaños por detrás del jugador; si no, quedaría bajo el rellano.
- **El caño de fuera va recto desde el portón, más ancho que él y pegado al terreno.** Con el rumbo del real y nivelado, el suelo y los muretes atravesaban las hojas abiertas del portón.
- **`entradas.gd`** usa `place.room_at(pp)` si el decorado lo tiene: es el primer decorado de varias estancias.
- Para entrar hay que pulsar el botón de acción sobre la flecha (`E.enter()` en la prueba).

## La planta del decorado

x a la derecha según se entra, +z hacia dentro, el portón en z = 0; y = 0 es el suelo del patio, y el corral y la calle están a 4,6 m.

- **La bajada**: rellano (z 0–2,2), 23 peldaños empedrados (hasta 11,4) y patio (hasta 15,4), de 3 m de ancho, con una soga de pasamanos a cada lado. La leñera está en la pared derecha. La real es escalones y rampa.
- **A la izquierda, la cuadra**: pesebre, paja, colleras, yugo, horca, hoces, criba, serones y pila.
- **Al fondo, la primera casa**:
  - el portal empedrado, con la mesa de mantel de flores, sillas y la fresquera;
  - la cocina, con la chimenea de azulejos bajo volante de vichy rojo, sillas bajas y la mesa;
  - la despensa, con las ollas rojas en los vasares, las sartenes sobre su paño, la lechera verde y los lebrillos;
  - la alcoba, con tres camas de hierro con colchas de flores, el arca, el palanganero y cuadros.
- **A la derecha, la segunda casa**:
  - la cocina, con chimenea de vichy azul, esteras de esparto y la mesa baja;
  - la alcoba de la cama amarilla, con el baúl, tras la cortina de rayas;
  - la alcoba de la cama azul.

## El azafrán

Luis, al cerrar el silo: «Añade un azafrán en una de las habitaciones pequeñas». Hay una flor en una macetita en la alcoba de la cama azul (`_saffron`, `saffron_spot`). El decorado la añade a `G.flowers`, la lista de las flores de las calles, y se recoge igual. Su otra idea, esconder azafrán en ubicaciones especiales, está pasada a Sistemas.

## Fuentes

Las fotos son de otros: **no se guardan en el repositorio**, solo las herramientas de `tools/silo/`.

- **El recorrido virtual de 38 fotos 360** (septiembre de 2019, 8192 × 4096): `cerca360.py LAT LON R` encuentra una; `tour360.py` las recorre todas y saca posición, rumbo y clave de imagen; `baja360.py` las descarga; `hojas360.py` hace el plano y las hojas de contacto. Se nombran e01–e38, ordenadas por z.
  - No salen ni en la página del sitio ni en las teselas de cobertura de Street View: solo con `photometa/si/v1`.
  - Google Maps en el navegador integrado es una «vista limitada», sin capa de Street View.
- **Las diez fotos normales** del sitio: `fotos.py`.
- **Street View de la calle** (noviembre de 2024): `tools/molino/panos.py foto`, panoramas `rVasKMCbb3WNbVwE2uMRYA` (portón), `-ZqEQyFMhY2ZM3S6fjTXwQ` y `f-ofOvppIx7k3xua1L6tOA` (tapia sur).
- **Ortofoto**: `tools/ign/silo.jpg` (0,1 m/px). **Manzana**: `tools/silo/manzana.py`.

## Vistas

`python tools/run_tests.py silo` saca todas (`godot/shots/silo_*.png`) y después `python -I tools/silo/hojas.py SV P360` monta las hojas de `guion/fotos/silo/`.
