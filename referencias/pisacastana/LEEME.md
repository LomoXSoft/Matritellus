# «Pisacastaña»

Luis, 23/11/2026, con una captura de Street View de la zapatería Pisamorena (calle de los Arcos con calle Argentina): «Perfecto. Ahora la zapatería. Usaremos Pisamorena (que llamaremos Pisacastaña). Mismo tratamiento que las otras dos tiendas pero solo con zapatos».

**Aprobada** por Luis el mismo día: «Visto bueno. Azafrán en caja de zapatos. Así está bien el interior. Las dos opciones me gustan».

Es la zapatería de la esquina de la calle de los Arcos con la calle Argentina. **En el juego se llama «Pisacastaña»**. «Mismo tratamiento» que el MaxiPrecio y la Tetoqa quiere decir: fachada hecha a mano desde Street View con rótulo propio, horario con estado abierta y cerrada, interior aparte con flecha verde y el maniquí rompible de la puerta, que cambia cada día y solo sale con la tienda abierta. «Solo con zapatos»: en los escaparates y dentro no hay más que zapatos.

**El rótulo.** El real es un cartel blanco con el nombre en mayúsculas finas grises entre líneas art déco, y el cristal esmerilado de junto a la puerta es turquesa claro con líneas blancas en rombos. Los nuestros están dibujados de nuevo con nuestro nombre: «PISACASTAÑA» en mayúsculas grises espaciadas entre dos líneas art déco (un rombo, dos rayas que acaban en galones y un abanico). Sin teléfono, sin dirección y sin redes.

## Reparto del trabajo

- **Edificios Especiales (Pretil)**: la fachada, el horario, el interior y el maniquí.
- **Texturas** cedió la casa `arcos_5` en `casas_calles.gd` (`["obra"]`).
- **Sistemas**: la Pisacastaña está en `tiendas_ropa.gd` (`SHOPS`, `"zapatos"`), cerrada hasta el Vizum de Josefa, con su peseta de bota de tacón en el mapa. Luis quiere las dos cosas que ofreció Sistemas («Las dos opciones me gustan»): frases de dependiente como las del Maxi y elegir zapatos en el banco. Ya está hecho (Sistemas, 23/11): la dependienta es Manuela Moreno (`manuela.gd`), detrás del mostrador mientras abre; en el banco se venden 14 zapatos a 20 € el par, con el color en los gatillos, y se prueban junto al espejo bajo; lo comprado va al armario de casa. Si se mueve el mostrador o el espejo, ella sigue los puntos. El interior expone `clerk_spot`, `clerk_h`, `client_spot`, `client_h`, `probador_spot` y `probador_h`; el banco está en x 0,7–2,3, z 4,93–5,37 del decorado, con el taburete delante.

## Dónde está

- Es la casa `arcos_5` de Texturas. Sin rehorneado.
- El contorno, en el orden del anillo: P0 (123.29, 89.19) y P1 (133.38, 91.21) son la trasera; P1–E es la medianera con la casa del este (el estudio de pintura); E (131.95, 105.78)–K (116.54, 102.08) es la fachada a la calle Argentina (15,85 m); K es la esquina; K–N (116.05, 88.65) es la fachada a los Arcos (13,44 m), y de N vuelve a P0 por la medianera con la casa blanca baja del norte.
- La calle Argentina apenas tiene pendiente (0,1 m). Los Arcos suben 0,3 m hacia el norte: el portal de los pisos y la tienda de electrodomésticos se suben a su suelo.
- Las dos calles miden 7,5 m de ancho en el mapa y las fachadas están a unos 3 m del eje, así que la acera cuenta como calzada: lo que se pone en la acera va pegado a la pared (el maniquí, a 0,6 m).

## Scripts

- `godot/scripts/pisacastana.gd` (`world.pisacastana`, paso «the shop Pisacastaña»): la fachada, sobre `esquina.gd`, con las tres plantas de arriba en vuelo (0,4 m sobre las dos calles) y el tejado a cuatro aguas bajo (una vertiente a cada calle, dos a la trasera y una a la medianera del este). Expone `door` (en la acera, delante de la puerta), `ar_spot`, `ac_spot`, `open_at(day, hour)`, `set_open(on)`, `is_open`, `dentro` y `maniqui`.
- `godot/scripts/pisacastana_dentro.gd` (`world.pisacastana.dentro`): el interior, un decorado aparte en (−1400, −150) al que se entra por la flecha verde de delante de la puerta (`entradas.gd`). Está a 249 m de cualquier calle, sin árboles a menos de 136 m, sin campos y a más de 1.100 m de otro decorado.
- `godot/scripts/maniqui.gd`: el maniquí del MaxiPrecio, con un séptimo parámetro, `with_shoes`, para una zapatería: siempre zapatos vistosos (botas, deportivas, sandalias, bailarinas, camperas, tacones o zapatos de vestir) y, a su lado, un pie blanco con otro par del día.
- Dibujos: `tools/pisacastana/dibujos.py` genera en `godot/assets/pisacastana/` el rótulo, el friso de los Arcos, el cristal esmerilado con el nombre, el cristal estrecho de la esquina con su cartelito, el horario, la placa de la calle, el nombre de la pared del fondo de dentro, el letrero de la tienda de electrodomésticos y el cartel de «se vende». Después de cambiarlos hay que importar: `Godot --headless --path godot --import`.
- Prueba: `python tools/run_tests.py pisacastana --timeout 600`. Saca las vistas de Street View (las mismas cámaras) abierta, cerrada, al atardecer y de noche, el maniquí seis días, los escaparates, la puerta y siete vistas del interior, y pasa `_pisacastana_checks()`, que va también en la prueba completa. Las hojas con capturas del juego están en `guion/fotos/pisacastana/`.

