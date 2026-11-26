# Referencia: el Ahorramás de la Calle de las Viñas («MasAhorro»)

Pedido por Luis el 17-11-2026, al aprobar el IES Valdeacero: «Intenta empezar por el Ahorramás ahora (que llamaremos
MasAhorro) intenta fijarte más en los detalles como en la entrada ahora». Al darle el horario: «Visto bueno entonces».
Y luego: «Spawnean al menos 4 o 5 coches en el aparcamiento mientras abierto? Estaría bien».

El modelo es `godot/scripts/masahorro.gd` (sobre `obra.gd`), en `world.masahorro`. Herramientas: `tools/masahorro/`.
Dibujos (todos nuestros): `godot/assets/masahorro/`, hechos con `tools/masahorro/dibujos.py`.

## Dónde
La nave de la esquina de la Calle de la Noria con la de las Viñas (Catastro 4286902VJ5648N: comercial, de 1999, 1680 m²,
una planta). Su frente da al norte, al aparcamiento, que llega hasta la Calle de las Viñas; el largo da a la Noria; detrás,
el callejón del sur.

## Fuentes
- **Street View**, noviembre de 2024 (`tools/masahorro/capturas.py`; 45 vistas): desde la Noria, desde la Calle de las Viñas
  por encima del aparcamiento (de frente, con zoom) y desde el callejón del sur. Las fotos son de Google: no se guardan.
- **Ortofoto** del PNOA (`tools/ign/masahorro.{jpg,json}`), girada al marco de la nave con rejilla de 1 m
  (`tools/masahorro/marco.py`) y con las calles del juego encima (`plano.py`): las filas de plazas, la isleta de los carros,
  las plazas verdes de los cargadores, las placas del tejado, el cuarto de máquinas y la marquesina de carga.
- **Catastro** (`tools/casas/4286902VJ5648N/`): la planta y la foto antigua de la fachada (de baldosa beige, antes de los
  paneles amarillos).

## Medidas
- **Dónde está la nave**: el Catastro la pone 1,5 m más lejos de la Noria y 1 m más al sur de lo que está. La acera de la
  Noria medida en Street View (el ángulo al pie de la pared desde tres cámaras, `*_suelo`) y la ortofoto coinciden. Origen
  del marco: la esquina noreste en (55,3, 517,0).
- **El frente** (`tools/masahorro/frente.py`): rumbos desde dos cámaras de la Calle de las Viñas, casi de frente, con zoom.
  Frente de 29,5 m y 6,9 m de alto. Marquesina de 8,1 a 29,1 m desde la esquina de la Noria, de 3,1 a 3,85 m de alto, que
  sale 3 m. Pilar crema de 8,1 a 9,4 m, cristal de 9,4 a 24,1 m (9 tramos, dos puertas automáticas), pared crema hasta 29,1 m
  y pilar amarillo al final. Rótulo de 9,1 a 19,7 m. Las cámaras de la Noria, de lado, no sirven para esto: un metro de error
  en su sitio da diez a lo largo del frente.
- **Largo**: 54 m hasta la pared del sur. Desde el callejón se ve la puerta de carga a unos 10 m de la cámara, y se
  comprueba con su tamaño (3,7 × 3,2 m). Detrás salen el cuarto de máquinas (11 m, en la punta oeste) y la marquesina de
  carga (10 m).
- **El aparcamiento**, en el marco: la fila de las casas (4,5 m; el murete gira de x = 32,3 a 30,2 en z = 40), el pasillo
  de entrada, la doble fila central con la isleta de los carros (x 13,6–18,1, z 43–52), el pasillo de salida y la fila de la
  Noria. Plazas de 2,45 m.

## Lo que hay
- **El frente**: paneles amarillos en rejilla (2,95 × 0,97 m, juntas oscuras), que doblan 3,6 m por la Noria y sobresalen
  0,25 m; el nombre en letras en relieve con su sombra (nuestro: «Mas» en verde, «Ahorro» en rojo, un trazo rojo debajo,
  que se ilumina al anochecer mientras está abierto); un foco en cada esquina de arriba, la caja negra y las pegatinas junto
  a la esquina.
