# «Colegio Público» (el Garcilaso de la Vega)

**APROBADO por Luis el 27/11/2026**: «Horario escolar 9 a 14. Por lo demás, visto bueno».

Luis, 27/11/2026, con una captura de Google Maps con la zona marcada en rojo: «Podrías ponerte con el colegio público Garcilaso de la vega (creo que con llamarlo colegio público es suficiente). Ocupa más o menos la zona en rojo. Está construido sobre las ruinas del antiguo cementerio. Así que si quieres poner algunos huesos o calaveras en algún sitio como easter egg estaría guay (también pásale este Lore a world building)».

- En el juego solo pone **«COLEGIO PÚBLICO»**: dos letreros en la cara norte del ala este, la que da a la calle del Socorro, en lo alto (la entrada queda a la vuelta de la esquina). No hay nombre propio, número, escudo de la Junta ni teléfono.
- El lore del cementerio viejo se le pasó a Worldbuilding el mismo día.

## Reparto del trabajo

- **Edificios Especiales (Pretil)**: todo lo de dentro de la valla, la valla y la acera de fuera (`godot/scripts/colegiopub.gd`, sobre `obra.gd`).
- **Sin rehorneado**: el mapa no tenía nada en esta manzana (era tierra). No se ha tocado `map.json` ni `casas*.gd`.
- **Sistemas**: avisado de las líneas metidas en `world.gd` (const, var, la entrada de la lista de construcción y `_build_colegiopub`) y en `selftest.gd` (modo `--colegiopub` y `_colegiopub_checks`, también en la pasada completa).

## Dónde está

- La manzana entre la calle de los Huertos (oeste), la calle del Socorro (norte), el callejón del este y las traseras de las casas de la calle del Santo (sur).
- Marco (u, v): A = (−136,4, −560,2) es la esquina noroeste del ala norte; u va a lo largo del ala norte (EU = (0,957, 0,289)), v cruza hacia el sur-suroeste. `map_at(u, v)` y `to_uv(p)` pasan de uno a otro.
- `FENCE` (23 puntos del mapa) es la valla, sacada de OpenStreetMap. Todo lo del suelo se recorta a ella.
- Fuentes: los contornos de OpenStreetMap (coinciden con la ortofoto del IGN), las vistas aéreas de Google para lo que hay en el suelo (son oblicuas: ponen los tejados un metro al norte por cada metro de altura) y Street View desde las calles de alrededor. Las capturas de Google se quedaron fuera del proyecto.

## Qué hay

- **Las dos alas de dos plantas** (norte y este), de paneles claros sobre zócalo gris, con un suelo común (`fl2`). La entrada está en la cara este del ala este (la del callejón), cerca de la esquina con la calle del Socorro, con marquesina y escalones; el ventanal de encima es la vidriera de la escalera.
- **Las aulas de una planta** detrás (M1, M2, el paso y las dos de la fila sur), cada una en su suelo, con el patinillo estrecho entre el ala norte y M2 y placas solares en el tejado de M2.
- **El porche del sur** sobre el patio de arena de los pequeños, con postes, tres cuadros de césped con árbol y el **arenero** (cubo rojo y pala azul).
- **El gimnasio** y su anexo en el norte: nave con cubierta de chapa a dos aguas y una banda de cristal alta.
- **La pista**: patio de hormigón al oeste con la pista de fútbol sala (líneas, porterías con red), dos canastas y tres torres de focos de 10 m (son farolas del pueblo: `world.lamp_spots`, se encienden de noche).
- **El aparcamiento** de asfalto al este, con sus plazas pintadas y el portón cerrado al callejón.
- **Los huertos**: dos bancales de ladrillo con lechugas en la tierra del norte.
- **La valla**: murete con malla en las calles, tapia blanca alta con malla a lo largo de la pista (calle de los Huertos), tapia blanca contra las traseras de la calle del Santo. Puertas abiertas en la calle del Socorro (dos) y en el sur; portón del aparcamiento cerrado.

## El huevo de pascua: el cementerio viejo

Tres sitios (`bones`, comprobados por la prueba dentro de la valla):

1. **El arenero**: una calavera medio enterrada en la arena y un hueso al lado.
2. **El huerto**: un fémur desenterrado en el primer bancal (las lechugas dejan hueco alrededor).
3. **El patinillo**: una calavera con dos huesos cruzados al fondo del patio estrecho, mirando al oeste.

La calavera y el hueso son un modelo propio hecho en Blender: `tools/blender/calavera.py` → `godot/assets/colegiopub/calavera.glb` (nodos `calavera` y `hueso`). Booleanas EXACT solo sobre mallas cerradas: primero la UNIÓN de cráneo, cara y pómulos, luego la DIFERENCIA de ojos y nariz.

## El azafrán escondido

Luis aceptó la propuesta «¿Pongo el azafrán escondido dentro del cubo rojo del arenero?» con un «Si, pon uno». Está en
el cubo rojo del arenero, junto a la calavera (`_saffron`, `id` "colegiopub", uno por partida).

## Los niños

Lo pidió Luis: «Además de que funcione como Calasanz, niños jugando y dando vueltas durante el horario escolar».

- Los hace `ninos.gd` (de Sistemas) en tres patios: `colegiopub_arena` (5 pequeños, del tamaño de los de Calasanz),
  `colegiopub_pista` y `colegiopub_patio` (5 y 5 mayores, del tamaño de los de la calle).
- Salen en horario escolar, de lunes a viernes de 9 a 14, y no salen si llueve (Luis: «Horario escolar 9 a 14»; las guarderías siguen de 10 a 13). Es la clave `hours` de cada patio en `ninos.gd`. Salen y entran solo cuando
  nadie mira.
- Los sitios entre los que corren están en `KID_YARDS` de `colegiopub.gd`, con el punto desde el que se hace la foto
  de cada patio.
- Los patios van en cuesta, así que cada niño pisa el suelo que tiene debajo.
- Prueba: `python tools/run_tests.py ninos`. Hace las fotos `ninos_colegiopub_arena`, `_pista` y `_patio`.

## Pruebas

- `python tools/run_tests.py colegiopub --timeout 600`: vistas (aire, aire_no, planta, socorro, socorro_oeste, entrada, callejon, sur, huertos, patio, porche, patinillo, arenero, huerto y noche) y las comprobaciones (más de 1500 piezas, 9 edificios sólidos y en el mapa, nada en la calzada, el nombre, los 3 focos, los 3 huesos).
- `zfight solo=colegiopub.gd`: de 285 m² a 3 m² exactos, casi todo zócalo enterrado.
- Fotos del juego en `guion/fotos/colegio_publico/` (antes y después, vistas, huesos).