## Horario

**El real** (Google Maps, 23/11/2026): de lunes a viernes de 10:00 a 13:30 y de 17:00 a 20:00, los sábados de 10:30 a 14:00 y los domingos cerrada. Hay un cartel con el horario pegado en el cristal esmerilado de junto a la puerta y otro por dentro, junto a la puerta.

- **Abierta**: la persiana subida, la puerta de cristal al fondo del portal, luz dentro, los escaparates encendidos, el maniquí fuera y la flecha verde.
- **Cerrada**: la persiana blanca bajada delante del portal y los escaparates en penumbra. El maniquí se recoge. Así estaba cuando pasó el coche de Street View en 2024.

## Qué hay

**Fachada** (Street View de noviembre de 2024; la puerta y los escaparates, también de 2019 y 2021). Bloque de pisos en esquina: planta baja y tres plantas de ladrillo naranja, en vuelo sobre las dos aceras, y tejado bajo a cuatro aguas.

- **La planta baja** es de enfoscado blanco sobre un zócalo de azulejo turquesa.
  - **A la calle Argentina**, desde la esquina: un machón con un cristal esmerilado estrecho y su cartelito («Calzado de señora, caballero y niño / Bodas, comuniones y diario»); el primer escaparate, de baldas blancas llenas de zapatos, con el rótulo encima; el segundo, de cubos blancos con un par o una caja de zapatos en cada uno; los dos con su toldo crema. Después, el cristal esmerilado turquesa con el nombre y el horario pegado, y el portal de la tienda, metido casi un metro, con suelo de baldosa blanca, la puerta de cristal al fondo y una marquesina de cristal ahumado con hiedra colgando. Pasada la tienda, el cuarto de los pisos en enfoscado beis (con su mancha de cemento gris al pie), una ventana tras una reja blanca abombada con la persiana de madera bajada, el contador y dos aparatos de aire acondicionado.
  - **A los Arcos**, desde la esquina: un escaparate de zapatos en escalones blancos con una balda alta de cristal en la punta, su toldo y el friso azul esmerilado con el nombre encima. Después, el portal de los pisos en granito negro, con tres escalones y una puerta de madera tallada de dos hojas, y una tienda de electrodomésticos cerrada y en venta, en granito negro: letrero sin marca («Electrodomésticos»), toldo crema con franja verde, puerta tras una reja de tijera, escaparates con malla detrás del cristal y un cartel de «se vende» (sin teléfono).
- **Las plantas de arriba** son de ladrillo liso con ventanas de aluminio blanco, persianas blancas a medio bajar y visillo detrás del cristal, alféizar de ladrillo y una hilada a sardinel en cada planta. A la calle Argentina, cuatro ventanas por planta; a los Arcos, una ventana en cada punta y entre ellas una columna de terrazas con barandilla de hierro rojo oscuro: la primera medio cerrada con aluminio blanco y su costado pintado de naranja, con macetas; la segunda abierta; la tercera con un toldo verde. Aparatos de aire, una antena parabólica, la placa de «Calle Argentina» en la esquina y los cables por el canto del vuelo.

**Escaparates sin maniquíes.** En Street View de 2021 el escaparate de los Arcos solo tiene zapatos; en 2024 hay maniquíes. Como Luis pidió «solo con zapatos», no he puesto maniquíes detrás del cristal: el único es el de la puerta.

**Interior** (aprobado así: «Así está bien el interior»). Las fotos de dentro de Google Maps solo se ven con la sesión iniciada, así que es una zapatería de pueblo sacada de lo que enseñan sus escaparates, y solo con zapatos:

- una sala de 6,8 × 9 m, paredes blancas, suelo de baldosa grande clara y focos redondos en el techo;
- la puerta a la derecha del frente al entrar; a su izquierda, el cristal esmerilado y el escaparate, y en la pared de la izquierda la ventana a los Arcos, los dos con un escalón blanco de zapatos detrás del cristal;
- a la derecha, de la puerta al fondo, una pared de baldas blancas llenas de pares (botas, botines y deportivas en la de abajo); a la izquierda, pasada la ventana, otra;
- en medio, una mesa redonda de zapatos con una bota en lo alto, un banco tapizado para probárselos con el taburete inclinado de la zapatería y un espejo bajo en el suelo;
- al fondo a la izquierda, el mostrador blanco con frente turquesa, la caja, el datáfono, un calzador y una caja a medio envolver, delante de una pared de cajas de zapatos hasta el techo; al fondo a la derecha, «Pisacastaña» sobre la pared turquesa y un escalón bajo de botas;
- nadie modelado (las figuras las decide Luis).

**Azafrán escondido** («Azafrán en caja de zapatos»): en una caja de zapatos negra, abierta, con papel de seda, en el suelo junto al banco; la tapa, de canto, apoyada en su frente. En `G.flowers` con `"id": "pisacastana"` y `"hidden": true`.
