# «MaxiPrecio»

Luis, 23/11/2026, con una captura de Google Maps: «Vamos con el HiperTextil Miniprecio (que llamaremos MaxiPrecio). Necesitará tener un interior (hay fotos en maps) y su horario comercial».

Es la tienda de ropa y textil de casa de la calle de los Arcos, en la esquina con la calle del Molino (al norte) y la calle de Granada (al sur). **En el juego se llama «MaxiPrecio»**. Los rótulos y los murales conservan «Hiper Textil» y dicen «Maxi Precio» donde la tienda real dice «Mini Precio».

**El logo.** El de la tienda real son dos cerezas. Luis, el mismo día, con una imagen de referencia: «Como el logo original son dos cerezas que el nuestro sean dos melocotones». Son dos melocotones juntos, el derecho delante, en degradado de rojo a naranja amarillento, con su hendidura, un rabito con dos hojas, un borde blanco y «Maxi» y «Precio» en blanco con su raya debajo. La referencia traía «Síguenos en Facebook»: no se pone, porque en el juego no hay redes sociales.

## Reparto del trabajo

- **Edificios Especiales (Pretil)**: la fachada, el horario y el interior.
- **Sistemas**: Maxi, el dependiente (`maxi.gd`), con sus frases llenas de «maxi» y el probador donde se compra ropa a 20 € para el armario. Lee del interior `open`, `clerk_spot`, `clerk_h`, `probador_spot` y `probador_h`.

## Dónde está

- Catastro 3692101VJ5639S: el edificio de la tienda y, a lo largo del Molino, la parte 3, que es otra casa. Es la casa `mol_b301` de Texturas, cedida en `casas_calles.gd` con `"mol_b301": ["obra"]`. Sin rehorneado.
- El contorno, en el orden del anillo: SO (119.37, 247.09), NO (121.25, 228.48), NE (154.98, 236.09), E1 (153.39, 239.69), E2 (141.04, 237.18), SE (138.56, 250.95). En el Molino, la tienda acaba en MS (141.83, 233.12), a 21,1 m de la esquina, y de ahí a NE es la parte 3.
- Al este de E2–SE el mapa está vacío: en la realidad sigue el bloque de pisos (su portal está al final de la calle Granada). Las paredes que dan ahí son medianeras lisas.

## Scripts

- `godot/scripts/maxiprecio.gd` (`world.maxiprecio`, paso «the shop MaxiPrecio»): la fachada, sobre `esquina.gd`. Expone `door` (en la acera, delante de los escalones), `side_spot` (ante el mural de Granada), `molino_spot` (ante el del Molino), `open_at(day, hour)`, `set_open(on)`, `is_open` y `dentro`.
- `godot/scripts/maxiprecio_dentro.gd` (`world.maxiprecio.dentro`): el interior, un decorado aparte en (2150, −600) al que se entra por la flecha verde de delante de los escalones (`entradas.gd`). Es el único sitio del mapa con más de 300 m hasta cualquier calle, sin árboles a menos de 500 m, sin campos de cultivo y a más de 780 m de otro decorado (el más cercano es el del silo). Se buscó con un script de una sola vez que no está en el repositorio.
- Dibujos: `tools/maxiprecio/dibujos.py` genera en `godot/assets/maxiprecio/` el rótulo de la V, el azulejo de las rayas, el mural y el cartel del horario. Después de cambiarlos hay que importar: `Godot --headless --path godot --import`. Hoja con los cuatro: `guion/fotos/maxiprecio/dibujos.jpg`.
- Prueba: `python tools/run_tests.py maxiprecio --timeout 600`. Saca las vistas de Street View (las mismas cámaras) abierta, cerrada, al atardecer y de noche, más cinco vistas del interior, y pasa `_maxiprecio_checks()`, que va también en la prueba completa.

## Horario

