# «Tetoqa»

Luis, 23/11/2026, con una captura de Street View (C. Sta. Ana 54, noviembre de 2024): «Vamos con la tienda de complementos Tutoq (que llamaremos Tetoqa). Mismo tratamiento que con MiniPrecio pero esta vez para complementos».

**Aprobada** por Luis el mismo día: «Así está perfecto. Visto bueno».

Es la tienda de complementos (bolsos, zapatos, sombreros, pañuelos, bisutería y algo de ropa) de la esquina de la calle de Santa Ana con la calle del Cristo. **En el juego se llama «Tetoqa»**. «Mismo tratamiento» que el MaxiPrecio quiere decir: fachada hecha a mano desde Street View con rótulo propio, horario con estado abierta y cerrada, interior aparte con flecha verde y el maniquí rompible de la puerta, que cambia cada día y solo sale con la tienda abierta.

**El rótulo.** El real es un cartel blanco con «Complementos» en letra rosa manuscrita, ramitas de flor rosa en las esquinas y el nombre pequeño abajo a la derecha. El nuestro está dibujado de nuevo: «Complementos» en rosa con una rúbrica debajo, ramitas de **flor de almendro** (la primera primavera de La Mancha) y «Tetoqa» pequeño en la esquina. Sin teléfono, sin dirección y sin redes.

## Reparto del trabajo

- **Edificios Especiales (Pretil)**: la fachada, el horario, el interior y el maniquí.
- **Sistemas**: que la Tetoqa entre en `tiendas_ropa.gd` (`SHOPS`) como el MaxiPrecio, cerrada hasta el Vizum de Josefa, con su peseta en el mapa. Si Luis quiere dependienta o venta de complementos, el interior expone `clerk_spot`, `clerk_h`, `client_spot`, `client_h`, `probador_spot` y `probador_h`.

## Dónde está

- Es la casa `stana_54` de Texturas, cedida en `casas_calles.gd` con `"stana_54": ["obra"]`. Sin rehorneado.
- El contorno, en el orden del anillo: F0 (402.31, 148.04) y A (405.45, 144.29) son la medianera con `stana_52`; A–B (7,32 m) es la fachada a Santa Ana; B (412.54, 146.11)–C (414.3, 148.59) es el chaflán (3,04 m); C–D (7,79 m) es la fachada al Cristo hasta D (412.17, 156.08); de D vuelve hacia el oeste por (407.5, 154.88) y la trasera.
- Al sur de D el mapa está vacío. En la realidad está pegado el edificio de una juguetería, de la misma altura. Por eso esa pared es una medianera lisa que se ve desde la calle.
- Las calles apenas tienen pendiente: 0,3 m de A a D. El portal de los pisos, que está en el extremo alto, se sube al suelo de su sitio.

## Scripts

- `godot/scripts/tetoqa.gd` (`world.tetoqa`, paso «the shop Tetoqa»): la fachada, sobre `esquina.gd`, con las plantas de arriba en vuelo (0,45 m sobre las tres calles) y el tejado a cuatro aguas: una vertiente a cada calle y otra a la trasera. Expone `door` (en la acera, delante del chaflán), `sa_spot`, `cr_spot`, `open_at(day, hour)`, `set_open(on)`, `is_open`, `dentro` y `maniqui`.
- `godot/scripts/tetoqa_dentro.gd` (`world.tetoqa.dentro`): el interior, un decorado aparte en (−1000, −1200) al que se entra por la flecha verde de delante del chaflán (`entradas.gd`). Está a 260 m de cualquier calle, sin árboles a menos de 790 m, sin campos y a más de 600 m de otro decorado (el más cercano es el del Recress).
- `godot/scripts/maniqui.gd`: el maniquí del MaxiPrecio, con un quinto parámetro `trinkets` para una tienda de complementos y un sexto, `in_window`, para los de detrás del cristal.
- `godot/scripts/semaforo_ambar.gd` (`world.tetoqa.semaforo`): el semáforo del chaflán.
- Dibujos: `tools/tetoqa/dibujos.py` genera en `godot/assets/tetoqa/` el rótulo, el cartel del horario, la cara de la caja de luz y el nombre de la pared del fondo de dentro. Después de cambiarlos hay que importar: `Godot --headless --path godot --import`.
- Prueba: `python tools/run_tests.py tetoqa --timeout 600`. Saca las vistas de Street View (las mismas cámaras) abierta, cerrada, al atardecer y de noche, el maniquí seis días y seis vistas del interior, y pasa `_tetoqa_checks()`, que va también en la prueba completa. Las hojas con capturas del juego están en `guion/fotos/tetoqa/`: la fachada, el interior, el maniquí y, en la cuarta, lo que Luis aprobó.
- Para Sistemas: quien está en el probador (`probador_h`) mira un poco hacia el centro de la tienda y no recto hacia fuera, porque el probador está en la esquina de la derecha y la cámara, a un paso a su lado, caería en la pared.

