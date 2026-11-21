# Referencia: la ermita del Santísimo Cristo del Prado

Pedida por Luis el 21-11-2026, con una captura de Google Maps. Sus palabras: «Siguiente proyecto la Ermita del Cristo
del Prado (junto a la residencia, en la misma manzana)».

El modelo es `godot/scripts/cristoprado.gd` (sobre `obra.gd`), en `world.cristoprado`. Las herramientas están en
`tools/cristoprado/`.

Su marco:
- el origen está en la esquina suroeste de la nave, donde acaba la fachada principal por el sur;
- x va a lo largo del costado sur, hacia el este (este-sureste);
- z sale del costado sur hacia el Paseo del Cristo;
- y = 0 es el suelo ante la puerta principal.

El suelo del juego baja 0,8 m de la fachada a la cabecera: los muros se hunden en él y el enlosado se tiende sobre él.

## Fuentes
- **Catastro**: el edificio `4587301VJ5648N`, que es la ermita y la Residencia de mayores juntas (de 2006, seis partes).
  - La ermita son tres piezas: la nave (un trozo de la parte 4), el cuerpo alto del crucero (la parte 3) y la cabecera
    (la parte 1).
  - El resto es la Residencia de mayores, hecha a mano en `residencia.gd` (abajo).
  - Para sacarlo: `python tools/cristoprado/manzana.py PLANO.png partes=4587301`.
- **Ortofoto** (PNOA): `tools/ign/cristoprado.jpg`, de `python tools/fetch_ortho.py cristoprado 250 405 380 560 0.12`.
- **La web del Ayuntamiento** (madridejos.es, «Ermita del Santísimo Cristo del Prado»): cuatro fotos de 2019 de la
  fachada principal y el calvario. Sirvieron para medir la fachada: sus 9,62 m de ancho dan la escala. No se guardan
  aquí.
  - Su texto: la ermita es de 1660 y tiene dos puertas; la principal es la que da al paseo.
- **Street View** (`tools/cristoprado/capturas.py`; las fotos son de Google y no se guardan aquí):
  - alrededor, en 2024, 2021, 2019, 2013 y 2009;
  - la placita de la fachada, solo en 2013, desde la calle del noroeste.
  - Medidas con `medir.py` (en el borrador, no en el repositorio): punto de la foto → plano de un muro.
- **Cuidado con las fotos de 2024**: con el sol de noviembre, la cara sur sale quemada, como si estuviera encalada. No
  lo está: a la sombra de los árboles se ve la fábrica.

## Medidas
- **Nave**: 16,94 × 9,62 m, alero a 11 m (la foto de la web y Street View s4 y s5 coinciden), cumbrera a 13,2 m.
- **Puerta lateral**: a 10 m de la esquina suroeste, 2,1 m de ancho.
- **Crucero**: 11,04 × 11,14 m, sale 0,77 m del costado sur. Cornisa a 15 m y pirámide hasta 17,4 m.
  - En Street View s1 parece más estrecho (8,9 m): esa cámara está mal situada en z. Contado con su escala, cuadra con
    el Catastro.
- **Cabecera**: alero a 8,9 m.
- **Campanario**: 2,46 m de lado, sobre la fachada. Cornisa a 15,6 m, aguja de pizarra y cruz hasta los 20 m.
- **Calvario**: en (268,1, 495,8) del mapa, en el parque. Está triangulado desde Street View w1 y w2.

## Lo que lleva
- **La fachada principal**, a poniente, sobre su placita:
  - pilastras de ladrillo en las esquinas y un paño de mampostería en medio;
  - la portada de piedra clara: dos columnas toscanas sobre pedestales, el arco de medio punto, el entablamento, el
    frontón partido con la tablilla roja, la ventana enmarcada con su frontoncillo, las dos pirámides y la cruz;
  - dos faroles.
- **El campanario**: de ladrillo, un arco por cara con la campana dentro, chapitel de pizarra, bola, aguja, cruz y
  veleta.
- **La nave**:
  - el costado sur, de aparejo toledano, con la puerta lateral en su marco de piedra y una ventanita encima;
  - el tejado a cuatro aguas, con faldón sobre la fachada y una buhardilla pequeña.
- **El crucero**: ladrillo y cajones de mampostería, una ventana al Paseo, la pirámide de teja con su varilla y su
  cruz.
- **La cabecera**:
  - al Paseo, el portón bajo arco de sillería con su reja y el sillar hasta la esquina;
  - a la Calle del Cristo, un zócalo de sillar con un arco cegado de ladrillo y tres saeteras, la imposta y el
    ventanal con reja y copete de forja;
  - por el norte, sus lados achaflanados con ventanas enrejadas.
