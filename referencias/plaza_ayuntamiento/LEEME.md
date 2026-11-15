# Referencia: la Plaza del Ayuntamiento y el Ayuntamiento

Pedido por Luis el 14-11-2026: rehacer la plaza y el ayuntamiento «de la misma manera que el Petril» (lo de dentro de
la línea roja de `usuario_01_zona_satelite.jpg`). `usuario_02_fuente_marcada.jpg`: lo rodeado en verde es **una fuente
de piedra** vista desde arriba (agua verde por las algas: en el juego, **agua limpia**).

El modelo es `godot/scripts/plaza.gd` (segunda versión; la primera estaba trazada a ojo). Las piezas con que se
construye están en `godot/scripts/obra.gd` (el oficio común de los sitios hechos a mano). Hojas en
`guion/fotos/plaza/` (`00_antes.jpg`: cómo estaba). Herramientas y cómo se usaron: `tools/plaza/LEEME.md`.

## Marco (el de siempre: `MapData.townhall`)
Origen en el centro de la fachada, **u** a lo largo de ella (hacia la calle Zaragoza), **n** hacia la plaza; alturas
sobre el suelo de la plaza. Mapa: m = (-162.26, -72.25), u = (0.9049, 0.4256).

## Fuentes
- **Catastro** (INSPIRE): ayuntamiento = `4193609VJ5649S`, dos partes de 2 plantas: el **soportal** (n de -3,2 a 0,
  u de -31,7 a 31,7: 63,4 m) y el cuerpo de detrás (n de -8,2 a -3,2). Catastro tiene además la fuente como un
  «edificio» redondo (`4193610VJ5649S`): el mapa ya no lo levanta (salía un cilindro gris de 5,5 m en mitad del agua).
- **Ortofotos del IGN** (PNOA, CC BY 4.0): la vigente a nivel 20 y las históricas de 2006, 2009, 2012, 2015, 2018,
  2021 y 2024 (servicio `pnoa-historico`). Ojo: **los tejados salen desplazados** unos 2,5 m (no es cenital): el
  alero parece estar en n = 2,5 y no lo está. Por eso la versión antigua tenía el ayuntamiento 3 m adelantado. Para
  la planta manda Catastro; la ortofoto, solo para lo que está a ras de suelo. De 2015 a 2018 se repavimentó la
  mitad sur con adoquín de colores; el quiosco y el templete ya estaban.
- **Street View**: panorámicas de marzo de 2013 tomadas *dentro* de la plaza (el coche cruzó la explanada), una
  fotoesfera de un particular de enero de 2020 junto a la fuente (cosida por un móvil: sus rumbos bailan hasta 4°,
  así que sirve para ver cómo son las cosas, no para situarlas), y las de noviembre de 2024 desde las tres calles. **La posición que
  da Google de las de dentro falla hasta 4 m**: cada una se fijó con el propio edificio (la separación de los arcos
  da la distancia a la fachada) y con los tableros de ajedrez, que la ortofoto sitúa bien.
- **OpenStreetMap**: contorno de la plaza, del parque infantil, del quiosco; fuente de beber; aseos.

## Medidas del ayuntamiento
Desde la panorámica de 2013 que está a 8,7 m frente al frontón (cámara a 2,56 m):
- **20 arcos** de 3,0 m, con el pilar central en u = 0 (el frontón y el balcón van centrados en él) y un pilar ancho
  en cada extremo. Una ventana encima de cada arco.
- Arranque de los arcos 2,55–2,60 m; clave 3,7; imposta entre plantas 4,15–4,3; ventanas altas de 1,0 × 1,5 m
  (de 5,25 a 6,75) en marcos de piedra de 0,24; cornisa de ladrillo de 8,07 a 8,6 (alero).
