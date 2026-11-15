# Herramientas del supermercado «Mercamona» y su aparcamiento

Con esto se midió y se comprobó `godot/scripts/mercamona.gd` (noviembre de 2026). Qué es cada cosa, las fuentes y lo
aproximado: `referencias/mercamona/LEEME.md`.

## Qué hay
- `capturas.py CARPETA [nombre…]` — baja las 26 vistas de Street View (las tres calles de alrededor).
- `vistas.py NOMBRE…` — el juego desde donde estuvo Street View:
  `python tools/run_tests.py "$(python tools/mercamona/vistas.py W3_f W5_f E4_w E2_s)"`.
- `hojas.py CARPETA_SV` — las dos hojas de `guion/fotos/mercamona/`.
- `enganche.py` — lo que añade a `map_data.gd`, `world.gd` y `selftest.gd`; ya aplicado.

## Lo que se aprendió aquí
1. **Hundir el terreno junto a calles: `pit`, no `terrace`.** `pit(poly, h)` pone a una cota los nudos del relieve de
   dentro de un polígono, sin colchón ni mezcla. Pero el suelo se interpola en triángulos de 12 m: el borde del hoyo es
   una rampa de hasta 12 m hacia dentro Y hacia fuera (aviso de Sistemas). Por eso `pit` no toca ningún nudo a menos de
   19 m de una calle de coches (17 m de triángulo más la calzada): ninguna calzada cambia de altura. Se comprobó
   midiendo cada 2 m, en el eje y a 2,5 m a cada lado, todas las calles en 400 m: diferencia 0.
2. **Lo que se construye en el borde del hoyo tiene que usar o tapar esa rampa.** Aquí: la caída del asfalto desde la
   puerta ES la rampa de entrada; bajo la tienda solo se abre el aparcamiento donde el suelo ya está a cota (`un`, que
   el script calcula mirando el terreno); las plazas solo se pintan donde el suelo está llano.
3. **Mirar si el mapa tiene una calle donde uno cree que no la hay**: listé las calles filtrando por sus nudos y se me
   escapó una recta de 170 m sin nudos intermedios que pasa junto a la puerta del aparcamiento. Hay que medir la
   distancia a los TRAMOS, no a los nudos.
4. **Un aparcamiento privado no sale en Street View**: ni el coche ni fotos 360. Sirven las vistas con zoom
   (`thumbfov` de 30 a 50) desde la valla y la ortofoto.
5. **Marcas**: el nombre lo dio el usuario («Mercamona»); el logotipo se hizo propio (una cara de mona en un aro verde).

## Pruebas
`python tools/run_tests.py mercamona`: 12 fotos (`godot/shots/mercamona_*.png`) y tres comprobaciones (está
construido; la tienda es maciza, el aparcamiento queda 3,2 m por debajo, se entra bajo ella hasta su muro del fondo y
el suelo donde aparcan los coches está llano; nada pisa una calzada, el mapa sabe que la tienda está ahí y la puerta
de coches está en lo alto de la rampa). Tras rehornear, además `relief` y `grua`.
