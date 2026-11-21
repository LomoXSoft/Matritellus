# «Cafetería Rize» y su callejón

Luis, 21/11/2026, con una captura de Street View de la boca del callejón: «El siguiente objetivo es la cafetería rice con todo su callejón incluido. Hay una foto 360° dentro del callejón. Enfrente habrá un NPC con bigote, hermoso, y peinado tupé negro que se llamará Marciano. De momento será solo un NPC que hablará que los jóvenes de hoy no tienen ni idea de lo que es una verdadera fiesta, y hablará de las locuras de los 80 y la ruta del bacalao». Y poco después: «Lo llamaremos al local Rize en vez de Rice».

**En el juego se llama «Cafetería Rize».** Aprobada por Luis el 21/11 («Visto bueno sobre todo»). Los scripts usan `rize`; las carpetas de herramientas, fotos y referencias conservan `rice`, que es como empezó.

## Reparto del trabajo

- **Edificios Especiales (Pretil)**: el callejón, la cafetería y lo que la rodea.
- **Sistemas**: Marciano (`marciano.gd`). Aquí no se modela a nadie; se le deja el sitio.

## Dónde está

- El callejón sin nombre que entra hacia el norte desde la avenida de Juan Carlos I, entre dos casas de ladrillo de Texturas (`juancarlos_10` a la izquierda y `juancarlos_4` a la derecha). Mide unos 4 m de ancho y 27 m de largo, y sube un metro hasta el fondo, donde se ensancha.
- Catastro: la cafetería es 4091010VJ5649S (un local de una planta, de 1975) y el garaje de enfrente, 4091028VJ5649S. El muro del fondo con el portón verde no está en Catastro.

## Fuentes

- La foto 360° de una persona, tomada al fondo del callejón en febrero de 2020 (se localiza con `tools/silo/cerca360.py` y se baja con `tour360.py` y `baja360.py`). **No está en el repositorio**: es de otra persona.
- Street View desde la avenida, de noviembre de 2024.
- **Las dos no coinciden en el suelo**: en 2020 era hormigón agrietado; en 2024, adoquín gris de pared a pared. Vale lo más reciente: adoquín.
- `tools/rice/vistas360.py PANO SALIDA CENTRO [rumbo,alto,campo …]` saca vistas planas de una foto 360°. El centro de esta foto mira al rumbo 307.
- `tools/rice/manzana.py` dibuja las parcelas de Catastro sobre la ortofoto (`tools/ign/rice.jpg`).

## Scripts

- `godot/scripts/rize.gd` (`world.rize`, paso «the Cafetería Rize»), sobre `obra.gd`, en el marco del mapa.
  - Para Sistemas: `marciano_spot` y `marciano_h` (enfrente de la cafetería, junto al emblema, mirándola), `door` (ante la puerta), `is_open`, `open_at(day, hour)`, `set_open(on)`, `saffron_spot`.
- Dibujos propios en `godot/assets/rize/` (`tools/rice/dibujos.py`): `mural.png`, `ramas.png`, `pizarra.png`, `rotulo.png`. Tras cambiarlos: `Godot --headless --path godot --import`.
- Prueba: `python tools/run_tests.py rize` (16 capturas y 4 comprobaciones). `_rize_checks()` va también en la completa.
- Hojas: `python tools/rice/hojas.py` → `guion/fotos/rice/01_callejon.jpg` y `02_cafeteria.jpg`. Con `CARPETA PANO 307` monta además la comparación con la foto 360°, fuera del repositorio.

## Horneado

En `tools/bake_godot.py`, solo con añadidos:

- `PAVED_ALLEYS`: una vía sin nombre elegida por sus dos extremos pasa a peatonal adoquinada (`k` 2, `paved` 2) con la marca nueva `narrow`.
- `corridor_half` respeta `narrow`: el pasillo se queda en 1,9 m, como el de una vía de servicio, y ninguna casa se mueve.
- Bloque `RIZE`: las dos parcelas dejan de levantarse como edificios genéricos y el mapa lleva la clave `rize`.

Efecto en `map.json`: salen 2 tejados y 5 muros genéricos; el `clr` del nodo 3062 baja de 2,8 a 1,6; relieve, nodos, árboles y casas, iguales.

## Qué hay

- **El callejón**: adoquín gris desde la avenida (lo pone `empedrado.gd`, como en Santo Domingo) y un remate propio al fondo, donde la vía del mapa se queda dos metros corta. Cerrado al tráfico.
- **La cafetería** (a la derecha): pared blanca sobre zócalo de granito gris, alero oscuro con focos, tres ventanas en rombo con reja negra, la puerta sobre tres escalones de piedra y un toldo azul con el nombre. Fuera, cuatro mesas de madera clara con sus sillas oscuras, el barril junto a los escalones y, en el rincón del fondo, cajas de botellines y sillas apiladas.
- **El fondo**: tapia vieja de color tierra, encalada por abajo y desconchada, con un portón verde de dos hojas, una señal de vado, la tinaja y las sombrillas cerradas apoyadas.
- **A la izquierda**: un garaje bajo y blanco con cubierta de uralita. En su pared, el emblema; en su puerta blanca, ramas en flor pintadas y una casita de pájaros. Dos jardineras amarillas al pie.
- **La casa gris**: revoco gris con recercos y zócalo de travertino, puerta y persianas blancas, ventana con reja, portón ancho de garaje y tres ventanas arriba. Es una **piel de 22 cm sobre el costado de `juancarlos_10`**, que por ese lado es ladrillo liso. Texturas la acepta (21/11: «La piel en el costado de juancarlos_10 me vale; déjala»).
- **En la boca**, mientras está abierta: la pizarra «RIZE · ¡ABIERTO! · Tapas · Raciones · Menú diario».
- **El emblema es del juego**: escudo amarillo en zigzag, tupé y bigote negros y la cinta «SIEMPRE DE FIESTA». El real es de una peña y lleva una gorra roja y un bigote demasiado parecidos a los de un fontanero muy conocido.
- Un azafrán escondido en el rincón, tras las cajas (`"id": "rize"`, `"hidden": true`).
- **Sin interior**: no se entra.

## Horario

El de la cafetería real, según Google Maps: **lunes cerrado; martes y miércoles de 9:00 a 17:00; de jueves a domingo de 9:00 a 19:00** (`HOURS` en `rize.gd`). Abierta: toldo fuera, puerta abierta y pizarra en la boca. Cerrada: toldo recogido, puerta echada y sin pizarra.

## Trampas

- Un callejón peatonal ya no es vía de coches: `MapData.nearest_road(p)` no lo ve. Hay que pedir `nearest_road(p, true)`.
- Lo que rellena los huecos de la piel (puerta, ventana, portón) tiene que quedar **por delante del ladrillo** de la casa que tapa: a 16 cm del frente de la piel, no al fondo. Si no, por los huecos asoma el ladrillo.
- El callejón está casi siempre en sombra: la piedra clara salía parda. Con `_glow(…, 0.2)` se lee crema, como el blanco de la cal.
- Las cámaras de la prueba no pueden caer dentro de un muro ni dentro de un recerco: la vista sale tapada.