- **Balcón** de hierro sobre los dos arcos centrales (6,3 m), con dos puertas y tres banderas; suelo a 4,15.
- **Frontón**: hombros a 9,2 (±4,0 m), con pináculos de ladrillo y bola; rótulo «CASA AYUNTAMIENTO» justo sobre el
  alero; escudo a 9,7; el reloj a 11,3 en un cuerpo de 1,6 m de ancho, rematado en arco, entre dos pináculos pequeños.
  El reloj marca la hora del juego (`world.set_clock`). Sus agujas se dibujan desde cualquier distancia: antes,
  `Parts.thin` dejaba de dibujarlas a 32 m por ser piezas pequeñas, y desde la plaza la esfera se veía vacía.
- Bajo el soportal: pared marfil con zócalo gris, ventanas enrejadas, la **puerta principal en el arco siguiente al
  balcón por la derecha** (u ≈ 4,9), tablón de anuncios, bancos de madera, faroles colgados.
- **Testero a Zaragoza**: arco de entrada al soportal y un mural pintado (en el juego, un dibujo propio: cerro,
  molino, jinete y sol). **Testero al Arroyuelo**: arco con seis peldaños que suben de la acera elevada, y una
  ventana enrejada.

## La plaza
- **Explanada** (n de 0 a ~20): adoquín gris con bandas rojizas; dos **tableros de ajedrez** de 10 m (u de -22 a -12
  y de 13,4 a 23,4; n de 4,6 a 14,6) y el escudo del pueblo en el suelo, muy gastado, entre los dos.
- **Dos parterres redondos** de ~9,3 m: centros (2,8, 26,8) y (15,3, 24,7). Banco corrido de piedra, respaldo en
  cuatro tramos con barandilla de hierro en los huecos, árbol grande en el centro, anillos de adoquín (ya casi sin
  color) alrededor.
- **Fuente**: centro (2,5, 53,4); el agua mide 8,2 m de diámetro en la ortofoto y el murete de piedra crema (0,7 m
  de alto, para sentarse) llega a 9,4 m; surtidor en el centro; alrededor, **doce anillos** de adoquín de colores
  (rojo, verde, amarillo y azul, de fuera adentro) hasta 10 m del centro. Buzón amarillo al lado.
- Adoquín **multicolor** en la mitad suroeste (fuente, quiosco, parque infantil, templete).
- **Parque infantil**: círculo vallado (postes negros, tablas crema) de 8,4 m de radio en (-17,2, 33,5), con suelo
  de caucho oscuro. Dentro, en la realidad: la torre con tobogán, la casita de tejado rojo y amarillo, el **tronco
  tallado** y el **pino piñonero** que se inclina hacia Zaragoza (su copa es la mancha oscura que tapa el este del
  parque en la ortofoto). Fuera, hacia la escalinata del Arroyuelo, el abeto alto (-25,5, 41).
  **Los juegos son modelos libres** desde el 15-11-2026 (Luis: «sustituir juegos del parque por assets de libre uso
  de juegos de parque infantil»): el conjunto «Fun Playground» de Tiny Treats (Isa Lousberg, CC0), preparado con
  `tools/blender/parque.py` en `godot/assets/parque/juegos.glb` (créditos al lado). Puestos: la torre de tejado rojo
  con su tobogán (del lado del ayuntamiento, como la real), columpios, balancín, tiovivo, dos caballitos de muelle
  y un arco de barras. La valla, el tronco, el pino y el cartel verde siguen hechos a mano.
  **Niños** (15-11-2026, pedido de Luis a través de Sistemas): seis, que juegan el fin de semana mientras es de día
  y de lunes a viernes desde la tarde hasta que anochece; con lluvia, no. Corren de un juego a otro, se montan en el
  tiovivo (que gira mientras hay alguien encima) y en los caballitos, y se quedan un rato junto a las cosas dando
  saltitos. Son vecinos como los demás: se les puede hablar y un puñetazo los tira. Salen y se van a casa solo
  cuando nadie mira el parque (código: `plaza.gd`, «children in the playground»).
