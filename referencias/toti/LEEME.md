# Referencia: la Pizzería Toti

Pedida por Luis el 17-11-2026, con una captura de Google Maps: «Tu siguiente objetivo es la pizzería ... Con su terraza
y todo». Nombre: «La llamaremos Pizzeria Toti» (el nombre real no sale en el juego).

El modelo es `godot/scripts/toti.gd` (sobre `obra.gd`), en `world.toti`, sobre la casa `cajal_3` del mapa (la segunda de
la acera este de la calle de Ramón y Cajal desde la esquina con la del Salvador; 16,48 m de fachada según el Catastro).
Texturas la marca `["obra"]` en `casas_calles.gd` y `casas.gd` no la dibuja. Sin rehorneado. Herramientas en `tools/toti/`.

## Fuentes
- **Street View**: noviembre de 2024, abril de 2021, octubre de 2019 y marzo de 2013, en cinco puntos de la calle
  (`tools/toti/capturas.py`; las fotos son de Google y no se guardan aquí).
- Las cámaras de Google en esa calle no están donde dicen: la de enfrente de la pizzería (2024) está unos 2,6 m más al sur
  y 1,9 m más lejos de la fachada. Se ajustó con los dos extremos de la casa: la esquina al norte y el escalón con la casa
  siguiente, la de la frutería del toldo amarillo, al sur. `python tools/merkocarry/alzado.py CARPETA b24 -148.74,14.86
  -152.18,30.98 SALIDA.jpg -1,17.5 10 2.62,-1.93 44` tiende la foto sobre la fachada ya corregida.

## Lo que lleva
- **La casa**: tres plantas. Las dos de arriba son de ladrillo naranja (el `brick_orange` de las casas) y vuelan 0,3 m
  sobre la calle. Tienen tres columnas de ventanas anchas por planta: persianas blancas casi bajadas, y la del medio con
  marco oscuro y visillos en la primera. Llevan alféizares, un aparato de aire en el ladrillo, la albardilla y una hilada
  a sardinel arriba.
- **La pizzería** (de 0 a 9,6 m desde el norte), en un marco de granito gris:
  - la puerta acristalada y un panel de vidrio con la carta pegada;
  - el escaparate grande de tres hojas;
  - un tercer hueco tras su reja de tijera, cerrada.
  - Encima, el toldo granate en dos tramos. Su faldón lleva los teléfonos garabateados y «PIZZERIA TOTI».
  - Sobre el toldo:
    - la caja de luz blanca con «PIZZERIA / TOTI» y nuestra insignia de pizza en los dos extremos;
    - dos aparatos de aire;
    - el óvalo luminoso de cerveza, sin marca, en su brazo;
    - las cajas grises de la luz.
  - Los rótulos los dibuja `tools/toti/rotulo.py`.
- **El portal de los pisos** (azulejo blanco): la puerta labrada de dos hojas con su reja encima y la cochera de tablas
  con su placa de vado. El número de la casa no se pone.
- **Dentro**, tras el cristal:
  - suelo de barro y paredes cálidas;
  - el mostrador al fondo con el horno encendido en la pared y la carta;
  - cinco mesas con sillas y las lámparas.
  - Todo esto solo se enciende mientras está abierta.
- **La terraza**, en la acera:
  - tres mesitas con una silla a cada lado (las pone `props.gd`, por `world.extra_terrazas` con sus piezas: se rompen) y
    sitio para dos vecinos;
  - una barandilla negra con una valla baja de madera a lo largo del borde de la acera, abierta al norte junto a la
    puerta;
  - dos pilas de sillas blancas contra la reja.
  - En la realidad (2024) la terraza ocupa unos 2,5 m de calle. En el juego, el asfalto dibujado de Ramón y Cajal mide
    4,4 m y la acera de ese lado ~1,4, así que la terraza se ajusta a la acera (`terrace_deep`).
- **Horario** (provisional, pendiente de Luis): de 13:00 a 16:00 y de 20:00 a 24:00 todos los días.

## Pruebas
`python tools/run_tests.py toti`: fotos de la fachada desde el frente, el norte y el sur, la terraza, el toldo, lo de
arriba, el portal y el interior, abierta, cerrada y de noche, y una desde el aire. Comprueba que está sobre su casa del
mapa y que `casas.gd` ya no la dibuja, que la fachada te para, que la terraza está puesta y no pisa el asfalto, y el
horario y sus luces.