Es el de la tienda real según Google Maps (23/11/2026): de lunes a viernes de 9:30 a 14:00 y de 17:00 a 21:00, los sábados de 9:30 a 14:00 y los domingos cerrada. Hay un cartel con el horario en el cristal del porche y otro por dentro, junto a la puerta.

- **Abierta**: los toldos bajados, la puerta abierta hacia dentro, luz dentro y la flecha verde.
- **Cerrada**: los toldos recogidos en sus cajones, la puerta cerrada y el interior a oscuras.

## Qué hay

**Fachada** (Street View de noviembre de 2024). Bloque de pisos de ladrillo salmón: planta baja, dos plantas y azotea.

- **A los Arcos (oeste, 18,7 m).** En cada extremo, una ventana de la tienda tras un toldo vertical de rayas azules y blancas, con pilastras de ladrillo y zócalo de granito con rejillas. En medio, el frente de la tienda sale en V bajo dos rótulos.
  - Bajo los rótulos, dos toldos también en V, unidos en inglete.
  - En la punta de la V, un pilar redondo crema con pintadas (lo sucio se queda sucio), un poste azul y tres escalones de granito que suben al porche.
  - El porche tiene los lados de cristal sobre azulejo blanco y azul, y la puerta de cristal al fondo.
  - Por encima de la planta baja corre una franja crema.
- **Arriba, en los Arcos.** Dos alas con balcones corridos en las dos plantas: losas de borde crema, barandillas de un gris claro y, encima, el alero hondo de la azotea. Los balcones doblan las esquinas hacia el Molino y hacia Granada (2,6 m).
  - Entre las alas, un mirador curvo de ladrillo: dos ventanas por planta con barandillitas, bandas crema en cada forjado, una barandilla arriba y una pérgola de hierro.
  - A cada lado del mirador, una franja de enfoscado blanco.
- **A Granada y al Molino.** La planta baja de la tienda es blanca, pintada con rayas azules inclinadas y el mural («Hiper Textil» y los melocotones), con aparatos de aire acondicionado y los cables. Arriba, ladrillo con ventanas de marco crema, persianas a medio bajar y barandillitas.
  - En Granada, junto a la esquina, una franja oscura de lamas (la escalera). Al final, el portal de los pisos, chapado de granito, con su puerta de cristal tras unas cancelas grises.
- **Parte 3 (el resto del Molino).** El pie es de ladrillo tosco sin enfoscar, con manchas de mortero y agujeros a lo largo de su parte alta. Encima, una banda gris y el ladrillo de las plantas, con un balcón blanco en su extremo este.

**Interior (PRIMER BORRADOR).** Las fotos de dentro de Google Maps solo se ven con la sesión iniciada; se le han pedido capturas a Luis. Mientras, es un hipertextil de pueblo genérico:

- una sala de 9 × 12 m, paredes blancas con las rayas de la tienda por arriba, suelo de terrazo claro y filas de fluorescentes;
- estanterías altas a los dos lados con pilas dobladas (toallas, sábanas, mantas);
- colchas colgadas en el fondo, a los lados del logo;
- en medio, burras de ropa, un perchero redondo, dos mesas de pilas y una isla de cestas;
- el mostrador con la caja a la derecha al entrar;
- dos probadores con cortina azul al fondo a la izquierda;
- carteles colgados: TOALLAS, ROPA DE CAMA, MODA, PROBADORES y CAJA.

Dentro no hay maniquíes ni figuras. El único maniquí es el de la puerta, que pidió Luis.

## El maniquí de la puerta

Luis, el mismo día: «Ponle un maniquí con ropa y sombrero en la puerta (puede ser un modelo de NPC blanco y la ropa con color), que sea rompible y que cambie cada día aleatoriamente».

