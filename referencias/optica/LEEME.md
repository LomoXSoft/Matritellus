# «Óptica Corsa»

Luis, 23/11/2026, con una captura de Street View (C. Salvador 5, marzo de 2013): «Vamos con el centro óptico cors (que llamaremos Óptica Corsa, en C. Salvador, 5 … Igual que Tutoq, icono de complementos, no, mejor, icono de gafas, y dividimos las tiendas entre complementos y gafas, gafas en las ópticas y complementos en las tiendas de complementos. aquí el NPC será una Óptica con bata blanca y solo venderá gafas. Y te dirá cosas sobre graduarte la vista, parece que tienes estrabismo, tengo modelos nuevos y vintage y tal. Se llamará Fátima Corsa.»

**Aprobada** por Luis el mismo día: «Visto bueno, y c».

Es la óptica de la calle del Salvador (la real se llama Centro Óptico Corts). **En el juego se llama «Óptica Corsa».** «Igual que Tutoq» quiere decir: fachada hecha a mano desde Street View con rótulo propio, horario con estado abierta y cerrada, e interior aparte con flecha verde. No lleva maniquí: en una óptica no es lo normal. Si Luis lo quiere, se pone.

**El rótulo.** El real es una banda verde azulada con «CENTRO OPTICO CORTS» en blanco. El nuestro está dibujado de nuevo: la misma banda verde con «ÓPTICA CORSA» en blanco entre dos gafas redondas, dibujadas por nosotros. A la izquierda, en su brazo negro, salen unas gafas en relieve: dos aros gruesos de cara verde sobre canto azul marino (en la real, dos aros verdes). Sin número, sin teléfono y sin redes.

## Reparto del trabajo

- **Edificios Especiales (Pretil)**: la fachada, el horario, el interior, los dibujos y las pruebas.
- **Sistemas**:
  - Fátima Corsa, con bata blanca (`fatima.gd`): está detrás del mostrador mientras la óptica abre; le hablas y te lleva al espejo.
  - El tipo «gafas» en `tiendas_ropa.gd`: la óptica sale en el mapa con el icono de unas gafas y está cerrada para ti hasta el Vizum de Josefa.
  - Las gafas se venden a 20 € (Luis: «De momento todo a 20€ hasta que decida precios»).
- **La separación** («gafas en las ópticas y complementos en las tiendas de complementos»):
  - las gafas solo se venden en las ópticas;
  - los maniquíes de la Tetoqa ya no llevan gafas (`maniqui.gd`);
  - la torre de gafas de sol del interior de la Tetoqa es ahora de coleteros y pinzas (`tetoqa_dentro.gd`).

## Dónde está

- Es la casa `salvador_5` de Texturas, cedida en `casas_calles.gd` con `"salvador_5": ["obra"]`. Sin rehorneado.
- La fachada es el lado RING[11] (−103.66, −3.21), su extremo oeste, → RING[10] (−95.47, −4.2), su extremo este. Mide 8,25 m y da al sur, a la calle del Salvador.
- La casa tiene 29 m de fondo hasta la trasera.
- El solar de al lado por el oeste (x −123 a −104) estaba vacío en el mapa. Texturas lo rellenó el mismo día con `salvador_3`, una casa vieja de dos plantas, alineada con `salvador_1` y con la óptica.

## Scripts

- `godot/scripts/optica.gd` (`world.optica`, paso «the optician Óptica Corsa»): la fachada, sobre `esquina.gd`.
  - Las dos plantas de arriba vuelan 0,55 m sobre la acera. Tejado de teja vieja: una vertiente a la calle y otra larga y suave (un cuarto de pendiente) hacia la trasera.
  - Expone `door` (en la acera, delante de la puerta), `front_spot`, `open_at(day, hour)`, `set_open(on)`, `is_open` y `dentro`.
- `godot/scripts/optica_dentro.gd` (`world.optica.dentro`): el interior. Es un decorado aparte en (2150, 650) al que se entra por la flecha verde de delante de la puerta (`entradas.gd`).
  - Está a 246 m de cualquier calle y a más de 150 m de cualquier otro decorado.
  - Expone `clerk_spot`/`clerk_h` (detrás del mostrador), `client_spot`/`client_h`, `probador_spot`/`probador_h` (ante el espejo largo) y `chair_spot`/`chair_h` (el sillón de graduar, por si algún día sirve).
- Dibujos: `tools/optica/dibujos.py` genera en `godot/assets/optica/`:
  - de la fachada: el rótulo, el cartel del horario, la placa granate de la óptica («Fátima Corsa, óptica-optometrista»), los tres carteles del cristal (REVISIÓN DE LA VISTA, GAFAS DE SOL Novedades, VINTAGE) y el fondo de hexágonos del escaparate;
  - del interior: el optotipo (su última fila dice MADRIDEJOS, desde el 24/11/2026), el nombre de la pared y los letreros «Novedades» y «Vintage».
  - Después de cambiarlos hay que importar: `Godot --headless --path godot --import`.
- Prueba: `python tools/run_tests.py optica --timeout 600`.
  - Saca las vistas desde las cámaras de Street View que dan a la fachada (la de delante y la del oeste): abierta, cerrada, al atardecer y de noche.
  - Saca tres de cerca (la entrada, las gafas del brazo y el escaparate) y nueve del interior.
  - Pasa `_optica_checks()`, que va también en la prueba completa.
  - Las cámaras de Street View que están más al este no sirven: las casas de la esquina del juego las tapan.

## Horario

**El real** (Google Maps, 23/11/2026): de lunes a viernes de 10:00 a 14:00 y de 18:00 a 21:00, los sábados de 10:00 a 14:00 y los domingos cerrada. El cartel del horario va pegado en el cristal de la puerta y hay otro por dentro, junto a la puerta.

- **Abierta**: la entrada despejada, luz dentro y la flecha verde.
- **Cerrada**: una persiana gris bajada sobre la entrada y el escaparate en penumbra.

## Qué hay

La fachada, de abajo arriba:
- la planta baja, de granito gris claro hasta el portal de los pisos:
  - las gafas del brazo en el extremo oeste;
  - la persiana blanca de un garaje;
  - el escaparate: gafas en escalones blancos y en una balda de cristal, delante del fondo de hexágonos, con los tres carteles en el cristal;
  - la entrada, metida medio metro detrás de un escalón de granito: la puerta de cristal en aluminio oscuro y una vitrina pequeña de gafas sobre pie de granito, con su rejilla negra;
  - encima, todo a lo largo, la banda del rótulo;
- luego ladrillo:
  - la placa granate de la óptica;
  - la caja redonda de la alarma;
  - el portal de los pisos, de madera y dos hojas bajo una reja de madera, hondo en el ladrillo;
- las dos plantas de arriba, de ladrillo de color beige:
  - el vuelo descansa sobre una moldura honda: lisa abajo, una fila de dientes finos e hiladas que salen hasta los alféizares;
  - dos ventanas anchas por planta con marco marrón, visillos blancos y persianas grises a medias;
  - entre ellas, dos aparatos de aire uno sobre otro y una antena parabólica;
  - una banda de dientes entre las plantas y un panel enmarcado en la segunda;
- la cornisa de ladrillo y los canecillos oscuros del alero.

El interior (primer borrador: Google Maps solo enseña el interior real con sesión iniciada):
- **Al entrar, a la derecha**: el mostrador blanco con frente verde, la caja registradora, el datáfono, una bandeja de gamuzas y un expositor con dos gafas. Detrás, la pared verde con baldas de fundas y botes de limpiagafas, su título enmarcado y la placa.
- **A la izquierda, «Novedades»**: una pared blanca iluminada con siete filas de baldas de cristal y unas gafas en cada sitio.
- **Más al fondo, «Vintage»**: una vitrina de madera oscura con bandejas de paño verde, monturas redondas de carey, oro y asta, y una lamparita de latón.
- **En medio**: una torre giratoria de gafas de sol y una vitrina baja de cristal.
- **A la derecha, pasado el mostrador**: el espejo largo (donde te pruebas las gafas) y una mesita redonda con espejo de pie, una bandeja de monturas y un taburete.
- **Al fondo**, tras un tabique con el nombre «Óptica Corsa» y un hueco de puerta, el gabinete:
  - el sillón negro, mirando al optotipo iluminado de la pared;
  - la columna con su brazo y el foróptero delante de la cabeza;
  - el taburete de ella;
  - la mesa con la caja de lentes de prueba abierta, el autorrefractómetro y una pantalla.

## Azafrán escondido

De las tres propuestas (la caja de lentes de prueba, una funda en la vitrina «Vintage» o detrás del optotipo), Luis eligió la tercera: «Visto bueno, y c».

- La caja del optotipo está separada de la pared 20 cm, sobre dos soportes grises, con su cable bajando a un enchufe.
- La flor, pequeña, está de pie en el soporte de abajo, en la rendija. Asoma un poco de morado por el lado de la caja, hacia la mesa del fondo.
- `_saffron` en `optica_dentro.gd`, `id` "optica", `"hidden": true`. Cuenta una vez por partida, como los demás escondidos.
- Luis dio el visto bueno al escondite con la captura delante: «Visto bueno».
- Se llega a ella desde el gabinete: la prueba se acerca a 0,31 m. Captura: `guion/fotos/optica/optica_04_azafran.jpg`, junto con la casa nueva de Texturas al oeste.

## Lecciones

- **Dibujos con brillo propio**: hay que poner `emission_operator = EMISSION_OP_MULTIPLY`, como en `obra._glow`.
  - Con el operador por defecto (sumar), `emission = WHITE` con `emission_texture` echa encima un velo gris de toda la energía. El verde del rótulo salía color salvia, igual de día que de noche.
  - Otros sitios míos tienen el mismo velo (rótulos, carteles y letreros de dentro). Casi no se nota porque casi todos son claros. Se puede corregir si Luis quiere.
- **La cámara del juego corta lo que tiene a menos de 0,3 m** (`cam.near`). Una vista pegada a un tabique «ve a través» de él. Las cámaras de prueba deben ir a medio metro de las paredes.
