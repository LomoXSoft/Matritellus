# Referencia: el Merkocarry (el Merkocash de la calle de Santa Ana)

Pedido por Luis el 17-11-2026, con una foto de satélite con el contorno en rojo: «Merkocash madridejos (Que llamaremos
Merkocarry). Este tiene miga porque ocupa varias fachadas de las calles Santa Ana, Cristo, Suspiro y Magallanes, pero sin
ocupar toda la manzana. Utilizar street view en las cuatro calles enfocando al merkocash». Veredicto (17-11, con el
interior, los pósters y la nave de la Mayordomía): «Visto bueno, está bastante bien».

El modelo es `godot/scripts/merkocarry.gd` (sobre `obra.gd`), en `world.merkocarry`, en el marco del propio mapa (x este,
z sur; y = 0 el suelo de la tienda, la acera de Santa Ana ante su puerta). Herramientas: `tools/merkocarry/`. Dibujos, todos
nuestros: `godot/assets/merkocarry/`, hechos con `tools/merkocarry/dibujos.py`.

## Fuentes
- **Street View** de noviembre de 2024 por las cuatro calles (`tools/merkocarry/capturas.py`; las fotos son de Google y no
  se guardan aquí). `tools/merkocarry/alzado.py` endereza una foto sobre el plano de una fachada con una cuadrícula en
  metros (con la cámara corrida a lo largo y hacia el frente hasta que los extremos caen donde dice el Catastro).
- **Catastro**: la parcela 4790703VJ5649S (comercio de 2001, nueve partes de una y dos plantas). `tools/merkocarry/manzana.py`
  lista y dibuja toda la manzana 47907.
- **Ortofoto** (PNOA): `tools/ign/merkocarry.jpg`; `tools/merkocarry/plano.py` la pone con la cuadrícula del mapa, el
  contorno del Catastro y las calles del juego. De ella salen el aparcamiento, los porches y el pasillo.
- **Google Maps**: el horario (de lunes a sábado de 9:30 a 21:00, domingo cerrado), el mismo del cartel del escaparate.
  No hay fotos 360 dentro del aparcamiento ni de la tienda.

## Lo que ocupa
- La tienda, sobre el contorno del Catastro salvo dos cosas: su esquina del Cristo junto a la Mayordomía se recorta un metro
  (la calle del juego pasa más cerca que la real) y el extremo sur de su parte del Cristo es el pasillo descubierto que
  entra al aparcamiento (en la ortofoto es suelo, y la puerta se ve desde el Cristo).
- Su fachada de Santa Ana era la casa `stana_60d` de Texturas; ahora es `["obra"]` y el horneado la quita al saltar la RC.
- El aparcamiento hasta Magallanes, entre los patios de las casas del Cristo y la calle del Suspiro, con los porches para
  coches a lo largo del muro oeste, de Magallanes y doblando el chaflán hacia el Suspiro.
- **No es suyo**: la nave crema de la calle del Cristo pegada a la tienda (4790711, de 2020), con la placa «Mayordomía Stmo.
  Cristo del Prado». Queda como la deja el horneado. (Pregunta abierta a Luis.)

## Medidas
- Santa Ana (16,19 m, del este al oeste): azul hasta 3,5 m, blanco, el rótulo de 4,6 a 7,1 m, banda azul hasta 7,85 m y la
  barandilla de la azotea. Escaparates de 1,25 a 4,86 m y de 5,92 a 9,82 m (de 1,4 a 3,42 m de alto); el contador de 10,57
  a 11,41 m; la puerta de cristal de 11,67 a 15,44 m, hasta 3,17 m; pilar azul hasta el final.
- El Cristo: el muro de la nave mide 22,3 m desde la esquina (zócalo de piedra 0,8 m, banda azul, blanco, chapa azul
  arriba hasta 4,6 m sobre la calle, barandilla), con el tejadillo azul sobre la puerta de servicio de la esquina, la puerta
  doble a 15,6 m y otra a 20,6 m. La entrada del parking de 22,4 a 29,5 m, el pilar azul de la P de 29,5 a 30,3 m; luego la
  pastelería.
- El Suspiro: el muro largo (45,3 m), azul hasta 2,4 m, blanco hasta 4,4 m, chapa azul hasta 5,6 m sobre el suelo de la
  tienda, y la barandilla. La puerta de lamas azul a 5,3 m de la esquina sur, en su cerco de piedra rosa. La puerta de
  clientes, pegada a esa esquina, y luego el muro bajo del aparcamiento (1,3 m), que sube hasta 2,4 m hacia la esquina de
  Magallanes, con la valla de malla encima.
- Magallanes: el muro del aparcamiento de 2,4 m sobre la calle y la valla; el chaflán de la esquina igual.
- Los porches: 5,6 m de fondo, chapa gris a 2,95 m junto al muro y 2,55 m en el borde, postes azules.