## Horario

**Inventado**: Google Maps no da horario de la tienda real (23/11/2026). Es el normal de una tienda del pueblo: de lunes a viernes de 10:00 a 13:30 y de 17:30 a 20:30, los sábados de 10:00 a 14:00 y los domingos cerrada. Hay un cartel con el horario pegado en el cristal del primer escaparate de Santa Ana, junto al chaflán, y otro por dentro, junto a la puerta. Si Luis da el real, se cambia en `HOURS` y en `tools/tetoqa/dibujos.py`.

- **Abierta**: la persiana del chaflán subida, la puerta de cristal detrás, luz dentro, los escaparates encendidos, el maniquí fuera y la flecha verde.
- **Cerrada**: la persiana blanca bajada y los escaparates en penumbra. El maniquí se recoge. Así estaba cuando pasó el coche de Street View.

## Qué hay

**Fachada** (Street View de noviembre de 2024). Bloque de pisos en esquina: planta baja y dos plantas, tejado de teja vieja a cuatro aguas.

- **La planta baja** es la tienda, chapada de granito pulido rosado oscuro, con rejillas de ventilación bajo los escaparates.
  - **A Santa Ana:** dos escaparates de ropa colgada con bolsos y zapatos delante, en aluminio blanco. Encima del primero va el rótulo. Sobre el machón del portal, un aparato de aire acondicionado con la caja de la alarma al lado. En el extremo oeste, el portal de los pisos en piedra clara, con su escalón, una cancela gris y la puerta de madera detrás.
  - **En el chaflán:** la puerta de la tienda tras una persiana blanca.
  - **Al Cristo:** dos escaparates, como en Street View. El ancho tiene un maniquí en cada punta y, entre ellos, baldas de cubos blancos con bolsos, zapatos, sombreros y pañuelos, y un busto de costura encima con chaqueta crema y lazo negro. El estrecho tiene dos maniquíes y, a su lado, baldas de cristal con bolsos.
  - **La caja de luz** de junto al chaflán, en el Cristo, lleva el nombre: «TETOQA» en mayúsculas grises espaciadas entre ramitas de almendro, con marco verde (`caja.png`). Al principio la dejé en blanco, pero en Street View, desde el Cristo, se ve el nombre de la tienda real.
- **Las plantas de arriba** salen en vuelo sobre la acera. Son de ladrillo naranja con paños crema enmarcados por el ladrillo: tres paños apaisados en los tramos ciegos y dos estrechos entre ventanas.
  - Los balcones franceses tienen marco de aluminio blanco, persianas beis a medio bajar, recerco de ladrillo y balconcillo de forja con su faja de volutas. Hay dos por planta a cada calle, hacia el extremo lejano de la esquina, y uno ancho de dos hojas en el chaflán.
  - Sobre cada planta corre una franja crema con un rombo de ladrillo encima de cada balcón y en los tramos ciegos.
  - Arriba, la cornisa de ladrillo con su diente de sierra y la fila de bocas de teja del alero. Los cables corren por el canto del vuelo.

