# Referencia: el supermercado de la carretera antigua («Mercamona») y su aparcamiento a desnivel

Pedido por Luis el 15-11-2026 (`usuario_01_zona.jpg`, la zona rodeada en rojo sobre el mapa): «Ahora habría que
intentarlo con el Mercadona (que llamaremos Mercamona). Es más o menos toda la zona roja. Tiene aparcamiento a
desnivel. Varios bloques (no solo el rojo). Aquí toma varias fotos desde todos los ángulos posibles. Incluso dentro del
aparcamiento».

El modelo es `godot/scripts/mercamona.gd` (sobre `obra.gd`). Herramientas: `tools/mercamona/`.
Primera versión enseñada a Luis el 15-11-2026 (hojas en `guion/fotos/mercamona/`). Su veredicto: «Estupendo. Se queda así».
Prueba: `python tools/run_tests.py mercamona` (12 fotos y 3 comprobaciones).

## Dónde
Lado este del pueblo, entre la carretera antigua de Madrid a Cádiz (al oeste) y un solar (al este); Google lo sitúa
en 39,46598, -3,52293, mapa (909, 334). Catastro `5187002VJ5658N` (comercio, 2019): una planta de 2.962 m² CON SÓTANO
(el aparcamiento) y un cuerpo de dos plantas de 208 m² en la esquina noreste; y `5187001VJ5658N` (176 m², «1970»): una
casita antigua al norte, blanca, con tejado a cuatro aguas y porche.

## Marco
Origen en la esquina noroeste de la tienda, mapa (905,0, 306,1). `x` a lo largo de su fachada oeste, hacia el sur
(u = (-0,1838, 0,983)); `z` sale hacia la carretera antigua (oeste); el este es `z` negativa. `y` = 0, el suelo de la
tienda; el aparcamiento está 3,2 m por debajo (`low`).

## Fuentes
- **Street View**, noviembre de 2024, desde las tres calles que lo rodean: la carretera antigua (oeste), la calle del
  norte junto a la rotonda y la calle del lado noreste del aparcamiento. 26 vistas en `tools/mercamona/capturas.py`;
  todas las cámaras con sus pasadas antiguas: `python tools/molino/panos.py cerca 0kuTvD40S4ObcE2J8Y1McQ 930 335 125`.
- **Dentro del aparcamiento no hay fotos**: es suelo privado, el coche de Google no entró, y no hay fotos 360 de
  particulares (se buscó en cuatro puntos: la entrada, el centro del aparcamiento, bajo la tienda y la explanada). Lo de
  dentro se ha sacado de vistas con zoom desde la valla (bajo la tienda, la rampa, la caseta, la escalera).
- **Catastro** y **ortofoto**: `python tools/molino/catastro.py 780 220 1040 450 partes.json`,
  `python tools/plaza/aerea_wmts.py 850 250 1010 420 0.17 aerea 20`.

## Lo que hay
- **La tienda**: una caja larga (85 × 39 m) de chapa ondulada en franjas verticales de grises y blanco, de unos 7,4 m.
- **Fachada oeste** (a la carretera): en el extremo norte, la entrada: un cuerpo blanco más alto con el nombre en
  verde y el logotipo redondo, frente de cristal oscuro debajo con marquesina y puertas correderas; delante, una valla
  de lamas de colores (verdes, blanco, gris) sobre murete blanco, césped con chopos y bancos. En el extremo sur, el
  muelle de carga: caja blanca con el logotipo sobre una persiana grande, y un patio tras malla verde.
- **Fachada este**: muro blanco con una banda de franjas arriba; debajo, la planta del aparcamiento abierta entre
  pilares, con coches bajo la tienda. Escalera de emergencia metálica en el extremo sureste.
- **Bloque noreste** (dos plantas): chapa en grises más oscuros sobre zócalo de piedra, ventanas cuadradas grandes.
- **Aparcamiento**: explanada de asfalto con plazas pintadas, una planta por debajo de la tienda, tras malla verde
  sobre muro de hormigón. Se entra por la esquina norte, bajando una rampa junto al edificio, bajo un cartel azul con
  flecha y una señal de altura 2,7 m. Dentro, una caseta blanca de instalaciones con puertas marrones, farolas altas,
  un cobertizo de carros.

## En el juego
- El nombre es «MERCAMONA» (de Luis). El logotipo es nuestro: una cara de mona en un aro verde (no el del real).
- No se entra en la tienda. Sin personajes. Se puede bajar al aparcamiento con el coche y meterse bajo la tienda.
- La calle del lado noreste del aparcamiento no existe en el mapa del juego: hay un firme de asfalto desde el final
  del ramal del norte hasta la puerta del aparcamiento.
- **El hoyo**: el terreno del juego solo caía 1,5 m de un lado a otro de la tienda. El horneado excava el aparcamiento a
  3,2 m bajo el suelo de la tienda (`pit` en `tools/bake_godot.py`): 32 nudos del relieve, sin tocar ninguno a menos
  de 19 m de una calle de coches, de modo que ninguna calzada cambia de altura.

## Lo que es aproximado
- **La calle del lado noreste**: en el juego es una recta que pasa unos 5 m más cerca de la tienda que la real y
  termina de otro modo. El bloque noreste va recortado a ella, y la valla del aparcamiento, 3 m retirada.
- **Bajo la tienda** solo hay aparcamiento desde unos 25 m de la esquina norte hacia el sur (`un`): más al norte el
  terreno todavía está bajando desde la calle (ahí la tienda lleva zócalo macizo). En la realidad entra bajo toda ella.
- **La rampa**: en la realidad baja pegada al edificio entre muros; en el juego es la propia caída del asfalto desde
  la puerta, sin muros.
- **El interior del aparcamiento** (plazas, flechas, caseta, cobertizo de carros, escalera): sacado con zoom desde la
  valla y de la ortofoto; no hay fotos de dentro. Número y sitio de las plazas, a ojo.
- **La fachada oeste**: anchos de la entrada y del muelle medidos sobre Catastro y la ortofoto; alturas, a ojo
  (7,4 m la nave, 9,4 la entrada, 8,5 el muelle). Las franjas de la chapa son un ritmo inventado con los tonos reales.
- **La casita antigua del norte**: volumen de Catastro con tejado y porche; sus huecos, a ojo.
- **La cubierta** (placas solares, lucernarios, máquinas): colocada a ojo sobre la ortofoto.
