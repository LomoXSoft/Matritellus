# Herramientas de la escuela infantil de la calle del Palo («S. José de Calasanz»)

Con esto se midió y se comprobó `godot/scripts/calasanz.gd` (noviembre de 2026). Mismo método que `tools/petril/`,
`tools/plaza/`, `tools/molino/` y `tools/puente/`; aquí solo lo nuevo. Qué es cada cosa y sus medidas:
`referencias/escuela_calasanz/LEEME.md`.

## Qué hay
- `capturas.py CARPETA` — baja las vistas de Street View con que se midió (mayo de 2009, marzo de 2013, 2024).
- `plano.py ORTOFOTO SALIDA.jpg` — la parcela en el marco de la escuela sobre una ortofoto, con las manzanas y los
  ejes de calle del juego.
- `vistas_sv.py` — el juego fotografiado desde donde estuvo Street View (vistas `cz_…`, en el marco de la escuela) y
  `hoja` para montar «Street View | juego».
- `hojas.py CARPETA_SV` — las dos hojas de `guion/fotos/calasanz/`.
- `enganche.py` — lo que la escuela añade a `selftest.gd` (el modo `--calasanz`, `_calasanz_checks`, las vistas
  `cz_`); ya está aplicado.
- La ficha de Catastro y su foto de fachada: `python tools/house_data.py --fast 4194305VJ5649S`
  (`tools/casas/4194305VJ5649S/`).

## Lo que se aprendió aquí
1. **Las fotos de invierno enseñan la fachada; las de primavera, el patio.** Los árboles de mayo de 2009 tapan el
   edificio; los de marzo de 2013, pelados, lo dejan medir entero. Lo de 2009 que pidió el usuario (colores, juegos)
   se toma de 2009 y la arquitectura de 2013.
2. **Una fachada simétrica se mide sola**: con el arco en el centro del frente de Catastro (23,36 m) y la esquina del
   edificio en la foto frontal salen la escala (45,8 px/m) y, de ahí, todas las ventanas.
3. **Allanar una parcela larga en una calle en cuesta mueve la calle entera.** El relieve del juego exagera las
   pendientes: la calle del Palo cae 3 m a lo largo de la parcela. `terrace()` allana la parcela y 18 m alrededor, y
   a la altura media de la parcela subía 2,6 m el cruce del Arroyuelo (el cauce viejo corría cuesta arriba hacia él).
   Se allana a la altura de la calle delante de la puerta más un palmo: el cruce sube 1,9 m y el de Zaragoza baja
   otro tanto, y el cauce queda casi llano del puente al cruce. Después de hornear, mirar siempre cuánto ha cambiado
   el suelo de los vecinos (aquí, el puente: su tablero pasó de 1,25 a 1,31) y repetir sus pruebas.
4. **Una tapia propia pegada a la linde queda dentro de la pared del vecino**: medio metro hacia dentro.

## Pruebas
`python tools/run_tests.py calasanz --window`: 12 fotos (`godot/shots/calasanz_*.png`) y tres comprobaciones (está
construida; el murete, la verja, la puerta y la casa paran, el patio queda 0,6 m sobre la calle en suelo llano y nada
pisa la calzada; el mapa sabe que la parcela está ocupada).