- `godot/scripts/maniqui.gd` (`world.maxiprecio.maniqui`), que vale para cualquier tienda. Es una figura del juego (`chara.gd`) con la piel de plástico blanco, sin pelo, sin ojos y sin coloretes, sobre una peana oscura.
- Está en la acera, a la derecha de los escalones según se mira la tienda, delante del cristal de la V (`MANIQUI` = 11,0 por los Arcos desde la esquina del Molino y 0,95 hacia fuera). Mira a la calle, un poco girado hacia el Molino. Solo está fuera mientras la tienda está abierta (Luis: «Solo mientras la tienda está abierta»). Al cerrar, `set_open` lo guarda con `maniqui.set_out(false)`: no se ve, no choca, y ni un golpe ni un coche lo alcanzan, porque su `rad` para `props.gd` queda fuera de alcance. Al abrir sale con la ropa del día. Si lo tiran, se queda en el suelo como lo demás hasta que `props.gd` lo arregla; si lo arregla con la tienda cerrada, lo guarda en su siguiente vuelta.
- **Cada día, otra ropa**: camiseta, colores, sombrero, calzado y a veces corbata, pañuelo o gafas de sol, todo sacado de lo que ofrece el creador. Se sortea con el día como semilla, así que el mismo día viste siempre igual. Se cambia cuando nadie lo mira.
- **Rompible**: es mobiliario de la calle (`props.adopt()`, tipo `"maniqui"`). Un puñetazo o un coche lo tiran, a los 40 s lo retiran y al día siguiente vuelve (`props.mend()`), como lo demás.
- Hoja: `guion/fotos/maxiprecio/maxiprecio_05_maniqui.jpg` (seis días). Dentro de la tienda no hay figuras.

## Medidas y lo aproximado

- **Alturas**, sobre la acera ante los escalones: suelo de la tienda 0,45; ventanas de 0,62 a 3,45; fin de la planta baja 4,45; primera planta 4,6; segunda 7,7; azotea 10,65; pretil 11,4. Son estimadas sobre las fotos: no hay medidas del Catastro.
- **La V**: de x 5,9 a 11,4 desde la esquina del Molino, con la punta en x 8,65 y 0,9 m hacia fuera. El pilar está en (8,65; 0,72).
- **El mirador**: de x 7,2 a 10,1, sale 1,0 m y tiene un radio de 1,55.
- Las alas de los Arcos son x 0–6,0 y 11,2–18,7. Los balcones salen 1,0 m.
- El nivel (`level`) es la altura del terreno ante los escalones. Las calles suben hacia el este: en NE el suelo está 1,4 m más alto. Las paredes bajan hasta −2.

## Trampas

- `_party_wall` de `esquina.gd` es para tejados inclinados. Aquí la azotea es plana: las medianeras se hacen con `_plain` (de `obra.gd`) con los extremos al revés que el anillo, para que miren hacia fuera.
- Las rayas pintadas llevan UV en metros (0,9 × 1,8 por azulejo), no triplanar, para que se inclinen igual en todas las fachadas.
- **El azul se apaga con el brillo.** Una pared blanca al sol pasa del umbral del resplandor (`glow`) del juego, y ese resplandor agrisa las rayas. Por eso los dibujos y la lona no brillan (`metallic_specular` 0), llevan poca emisión (0,05 y 0,06) y el azul del dibujo es hondo, (10, 40, 146). Medido sobre Street View, el azul queda en (68, 80, 176), y el de la foto es (48, 86, 158).
- **El ladrillo**, medido sobre Street View: tinte (1,12; 1,12; 1,42) sobre `brick_wall_003`. Es salmón pálido, no el naranja de la textura.
- Los escalones son un sólido de 1 m de alto. Nadie se sube al porche: la flecha está en la acera, antes de los escalones.

## El azafrán escondido

Luis, 23/11/2026: «Ponlo también». Está en el cubo del fondo de la isla del centro, el de la izquierda según se entra, de pie entre los paquetes de calcetines (`maxiprecio_dentro.gd` `_saffron`, `saffron_spot`, `"id": "maxiprecio"`). Cuenta una sola vez por partida, como todos los escondidos.

## Pendiente

- **Aprobado** por Luis el 23/11/2026: «Visto bueno también».
- Las fotos del interior, si Luis las manda, para rehacer el borrador.