- **La entrada**: la marquesina crema con su borde claro y sus luces, el pilar crema, el cristal con montantes oscuros y el
  dintel oscuro, las dos puertas automáticas (la de entrar y la de salir), carteles de ofertas, la pared crema con su
  papelera y su cenicero.
- **Dentro** (se ve por el cristal): cuatro cajas con cinta y pantalla, cinco estanterías con productos, la fruta, luces en
  el techo y la franja verde del fondo.
- **Su horario** (Luis, 17-11: de lunes a sábado de 9:00 a 21:30, el domingo cerrado; es lo mismo que dice la placa del
  aparcamiento). Abierto: las luces de dentro, las de la marquesina y las pantallas de las cajas encendidas, y al anochecer
  el rótulo iluminado en sus colores. Cerrado: todo a oscuras y el rótulo apagado.
- **El paseo** elevado delante del frente, con bordillo, bolardos negros con banda clara, el aparcabicis, una papelera, y
  escalones y barandilla al final, en la esquina.
- **El lado de la Noria**: chapa gris con paneles más claros sobre una banda negra y su pie de hormigón, la puerta de
  servicio (negra, marco blanco, caja de persiana), rejillas y focos.
- **Detrás**: chapa vieja, amarilla sobre blanca; la puerta de carga gris con su tirador rojo, una puerta, una rejilla, el
  banco y el cenicero, bajo la marquesina de acero oscuro con postes y tirante, sobre su solera; bolardos amarillos y un
  poste blanco. El cuarto de máquinas: chapa blanca, barandilla de listones ocre, los extractores redondos y los conductos
  plateados.
- **El tejado**: las placas solares en filas (tres campos, de la ortofoto), tres máquinas de aire, la cúpula blanca, un
  conducto, lucernarios.
- **El aparcamiento**: asfalto, plazas pintadas (las azules de minusválidos delante de las puertas, las verdes de los dos
  cargadores), el paso de cebra a las puertas, flechas, el bordillo de baldosa de la Noria, el murete gris pizarra de las
  casas con las cabezas de las plazas pintadas; la marquesina de los carros con sus carros amarillos, nuestro nombre en el
  lateral, una papelera y un poste amarillo; cinco báculos con dos focos (del pueblo: se encienden de noche).
- **La entrada desde la Viñas**: vallas negras de aspas, la P azul de clientes, las señales (20 y prohibido peatones), la
  placa con el horario del aparcamiento y el contenedor verde de ropa usada (sin marca).
- La puerta gris del pasillo, entre la nave y las casas.
- **Los coches de los clientes**: mientras está abierto, 5 aparcados, y 7 de 12:00 a 14:30 y de 18:00 a 21:00. Van de
  morro en la fila de las casas y en la doble fila central, que dan a los pasillos; en la fila de la Noria no, porque el
  carril de salida les pasa por la cola. Casi todos cerca de las puertas, y en las plazas verdes solo eléctricos. Aparecen
  y se van donde no miras; cerrado, ninguno. Uno que te lleves o que saquen de su plaza ya no es de la tienda.

## Lo que es inventado o aproximado
- El lado oeste no se ve desde ninguna calle: chapa como la de detrás.
- El fondo de la marquesina de carga lo marca el callejón del juego, que va unos 2,5 m más al norte que el de verdad; en la
  realidad la marquesina es más honda.
- Dentro: hecho a juego con lo poco que se ve por el cristal.
- Los carros, los contenedores y las señales, de Street View y sin marcas.

## Trampas
- Una pieza recortada a «lo que queda» puede quedarse sin tamaño: los productos de las baldas se recortan al final de la balda y el último podía salir con fondo casi cero. Desde el 26/11/2026 no se pone si mide menos de 2 cm.

## Pruebas
`python tools/run_tests.py masahorro`: fotos y comprobaciones (está hecho; sus paredes paran y el mapa la conoce, nada pisa
una calzada; da a la Calle de la Noria; el paseo se pisa; sus horas y sus luces; los focos son del pueblo).
