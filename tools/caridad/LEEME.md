# Herramientas de la ermita de la Caridad (ermita, plaza, parque de la fuente y guardería)

Con esto se comprobó `godot/scripts/caridad.gd` (noviembre de 2026). Qué es cada cosa, las fuentes y lo aproximado:
`referencias/ermita_caridad/LEEME.md`.

## Qué hay
- `vistas.py [nombre…]` — las vistas `ca_…` del juego para `tools/run_tests.py "<vistas>" --window` (marco del sitio).
- `hojas.py CARPETA_SV` — las dos hojas de `guion/fotos/ermita_caridad/`.
- `enganche.py` — lo que el sitio añade a `selftest.gd` (el modo `--caridad`, `_caridad_checks`); ya está aplicado.
- Catastro y ortofoto: `python tools/molino/catastro.py -545 55 -385 215 partes.json`,
  `python tools/plaza/aerea_wmts.py -540 92 -418 186 0.12 aerea 20`, `python tools/molino/plano.py aerea plano.jpg --parts partes.json --grid 10`.
- Street View: las cámaras están apuntadas en el LEEME de referencias; las fotos se bajan con
  `python tools/molino/panos.py foto ID salida.jpg rumbo inclinación campo`.

## Lo que se aprendió aquí
1. **Mirar el relieve del juego antes de decidir los niveles.** La isleta cae 7 m (el relieve está exagerado). Allanar
   con `terrace()` habría movido cuatro calles varios metros. En su lugar la plaza es un suelo (`MapData.decks`, con
   `grad`) que por el lado alto enrasa con el terreno y por el bajo acaba en un muro: sale el muro de 1,5 m de la
   avenida sin tocar el relieve. Lo que queda cuesta arriba (los edificios por la calle del Rollo) va medio enterrado.
2. **Un suelo así necesita tres cosas**: la cara que se ve, un sólido debajo (`_hull`) y la entrada en `MapData.decks`
   (`_poly_deck`, con `grad` si tiene pendiente). `_floor()` hace las tres.
3. **Catastro puede tener casas que no existen** (aquí, una de dos plantas donde está la fuente) y los años cambiados
   entre dos edificios vecinos. La ortofoto y Street View mandan.
4. **Para llegar a la primera cámara de Street View** de una zona nueva: andar por el grafo de vecinas con
   `panos.info` desde una conocida hacia el punto (el truco de la barra de direcciones daba una fotoesfera de un
   particular, o nada).
5. **El horneado es determinista** (dos horneados seguidos salen idénticos), pero quitar edificios cambia cómo se
   simplifican contornos de manzanas lejanas (el vértice de arranque de la unión cambia): unos 300 contornos ±0,1 m,
   cuatro con un vértice movido hasta 3,7 m, y dos árboles de calle nuevos. Muros, tejados, calles, relieve y casas a
   mano no cambian fuera de la zona. Compararlo siempre con una copia del mapa anterior.
6. **Los modos con fotos necesitan `--window`** (`relief` también lo es); sin ella se quedan colgados hasta el tiempo límite.
7. **Antes de construir, buscar las fotos 360 de particulares que haya DENTRO del sitio.** La primera versión se hizo
   solo con las del coche, desde la avenida, y puso la puerta principal en el lado que no era: la fachada de la
   ermita es la de poniente, que desde ninguna calle se ve de frente. El usuario lo vio a la primera. En Google Maps
   son los círculos azules; se abren con `…/maps/@?api=1&map_action=pano&viewpoint=LAT,LON` y su imagen sale de la
   barra de direcciones (ver el LEEME de referencias).

## Pruebas
`python tools/run_tests.py caridad --window`: 10 fotos (`godot/shots/caridad_*.png`) y tres comprobaciones (está
construida; sus muros paran, la plaza es un suelo que se pisa, 1,5 m sobre la acera de la avenida, y nada pisa una
calzada; los árboles del mapa han salido de la isleta, el mapa sabe que la ermita está ahí y su puerta da a la plaza).
Tras rehornear: además `relief` y `casas solo=juancarlos_ --window`.