**Interior (borrador, aprobado así por Luis).** Las fotos de dentro de Google Maps solo se ven con la sesión iniciada; si Luis manda capturas, se rehace. Mientras, es una tienda de complementos de pueblo, sacada de lo que enseñan sus escaparates:

- una sala de 7 × 9 m, paredes blancas, suelo de tarima clara y focos redondos en el techo;
- a la izquierda al entrar, baldas de cubos blancos con bolsos, zapatos, sombrereras y pañuelos doblados;
- a la derecha, el mostrador con la caja y una pared rosa detrás con baldas de cajas de regalo y bolsos; pasado el mostrador, una barra de ropa con una fila de ganchos encima, con sombreros y pañuelos;
- en medio, una vitrina de bisutería y relojes, una torre giratoria de gafas de sol, una mesa redonda de pañuelos y sombreros y un sombrerero;
- al fondo, «Tetoqa» en letra rosa sobre un banco bajo de sombrereras y un espejo ovalado;
- en la esquina del fondo a la derecha, el probador con cortina rosa, espejo largo y taburete.

Dentro no hay maniquíes ni figuras. **El azafrán escondido** está en la última sombrerera del banco del fondo, a la derecha: está abierta, con la tapa apoyada de canto y la flor asomando (`saffron_spot`, `"id": "tetoqa"`).

## El maniquí de la puerta

Es el mismo de `maniqui.gd` que el del MaxiPrecio: figura del juego en plástico blanco, sin cara ni pelo, sobre su peana. Lo pone `tetoqa.gd` en la acera de Santa Ana, junto a la esquina, un poco girado hacia la puerta del chaflán.

- Como es de una tienda de complementos (`trinkets`), lleva **siempre sombrero** y casi siempre gafas, pendientes y algo al cuello: cadena, medalla, perlas, bufanda, flores, gargantilla o pañuelo de fiestas.
- Cambia cada día como el otro: la semilla es el día, así que un mismo día viste siempre igual.
- Es mobiliario de la calle (`props.gd`): un puñetazo o un coche lo tiran y al día siguiente vuelve.
- Solo está fuera mientras la tienda está abierta.

## Los maniquíes de los escaparates

Son cuatro, tras los cristales del Cristo (`tetoqa.dummies`): el mismo `maniqui.gd` con `in_window`. Llevan también sombrero y adornos y cambian cada día mientras nadie los mira. No son mobiliario de la calle: no se pueden tirar ni chocar, y están igual con la tienda abierta o cerrada.

## El semáforo del chaflán

`semaforo_ambar.gd`: un poste gris claro con una cabeza de tres luces, en la acera, en la punta del chaflán que da al Cristo, junto al bordillo. Mira hacia Santa Ana, al este, como en Street View.

- **Solo parpadea el ámbar**: en Street View tiene el ámbar encendido de día, así que es un semáforo de aviso y no un ciclo de cruce. No para a nadie («Solo paran coches», y un ámbar intermitente ni eso).
- Es mobiliario de la calle (`props.gd`, como `"semaforo"`): un coche o un puñetazo lo tiran, se apaga y vuelve al día siguiente.
- Para Sistemas, si algún día lo lleva `semaforos.gd`: `set_light("verde" | "ambar" | "rojo" | "off" | "blink")`, y `auto = false` le quita su parpadeo.

## Lo que propuse y Luis aprobó

Luis, 23/11/2026: «Si a las tres recomendaciones». Eran el azafrán escondido, los maniquíes de los escaparates y el semáforo del chaflán, y los tres están puestos (ver arriba). Del azafrán propuse dos sitios y elegí la sombrerera del banco del fondo.

## Pendiente

- **La juguetería del sur**: si Texturas pone esa casa, la medianera del sur deja de verse.
