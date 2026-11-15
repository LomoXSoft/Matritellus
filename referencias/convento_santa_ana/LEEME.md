# Referencia: el convento de Santa Ana (Hermanas Clarisas)

Pedido por Luis el 15-11-2026 (`usuario_01_fachada_2024.jpg`, una captura de Street View de noviembre de 2024):
«Pasemos al convento de santa Ana. La calle está empedrada pero no es peatonal».

El modelo es `godot/scripts/santaana.gd` (sobre `obra.gd`). Herramientas: `tools/santaana/`.

Veredicto de Luis, con el fraile ya puesto (15-11-2026): «Esta increíble. Muy buen trabajo».

## Dónde (¡ojo!)
NO está en la calle Santa Ana. Es el convento de las Clarisas, en la esquina de la **calle de las Monjas** (su fachada,
al este) con la **calle de Santiago Apóstol** (su costado norte); Google lo sitúa en 39,46949, -3,53941, mapa
(-508, -54). Catastro `3792701VJ5639S` (servicios públicos, «1900», 1.349 m²): un cuerpo de dos plantas de 1.005 m², la
iglesia (una planta alta, 258 m², en la esquina noreste) y dos cuerpos bajos en el huerto.

## Marco
Origen en el extremo sur de la fachada del convento, mapa (-501,6, -33,6). `x` a lo largo de la fachada hacia el norte
(u = (0,2425, -0,9701)); `z` sale a la calle de las Monjas (este). `y` = 0 es el suelo del convento, la calle ante su
puerta grande.

## Fuentes
- **Street View**: treinta cámaras en las dos calles (`python tools/molino/panos.py cerca HunZ4RQmngS_4PXutUbrOg -495 -58 75`
  las lista todas con sus pasadas de 2009, 2013, 2021 y 2024). Las vistas usadas, en `tools/santaana/capturas.py`. No hay
  fotos 360 de particulares dentro: es un convento de clausura (se comprobó en tres puntos).
- **Catastro** y **ortofoto**: `python tools/molino/catastro.py -610 -150 -410 50 partes.json`,
  `python tools/plaza/aerea_wmts.py -565 -105 -470 -15 0.1 aerea 20`.

## Lo que hay (de sur a norte por la calle de las Monjas)
- **Fachada del convento** (28,5 m): dos plantas altas de ladrillo claro con cajones de mampostería entre verdugadas
  (aparejo toledano), alero de ladrillo con dientes a unos 8 m. Ocho ejes: abajo, ventanas altas (1,0 a 3,05 m) con
  rejas de forja pintadas de gris con copete; arriba, ventanas (4,95 a 6,6 m) con las mismas rejas. En el tercer eje, una
  puerta pequeña oscura bajo un dintel de ladrillo a sardinel, con un escalón de piedra; en el quinto, la **puerta
  grande** de arco de ladrillo (2,25 m de ancho, 2,85 de alto) con dos hojas de madera vieja y su propio tejaroz de
  ladrillo encima. Entre las dos, una piedra labrada. Tres faroles de hierro en brazo.
- **Torre**: cuadrada, de ladrillo con cajones, detrás de la fachada hacia el sur; huecos de arco bajo la cubierta (dos
  por cara al este y al oeste, uno al norte y al sur), tejado a cuatro aguas.
- **Compás**: la fachada se retranquea unos 3,5 m y forma un patinillo de ladrillo con dos cipreses, un pedestal de
  piedra (con un fraile de bronce) y un cartel informativo granate.
- **Portada de la iglesia**, en el muro retranqueado: arco de medio punto de piedra dorada entre pilastras bajo
  cornisa; encima, hornacina con imagen entre dos escudos, frontoncillo y cruz. Puertas de madera oscura con cuarterones.
- **Cabecera de la iglesia**: cuerpo más alto (unos 10,5 m) de ladrillo con cajones, una ventanita alta con reja,
  sillares de piedra en la esquina con Santiago Apóstol.
- Una **torrecilla-campanario** cuadrada pequeña sobre el tejado, junto a la iglesia.
- **Por Santiago Apóstol** (calle muy estrecha): el testero de ladrillo de la iglesia con una ventana enrejada, y
  después una pared larga enfoscada en crema sobre zócalo granate con ventanas enrejadas altas; luego la tapia del huerto.

## La calle
La calle de las Monjas va **empedrada**: carril central de adoquín gris oscuro y bandas de ladrillo rojizo hasta las
casas, todo a un nivel, y **con tráfico**. Desde su extremo sur (cruce con la calle de Nalda) hasta el cruce con
Santiago Apóstol y la Amargura; más al norte es asfalto. Santiago Apóstol y la Amargura son de asfalto.

## En el juego
- No se entra: es clausura. Sin personajes. Sin rótulos.
- **El fraile de bronce** está en su pedestal. Al enseñarle la primera versión sin él, Luis: «Pon una figura de un
  fraile, que tenga el estilo de nuestros NPCs pero completamente en bronce». Es una figura de las del juego
  (`chara.gd`: tonsura, barba, hábito hasta los pies con capucha y cordón, brazos abiertos) con todas sus piezas en un
  solo bronce (`_friar` en `santaana.gd`). La imagen de la hornacina es un bulto de piedra sin rasgos.
- La calle: `PAVED_STREETS` en `tools/bake_godot.py` (el tramo sigue siendo calle de coches, con `"paved": 3`) y el
  tercer bucle de `godot/scripts/empedrado.gd` (ladrillo de casa a casa y adoquín en el centro, por encima del asfalto).
- Prueba: `python tools/run_tests.py santaana` (13 fotos y 3 comprobaciones).

## Lo que es aproximado
- **El extremo norte**: en el juego la calle de Santiago Apóstol pasa unos 3 m más al sur que la real, por donde de
  verdad está el final de la iglesia. La iglesia y la crujía norte van recortadas hasta la calle del juego (la
  cabecera mide 8,8 m de largo en vez de 9,6; la nave pierde unos 3 m).
- **La fachada** se ha hecho recta; la real hace un quiebro de 0,8 m hacia la calle.
- **Posiciones de los ejes**: medidas sobre vistas frontales con la posición de Google sin corregir, ±0,5 m; el tramo
  entre la puerta pequeña y la grande solo se ve de lado. Alturas, ±0,2 m.
- **La torre y la torrecilla**: situadas a ojo por cruce de dos vistas (±2 m); sus medidas, estimadas.
- **La portada**: proporciones a ojo; escudos e imagen, simplificados.
- **Por dentro** (claustro, patios, huerto): macizos de Catastro con tejado, sin patios; el huerto es una tapia con
  cipreses y árboles asomando.
- **La casa crema del sur** (la del portón con escudos de piedra) es la vecina y sigue siendo genérica.