- **Alrededor**:
  - el enlosado claro a lo largo del costado sur. Sigue el suelo hasta el crucero y desde allí queda a nivel mientras la
    calle baja. Lo sujeta un murete de piedra con albardilla que sube de bordillo a medio metro en la esquina y rodea la
    cabecera por la Calle del Cristo, con su chaflán donde la calle corta la esquina (Luis, 21-11: «the little stone
    wall»). Los pilones están encima y el portón se abre a su nivel;
  - el ajedrezado rojo y blanco hasta el bordillo del Paseo, donde aparcan los coches, y rodeando la esquina hasta el
    asfalto de las dos calles (Luis: «the last portion of acera»);
  - la placita ante la fachada, con un anillo de piedra gris;
  - los olmos (el viejo y hueco, delante del crucero);
  - los pilones de piedra con su urna;
  - la franja con verja y ciprés junto a la Calle del Cristo;
  - el calvario del parque: tres cruces de piedra sobre un bloque de mampostería.

## El horneado
`tools/cristoprado/enganche.py`:
- No levanta la ermita, pero sí la Residencia, recortada.
- Mete el contorno de la ermita en los bloques.
- Da al mapa la clave `cristoprado` (`o`, `u`).
- No planta árboles en la acera sur, en la placita ni junto al calvario.

Solo se activa si `cristoprado.gd` lleva `const READY := true`.

`tools/cristoprado/enganche_juego.py` hace los cambios de `map_data.gd`, `world.gd` y `selftest.gd`.

## Pruebas
`python tools/run_tests.py cristoprado` hace fotos de:
- la fachada y la portada;
- el Paseo, la puerta lateral, el crucero y la cabecera;
- el campanario y el calvario;
- de noche y desde el aire.

Comprueba que los muros te paran, que el suelo ante las dos puertas está libre y que nada pisa el asfalto.

## La Residencia (residencia.gd)
- Es el resto del edificio 4587301: el bloque grande, el cuerpo redondo y el ala baja. Sus fuentes están en
  `tools/residencia/capturas.py` y en la entrada de `TRASPASO_CLAUDE.md`.
- **El ala baja, a la placita** (Luis, 21-11: «Here in red the fachada is very different to the photo, also a door is
  missing», con sus fotos 360 de Google Maps de hace seis años; no se guardan aquí):
  - cuatro ventanas, el porche de dos vanos con sus cancelas de hierro de suelo a viga, el pie derecho de madera, y una
    última ventana junto al cuerpo redondo;
  - dentro del porche: la puerta de madera de cuarterones, una ventana, la tabla de la Mayordomía con el azulejo del
    Cristo entre dos faroles, el banco y las macetas;
  - zócalo de granito claro, columnas de cajones de mampostería, cornisa de ladrillo en dientes y canecillos oscuros.
- **Su fachada está 2,85 m detrás de la línea del Catastro.**
  - La ortofoto pone su alero 2,25 m dentro de esa línea, igual de punta a punta (`perfil.py` del borrador: brillo a
    través de la fachada). La cara oeste y la fachada de la ermita sí caen en las suyas.
  - El césped de OpenStreetMap del mapa también rodea el edificio por esa línea de atrás.
  - Así queda al aire el muro del cuerpo redondo entre el ala y la ermita, con la puerta de la Residencia, como en la
    foto 360.
  - La franja que deja libre se enlosa igual que la placita.
- **La puerta de la Residencia**: en el muro del cuerpo redondo, entre el ala y la ermita. Lleva la cancela de dos
  hojas, la banda negra con el nombre, el montante de hierro con la cruz en su aro y el balcón de dos ventanas encima.
- **Fotos del juego desde los sitios de las fotos 360** (vistas de `tools/run_tests.py`; la altura es sobre el suelo):
  - `sv_goeste:302.58,492.96,1.60,288.0,487.0,1.90,70.0` (a lo largo del ala);
  - `sv_gdentro:300.6,494.0,1.60,301.7,489.4,1.70,70.0` (el porche);
  - `sv_gpuerta:301.07,492.55,1.60,305.29,494.12,2.60,75.0` (la puerta);
  - `sv_gporche:296.60,498.70,1.60,299.98,490.31,1.90,60.0` (el porche desde la placita);
  - `sv_garriba:297.0,496.0,14.0,297.2,489.0,0.0,70.0` (desde arriba).
  - La hoja es `python tools/residencia/hojas.py SV fotos=CARPETA`.