- **Quiosco-bar**: su tejado mide 10,9 × 13,5 m en la ortofoto (u de -30,5 a -19,6; n de 49 a 62,5), color arena;
  pabellón bajo a cuatro aguas; por detrás, sobre el Arroyuelo, ladrillo rojo sobre zócalo blanco. Rótulo: BAR.
  La terraza (mesas, sillas y toldos, todo se puede tirar) la sigue haciendo `props.gd`, pero desde el 15-11-2026
  la plaza le dice dónde va cada pieza (Luis: «toldos más altos y distribuidos más orgánicamente; ahora solo hay
  uno, muy largo y muy bajo»): **seis toldos cuadrados** de rayas rojas, de 3 a 4 m de lado y con la lona a
  2,6–3,0 m, cada uno girado a su manera, con una o dos mesas debajo. (El de antes quedaba a 1 m del suelo porque
  `props.gd` apoyaba las cosas en el terreno, que aquí está 1,4 m por debajo del suelo de la plaza: ahora lo de
  esta terraza se apoya en el suelo que se pisa.) La real tiene sombrillas blancas.
- **Templete** de ladrillo (centro (-20,5, 76,3), girado 20° respecto al ayuntamiento): escenario a 1 m con
  escalinata, tres arcos con celosía de hierro y tejadillo, el central más alto; detrás, la caseta de los aseos.
- Céspedes con murete al este y al sur de la fuente, con la **columna** de piedra, cedros, un ciprés grande;
  jardineras redondas pequeñas con anillos de adoquín y bancos de piedra blanca a lo largo de Zaragoza; farolas
  fernandinas; papeleras; fuente de beber; aparcabicis; la caseta azul de chucherías en la esquina sureste.
- **Lado del Arroyuelo**: acera elevada de baldosa en damero sobre muro de mampostería, bordillo amarillo y gris con
  arcos de hierro, arbolitos recortados, escalinatas con barandilla, la pasarela roja (de antes, aprobado).

## Hojas (`guion/fotos/plaza/`)
`00_antes` (cómo estaba) · `01_ortofoto_y_juego` (la ortofoto del IGN junto al juego visto desde arriba) ·
`02`–`05` (Street View frente al juego desde el mismo punto: ayuntamiento, jardín, desde el Arroyuelo y Zaragoza,
desde la calle de la Plaza) · `06`–`07` (el juego por dentro y alrededor) · `08` (de noche) · `09` (los juegos del
parque, antes y después) · `10` (la terraza del bar, antes y después) · `11` (el reloj y los niños). Las hojas `01`–`08` son anteriores a esos
dos retoques: en ellas se ven los juegos y el toldo antiguos.
La hoja con la fotoesfera de 2020 no se guarda (es de un particular).

## Lo que es aproximado
- No hay interiores. La parte trasera del ayuntamiento es un muro liso.
- De noche se encienden las farolas y los faroles del soportal; las ventanas del ayuntamiento no.
- En el minimapa el ayuntamiento no sale dibujado como manzana (nunca salió: el mapa dibuja las manzanas que
  levanta con muros genéricos, y pintar esta taparía los arcos con un muro).
- La caseta de chucherías real está en la acera de la esquina, que en el juego es calzada: queda dentro de la plaza.
- Los árboles están donde los ponen las fotos, pero en verano (las panorámicas de dentro son de invierno).
- El quiosco se ha hecho como pabellón sencillo; el real tiene más toldos y cerramientos.
- Los juegos del parque son los de un conjunto libre, no los reales: se parecen en lo que hay (torre con tobogán)
  y no en cómo es cada pieza. La casita de tejado rojo y amarillo no está (la torre lleva el tejado rojo).
- Los toldos de la terraza son los del juego (lona de rayas sobre cuatro palos), no las sombrillas blancas reales.
- La esquina suroeste de la plaza queda en el juego más alta que la calle de la Plaza (por el corte del Arroyuelo
  en el relieve): en la realidad están casi a nivel.
- Los colores están ajustados por proporciones contra fotos de día nublado; el ladrillo real varía mucho de un paño
  a otro.

## Reglas que aplican aquí
Ni nombres ni marcas reales: el bar dice BAR, los aseos ASEOS, la policía POLICÍA LOCAL. El mural del testero es un
dibujo propio, no una copia del real.
