# Herramientas de la farmacia de la calle Real y sus vecinas

Con esto se midió y se comprobó `godot/scripts/farmacia.gd` (noviembre de 2026). Qué es cada cosa y sus medidas:
`referencias/farmacia_real/LEEME.md`.

## Qué hay
- `capturas.py CARPETA [nombre…]` — baja las vistas de Street View con que se midió.
- `medir.py CARPETA VISTA px,py …` — dónde cae un píxel de una vista sobre el plano de las fachadas (metros a lo largo
  de la fila, altura). `… fit px,py=x …` ajusta dónde estuvo la cámara para que esos píxeles caigan en esos metros
  (las medianeras de Catastro); el resultado se apunta en `FIX`. Con `colon` tras el nombre, sobre el costado de Colón.
- `vistas.py [nombre…]` — las vistas `fa_…` del juego para `tools/run_tests.py "<vistas>" --window`.
- `hojas.py CARPETA_SV` — las dos hojas de `guion/fotos/farmacia_real/`.
- `enganche.py` — lo que la fila añade a `selftest.gd` (el modo `--farmacia`, `_farmacia_checks`); ya está aplicado.

## Lo que se aprendió aquí
1. **Antes de medir nada, mirar cómo está la esquina en el mapa del juego.** La calle de Colón del juego pasa 3 m al
   norte de la real y el horneado había recortado la manzana: la esquina real caía en mitad de la calzada. Medí la
   droguería real entera antes de verlo. Lo primero: las calles de `map.json` en el marco del sitio y
   `road_edge_dist` de cada esquina.
2. **Una casa de `casas.gd` se entrega a un sitio hecho a mano marcándola `["obra"]`** en `casas_calles.gd`: `casas.gd`
   no dibuja nada de ella (ni tejado ni traseras) y el sitio levanta el contorno que da `MapData.houses` (`_bodies`).
   El bloque sólido del mapa sigue ahí; lo que Catastro no tiene (la mitad norte de la farmacia) lleva `solid()`.
3. **El error de Google es de toda la pasada**: las cámaras de un mismo día iban desviadas lo mismo (aquí, 0,5 m al
   este y 2 m al sur). Con dos medianeras conocidas en una foto frontal sale la corrección; vale para las vecinas.
4. **Lo que se ve muy de lado desde dos cámaras no casa** (aquí, 1,5 m de diferencia a 55°): para el centro de una
   fachada larga, encadenar anchos desde cada extremo y repartir la diferencia.
5. **Los revocos claros a poniente salen grises por la mañana**: aquí llevan más luz propia que en otros sitios (0,4 a
   0,6); las fotos de la prueba se hacen a las 17 h, con el sol dando en las fachadas.

## Pruebas
`python tools/run_tests.py farmacia --window`: 10 fotos (`godot/shots/farmacia_*.png`) y tres comprobaciones (está
construida; las fachadas paran de punta a punta y nada pisa una calzada; `casas.gd` no dibuja nada ahí, la puerta de
la farmacia está en la acera y el mapa sabe que la mitad norte está ocupada).