## Nombres y dibujos (nuestros)
- «MERKOCARRY» con los colores de su fachada: MER en rojo, KO en blanco sobre cuadro rojo, CARRY en verde ribeteado de blanco
  sobre rojo. La franja verde dice «EL SÚPER DE LA FAMILIA · PARA TODOS LOS PÚBLICOS». Debajo, una fila de insignias sin
  marca ni letras, donde la real lleva las de sus proveedores.
- Carteles: «PRECIOS IVA INCLUIDO» con una cesta de fruta, y un carro con la placa del horario. «ENTRADA PARKING» con las P,
  «ENTRADA CLIENTES», la P con flecha del pilar. Ninguno con caras.

## Horario y lo que cambia
De lunes a sábado de 9:30 a 21:00; el domingo, cerrado. Abierto: las cancelas del Cristo y de clientes abiertas, la tienda
iluminada tras el cristal, luces en los porches, y coches de clientes en las plazas (6; 9 a mediodía y por la tarde), como
en el MasAhorro. Cerrado: las cancelas cruzadas (y sólidas), todo a oscuras, el aparcamiento vacío. El rótulo se ilumina al
anochecer mientras está abierto.

## Pósters de Roster e interior (Luis, 17-11: «Tiene muy buena pinta. Pega un póster de Roster Energy cerca de cada entrada y luego les haces un interior al que se puede acceder por las dos entradas»)
- El póster de Roster (el de los chinos, `assets/chinos/poster_roster.png`), un poco torcido, junto a cada entrada: en
  Santa Ana entre el contador y la puerta de cristal, al lado de la puerta trasera (en el blanco), en el pilar azul de la P
  de la entrada del parking y en la esquina de la tienda junto a la puerta de clientes.
- El interior es `godot/scripts/merkocarry_dentro.gd`, un set aparte en (1100, 1850), a 364 m de cualquier calle: 14 x 24 m,
  4,2 m de alto. Se entra por la flecha verde de la puerta de Santa Ana (llegas delante, junto a las cajas) o por la de la
  puerta del aparcamiento (llegas al fondo, junto a la carnicería); dentro, las dos salidas valen, por la que quieras
  (`entradas.gd`: las dos puertas son un mismo set, `set_id`). Solo se entra mientras está abierto.
- Dentro: tres cajas, la fruta, cuatro filas de estanterías altas (azules y naranjas) con cajas de stock arriba y ofertas
  en los extremos, palés de agua y aceite, congelados y lácteos por la pared izquierda, bebidas por la derecha, la
  carnicería al fondo (sin nadie: no hago personajes nuevos), carros en las dos puertas, el nombre sobre ambas.

## La nave de la Mayordomía (Luis, 17-11: «La nave de la mayordomia es otro edificio distinto. Pero puedes ponerte con él ahora»)
- `godot/scripts/mayordomia.gd`, construida desde `merkocarry.gd` cuando el mapa se horneó con ella (`merkocarry.nave`); en el
  horneado, su RC (4790711VJ5649S) se salta con la del Merkocarry (`MERKOCARRY_RCS`).
- Su planta: el cuadrilátero de Catastro con el frente del Cristo un metro más atrás (como la esquina del Merkocarry): de
  (415.47, 169.97) a (411.41, 179.03), 9,93 m, y al fondo contra el Merkocarry.
- Su frente, medido sobre Street View 2024 enderezado (`alzado.py`; la cámara estaba ~1,2 veces más lejos de lo que dice
  Google, como en Santa Ana): zócalo de piedra hasta 0,45 m, revoco crema hasta 3,8 m, chapa beige de costillas anchas
  hasta 6,2 m. Desde la esquina norte: caja de la luz (0,15 m), ventana con reja (2,25 a 3,47 m, de 1,12 a 2,23 m de alto),
  puerta gris estrecha (3,57 a 4,82 m, 2,09 m), la placa encima (3,37 a 5,05 m), el portón de los pasos (5,33 a 8,62 m,
  3,99 m de alto, dos hojas con arco en relieve, cuarterón y piezas de esquina, dintel oscuro), y el pilar con el espejo
  convexo (9,48 m), vuelto hacia la salida del parking.
- La placa dice solo «MAYORDOMÍA» (la real lleva el nombre completo). Luis, 17-11: «Solo mayordomía está bien».

## Pruebas
`python tools/run_tests.py merkocarry`: fotos de las cuatro calles, las puertas, el aparcamiento, de noche y desde el aire,
y comprobaciones: está donde estaba el bloque del Catastro (la casa de Texturas ya no se dibuja); sus frentes y el muro de
Magallanes paran; el mapa la conoce; nada en la calzada; da a las cuatro calles; el horario, las luces, las cancelas y el
pasillo; los coches; el interior aparte, cerrado, con las dos puertas en la lista de entradas y abierto con la tienda;
entrar por Santa Ana y salir por la puerta trasera. Tras el horneado también pasan `relief` y `casas solo=stana_`; tras
tocar `entradas.gd`, `entradas` y `noche`.
Hojas para Luis: `python tools/merkocarry/hojas.py CARPETA_SV` (tras el modo de vistas que indica), en
`guion/fotos/merkocarry/`.
