# Referencia: la ermita de la Caridad, su plaza, el parque de la fuente y la guardería

Pedido por Luis el 15-11-2026 (`usuario_01_mapa.jpg` y https://maps.app.goo.gl/PGYysfepTctu4wbN9): «Ahora pinta con
la hermita de la caridad. Que es hermita, parque con fuente y guardería».

El modelo es `godot/scripts/caridad.gd` (sobre `obra.gd`). Herramientas: `tools/caridad/` (`vistas.py`, `hojas.py`,
`enganche.py`). Primera versión enseñada a Luis el 15-11-2026 (hojas en `guion/fotos/ermita_caridad/`); pendiente de su
veredicto. Prueba: `python tools/run_tests.py caridad --window` (10 fotos y 3 comprobaciones).

## Dónde
La isleta entre la avenida de Juan Carlos I (sur), la calle del Rollo (norte), la calle del Peso (este) y la glorieta
de las Viñas (oeste). Google pone la ermita en mapa (-459, 135).

## Catastro (tools/molino/catastro.py -545 55 -385 215)
- `3890803VJ5639S` (servicios públicos, «1982», 1 planta, 453 m²): x -490..-466, z 117..141. Es la **ermita** (el
  edificio del OESTE: nave larga con la puerta en el centro del lado sur, espadaña en el extremo este).
- `3890802VJ5639S` (41 m², 1 planta): x -467..-461, z 132..140: el cuerpo cuadrado más alto pegado a la esquina
  sureste de la ermita.
- `3890801VJ5639S` (servicios públicos, «1900», 1 planta, 515 m²): x -472..-442, z 108..136. Es la **guardería** (el
  edificio del ESTE, en L, con lucernarios), con su patio de vallas de colores al sureste.
- `3790101VJ5639S` («residencial 1980, 2 plantas», x -507..-493, z 135..152): NO existe; ahí está la **fuente**
  redonda del parque, centro (-499,5, 145). En el juego hay ahora un bloque genérico: hay que quitarlo.

## El sitio (Street View, noviembre de 2024 y marzo de 2013)
- Toda la isleta es un jardín elevado sobre la avenida: muro de mampostería de 1,3 a 1,8 m con pilares de ladrillo y
  verja de hierro encima; dentro, plaza con olmos desmochados y cipreses, farolas de globo, bancos, césped, un crucero
  de granito sobre gradas delante de la ermita; escaleras en la esquina de la calle del Peso.
- El parque de la fuente queda al oeste (x -527..-492), con senderos (ya están en el mapa como calles peatonales).

## El relieve del juego (¡ojo!)
El suelo cae 7 m del noreste (+0,5) al suroeste (-7) a lo largo de la isleta (relieve exagerado x2,5). Decisión: NO
allanar (movería cuatro calles varios metros). La plaza delante de los edificios es una tarima casi llana que por el
norte enrasa con el terreno al pie de las fachadas y por el sur acaba en el muro de mampostería (1,2 a 1,7 m sobre la
acera de la avenida); los edificios quedan algo enterrados por la calle del Rollo; el parque sigue el terreno.

## Street View: cámaras (tools/molino/panos.py)
Avenida, noviembre de 2024: `c6fz_OyVjRb6I3244Gsi0g` (-457,8, 157,6), `8JVYzyyYy3o8SKWMK_XIVA` (-488, 162,3),
`nOd4Cnp722SeEYuYvCVw1g` (-425,3, 153,7). Marzo de 2013 (árboles pelados): `_qiaWS3AD3R5h2ZkYtJ41g` (-445,8, 155,3),
`lc3ldm-p8Q5bQSB-Gt7h0A` (-475,7, 160,3), `YeJi0VQBvluVgdh0BOqCHg` (-490, 162,7), `pp-LSLplLRjwp097_6ZaIA`
(-425,1, 151,5). Calle del Peso, 2024: `BRPJt1JJGd20eHnU9j6PhQ` (-426,7, 139,3).

## Las tres fotos 360 (lo que mandan)
Luis, al ver la primera versión (15-11-2026, `usuario_02_circulos_360.jpg`): «Hmm. Es mejorable. Creo que no has hecho
suficientes capturas. En esos tres círculos street view tiene imágenes 360 de la zona». Son fotoesferas de
particulares, no del coche de Google: `CIHM0ogKEICAgICK9OfEfA` (junto a la fuente), `CIHM0ogKEICAgICK9KfjwQE` (en el
parque, hacia la calle del Rollo) y `CIHM0ogKEICAgIDq88Xe4wE` (en la plaza, ante el patio de la guardería). Se abren
con `https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=LAT,LON` en un punto de dentro de la isleta, y de la
dirección que queda en la barra sale la de su imagen (`…=w1024-h640-k-no-pi-5-yaRUMBO-ro0-fo80`). No se guardan.
Lo que enseñaron y la primera versión tenía mal:
- **La fachada principal de la ermita es la de poniente**, hacia el parque: hastial blanco bajo cubierta a cuatro
  aguas, puerta grande de arco con recerco de piedra, hornacina encima, un farol a cada lado; delante, **cuatro
  columnas de granito** sobre un poyo bajo de mampostería. A su izquierda, una casa más baja con un portón de madera.
  En el lado de la plaza solo hay una puerta pequeña. La espadaña está sobre el extremo este de la nave.
- **La fuente** es un pilón redondo de mampostería con albardilla y, alrededor, un anillo de muretes curvos iguales.
- **El parque es de tierra**, con parterres de césped bordeados alrededor de los olmos, bancos de piedra y farolas de
  farol; lo cierra el mismo murete con verja también por la calle del Rollo.
- **La plaza**, de los edificios a la avenida: acera pegada a las fachadas, explanada de tierra, paseo de baldosa con
  bancos de hierro y farolas, césped con los olmos tras una barandilla baja verde, y el crucero entre cipreses al sur
  del paseo.
- **La guardería**, por el patio, es de mampostería con ladrillo y ventanas enrejadas, con un porche cerrado con verja
  azul alta y una pérgola con toldo.

## Las capturas desde la calle del Rollo
Luis, al ver la segunda versión: «Falta las columnas de piedra y la entrada grande a la hermita por ejemplo. A parte de
capturas desde la calle del rollo». Cámaras de noviembre de 2024 a lo largo del Rollo, de oeste a este:
`R8wMUnpTRFOH4nY_Pa-CBg` (-508,2, 121,4), `iKfJ7n5oUj15gEc2PvFHlQ` (-497,1, 118,3), `AJc5A8sLTP699Y9K1nEfOA` (-487,5,
114,9), `yZ54T0p9QIwaOSkpCbyJfg` (-477,7, 111,6), `lVTuJSsFg1ns3K8L5OTK4A` (-467,6, 109,0), `ZPwuRUKs5elDYZmBNIAX3Q`
(-457,3, 106,2), `HunZ4RQmngS_4PXutUbrOg` (-446,4, 103,6); todas mirando al sur (rumbo 175). Lo que enseñan:
- **Las columnas son cinco**, fustes lisos de granito claro de alturas distintas, en fila paralela a la fachada de
  poniente y a unos 4 m de ella, sobre un murete bajo; entre ellas y la fachada pasa un **camino empedrado** que
  entra al parque desde el Rollo (el murete del parque empieza pasadas las columnas).
- **La puerta grande** lleva recerco de piedra en arco dentro de un marco cuadrado y un medallón redondo encima.
- **La casa baja**, por el Rollo, es un muro largo blanco con zócalo pintado de salmón y una rejilla alta.
- **La guardería**, por el Rollo: paños de mampostería entre ladrillo, alero de teja, ventanas enrejadas y, en medio,
  un gran arco acristalado de carpintería gris con banda crema, que es su entrada. Su cartel dice «Escuela Infantil
  Municipal» (así va en el juego: no es nombre de negocio); buzón verde y azulejo «Calle Rollo».

## Veredicto
Luis, al ver la tercera versión (15-11-2026): «Está incrible. Solo añadiría más juegos a la guardería. Está un poco
vacía. Quizá algún balón o portería pequeña también». Hecho: el patio lleva tobogán, columpios, tiovivo, balancín y
dos caballitos de muelle (del lote del parque de la plaza), un arenero con su cubo y su pala, dos mesitas con
taburetes, una rayuela pintada, una portería pequeña y cinco balones. Hoja: `guion/fotos/ermita_caridad/04_patio_guarderia.jpg`.
Al ver el patio: «Impecable. Buen trabajo».

## Marco y medidas (en el juego)
Origen en la esquina suroeste de la ermita, mapa (-489,5, 141,2); `x` a lo largo de su lado sur (hacia el este), `z`
sale hacia la avenida. La plaza sube 4 cm por metro hacia el este (`SLOPE`).
- Ermita: nave de 23,04 x 8,6 m, muros de 6 m; fachada de poniente en x = 0 (puerta en z = -4,3); casa baja al norte
  (planta de Catastro), de 4,1 m. Cinco columnas en x = -4,3, cada 4,1 m.
- Cuerpo de la esquina: 5,6 x 7,5 m, 7,2 m de alto.
- Guardería: planta de Catastro (ocho esquinas); su patio, un escalón por encima de la plaza, con verja de colores.
- Crucero: en (12,7, 11,4). Fuente: en (-10,2, 3,2). Muro de la avenida: z = 16,17 - 0,1337 x. Paseo: z de 4,6 a 7,8.

## En el juego
- No se entra en la ermita ni en la guardería; el patio de la guardería está cerrado. Sin personajes ni niños.
- El cartel de la guardería dice «ESCUELA INFANTIL MUNICIPAL», como el real; la ermita no lleva rótulo.
- Se entra a la plaza por la calle del Peso y desde el parque (unos peldaños en cada lado); al parque, por la calle
  del Rollo, por la esquina de la glorieta y por el final de la avenida.

## Lo que es aproximado
- **Los niveles**: el relieve del juego cae 7 m en la isleta (el real, metro y medio). La plaza no es llana del todo,
  los edificios quedan medio enterrados por la calle del Rollo, el parque va en cuesta y la fuente se apoya en un
  talud de tierra por el lado bajo. El muro de la avenida sale de 1,5 m, como el real.
- **La ermita**: anchos y alturas de la fachada de poniente, a ojo sobre las fotos 360 (sin medir); la casa baja del
  norte y su cubierta, simplificadas; las ventanas del lado de la plaza, a ojo.
- **La guardería**: fachadas a ojo; los juegos del patio son los del lote del parque de la plaza, colocados a gusto
  (los reales no se distinguen en las fotos).
- **El parque**: parterres, árboles, farolas y bancos colocados a ojo; el pavimento de losa por dentro del murete del
  Rollo no está.
- **Escalera de la esquina de la avenida con el Peso**: no está; se entra por el Peso unos metros más arriba.
