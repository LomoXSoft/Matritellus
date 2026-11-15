# Referencia: el molino («Molino del Tío Gerardo» en el juego)

Pedido por Luis el 15-11-2026: «¿podrías ponerte con el Molino del tío Genaro? (al que llamaremos Tío Gerardo por
evitar líos). Aproximadamente la zona roja» (`usuario_01_zona.webp`: el recinto del molino, de la portada del norte al
edificio del sur, en la calle de Dulcinea del Toboso). Mismo método que el Petril y la plaza.

**En el juego no aparece el nombre real**: el molino y su molinero son «del Tío Gerardo».

El modelo es `godot/scripts/molino.gd` (sobre `obra.gd`). Herramientas: `tools/molino/`.

## Marco (`tools/molino/marco.py`)
Origen en el centro del molino, mapa (-278,0, -729,1). **x** a lo largo del muro norte del corral (este, girado 14,5°
en el sentido del reloj respecto al mapa: u = (0,968, 0,250)), **z** hacia el corral (sur). Alturas sobre el suelo
de la era. La calle queda al oeste (x ≈ -12 … -20).

## Fuentes
- **Catastro**: referencia `3998402VJ5639N` (servicios públicos, 1992), cuatro partes: el corral (2 plantas, 316 m²:
  x de -11,4 a 13,4, z de 16,9 a 29,3, con un saliente al noreste hasta z = 12,6), dos naves bajas al norte
  (parte 4: x -13…-4,5, z -21,8…-14; parte 2: de (-5, -27) a (8, -17,5)) y **un círculo de 2,1 m de radio en
  (-2,2, -10,8) que NO es el molino** (está 11 m al norte de donde lo pone la ortofoto: es un error de Catastro).
  Al norte, otra referencia (`3998418VJ5639N`, ladrillo visto) cierra el recinto.
- **Ortofoto del IGN** (`tools/ign/molino_wmts.jpg`, nivel 20): manda para todo lo que está en el suelo. La caperuza
  sale desplazada 1,9 m al sur-sureste (está a 9 m de altura): la base se saca de la era, que es redonda y tiene el
  molino en el centro.
- **Street View**: la calle (noviembre de 2024, y 2009, 2013 y 2021 en el mismo punto), el camino del oeste, el del
  este (al otro lado del solar, a 58 m: se ve el molino entero por encima de la tapia) y el del norte. Las fotos no
  se guardan (son de Google): `tools/molino/capturas.py` las vuelve a bajar. **La posición que da Google en esta
  calle está 1,5 m al este de la real** (la cámara va por el centro de la calzada, x ≈ -16).
- **Fotos de visitantes** y la web del sitio: solo para ver cómo es por dentro (no se guardan).

## El molino
- Torre de mampostería encalada, casi cilíndrica: **6,2 m de diámetro** (150 px a 58 m con un campo de 40°).
- **Alero a 8,1 m** del suelo de la era y punta de la caperuza a 11,6 (caperuza cónica oscura, de 3,5 m, que vuela
  15 cm). Cota del alero 704,8 m; la calle delante, 696,7.
- Doce **ventanillos** bajo el alero (de 0,33 m); una ventana pequeña a media altura; **puerta** de madera oscura
  en un hueco con arco, a ras de suelo.
- **Aspas**: cuatro, con enrejado de palos (el macho, descentrado); brazo de unos 7 m, enrejado de 1,8 m de ancho
  desde 1,2 m del eje. En 2024 miran a la calle (oeste). Detrás, el **palo de gobierno** baja inclinado hasta el suelo.
- En el juego giran (`world.mill_blades`).

## El recinto (de norte a sur por la calle)
- Tapia blanca de **2,85 m** con la albardilla (1,42 veces la puerta roja, que mide 2 m), con **zócalo granate** de
  0,6 m y **albardilla de teja**; va de (-12,8, -25,9) a (-11,1, 15,6).
- **Portada** al norte (z de -25,0 a -20,4): paño más alto (3,65 m) con tejadillo sobre canecillos de madera y
  portón de madera oscura de dos hojas de 3,1 m, tallado. Antes, un trozo de tapia baja desde la esquina del vecino;
  después, un ventanuco con contraventana oscura.
- **Puerta roja** de chapa en la tapia hacia z = -7: de ella sale un camino curvo, entre bordillos, hasta la era.
- **Era** redonda de 11,5 m de radio con el molino en el centro, empedrada, a ras de calle; toca la tapia por el
  oeste. Seto alto alrededor (por el este y el sur sobre todo), reja de hierro oscuro, hitos de piedra, arbolitos al
  norte, una franja de césped al pie de las naves del norte.
- Delante del molino la tapia sube (paño blanco más alto, de 3,35 m, z de 3,4 a 7,6). Dentro, al lado, un mástil
  blanco con una cruceta.
- **Azotea** detrás de la tapia (z de 7,6 a 15,6), a 2,9 m, con barandilla de hierro negro; sobre la tapia, una
  chimenea manchega blanca.
- **Portón rojo** con arco rebajado (3,3 m de ancho, 3,15 de alto) y tejadillo justo encima, ya en la fachada del
  corral; a su izquierda, en la tapia, un **panel de azulejos** con el dibujo de un molino y su nombre.
- **El corral** (2 plantas, alero a unos 6,3 m): fachada blanca a la calle con zócalo granate, ventanas con reja
  negra, un ventanuco rojo con tejaroz, aleros de teja con canes rojos. Hacia la era, galería alta de madera roja.
  Por dentro es un patio manchego con galerías de madera almagre en dos alturas, cubierto por una **montera de
  cristal** (el rayado blanco de la ortofoto: x de -6,5 a 11,5, z de 21,5 a 27,5). Al sur, medianera blanca ciega.
- Por el este, tapia hacia el solar; al sur, un vecino de ladrillo visto.

## Hojas (`guion/fotos/molino/`)
`01` y `02`: Street View frente al juego desde el mismo punto (el molino; el recinto) · `03`: el juego por dentro y
desde el aire.

## Lo que es aproximado
- **No hay interiores**: ni el del molino ni el del corral (el patio con sus galerías está solo sugerido por la
  montera de cristal y la galería que da a la era). El portón rojo y la portada están cerrados; se entra a pie por
  la puerta roja de la tapia, que en la realidad está cerrada.
- Lo de dentro del recinto (setos, hitos, camino curvo, arbolitos, reja, muela, pilón, faroles) está puesto por la
  ortofoto y una foto de visitante: el sitio de cada cosa es bueno a un metro; su forma, de oficio.
- Las naves del norte son cajas blancas con tejado de chapa. El vecino de ladrillo del norte y los de enfrente son
  las casas genéricas del juego.
- El corral: sus cuatro tejados bajan hacia fuera desde la montera; los reales son más revueltos (hay un torreón en
  la esquina de la calle). Su fachada a la calle sí está medida (portón, rejas, ventanuco, alero).
- La fachada del corral se ha girado 2,6° para que no pise la calzada: la calle del mapa pasa medio metro más cerca
  que la real por ese extremo.
- El largo de las aspas (7,8 m) sale de las proporciones de estos molinos y de una foto en escorzo, no de una medida.
- El terreno del juego es llano alrededor (terraza); en la realidad el solar del este está 1,2 m más bajo.
- Las aspas miran al suroeste, como en 2024; el molino real las cambia de sitio.
