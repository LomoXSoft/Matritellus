# El parque del Paseo del Cristo

Luis, 21/11/2026, después de aprobar la Residencia: «Podemos continuar con el parque largo empedrado que hay al lado del paseo del cristo (tiene su propia linea en street view, sin nombre)». Mandó una foto de noviembre de 2024 de la esquina oeste, con la casa de los arcos y la muela, y un mapa con la flecha.

En el mapa se llama «Parque del Paseo del Cristo». Va de la esquina de la Calle de las Viñas y la Calle de los Arcos a la placita de la ermita del Cristo del Prado, unos 165 m. El paseo central apunta a la puerta de la ermita.

## Script

`godot/scripts/paseo.gd`, sobre `obra.gd`, paso «the park of the Paseo del Cristo» en `world.gd`, detrás de la Residencia. **No hay horneado**: se tiende sobre el suelo, el césped y la senda que ya tiene el mapa y se recorta a las calles del juego.

- **Marco**: origen en el extremo oeste de la senda del mapa, (132.6, 441.6); x a lo largo (u = (0.9424, 0.3346), hacia la ermita); z a lo ancho, hacia el Paseo.
- **El paseo**: centro en z = −3.2 + 0.004·x, 4.4 m de baldosa clara con un cuadro rojo en un marco rojo cada 15 m; a cada lado, 1.4 m de losas de pizarra irregulares (`tools/paseo/losas.py` → `godot/assets/paseo/losas.png`).
- **Los bordes se leen del juego al cargar**: el asfalto del Paseo, por el sur, y la tapia, la verja, el callejón o las casas, por el norte.
- **Los árboles del mapa** que caen dentro se quitan con `W.fell_tree`, y se plantan los del parque.

## Fuentes

- **Street View**, con las cámaras en `tools/paseo/capturas.py`:
  - la línea propia del parque, sin nombre: solo marzo de 2013, cámaras unos 3 m al norte de la senda del mapa;
  - el Paseo: noviembre de 2024, con 2009–2021 detrás.
- **La ortofoto PNOA**: `tools/ign/paseo_cristo.jpg` (x 100–320, z 410–545, 0.15 m/px). Las copas de los árboles salen de ella, enderezada a lo largo del parque.

## Trampas

- **El Paseo del juego** está unos 4 m metido en el parque real. El borde del asfalto va de z ≈ 7.4 en el oeste a 13.4 junto a la ermita. La acera ajedrezada (2.6 m) va pegada a ese borde, así que el césped sur queda más estrecho que el real.
- **La línea de Street View del parque** es solo de 2013. En 2024 solo hay fotos desde el coche.
- **La tapia blanca** de los huertos (x 13–40) no existe en el mapa: detrás solo hay suelo. La levanta el parque.
- **El callejón del norte** (OSM living_street, tramo este–oeste) sí existe: queda por encima, tras un murete de mampostería con verja.

## Las piezas de piedra (marzo de 2013)

Luis, 21/11: «Faltan varias cosas. La prensa de piedra, el monolito de piedra, la mesa de piedra, la fuente», con cuatro capturas de la línea propia del parque (2013). Cada pieza tiene su función en `paseo.gd`:

- **La prensa** (`_press`): en la esquina ante la casa de los arcos. Tres rulos cónicos alrededor del poste de hierro, uno mirando a la casa. En 2024 en su sitio hay una muela de pie y un cono, pero se ha hecho la de 2013.
- **El monolito** (`_monolith`) está en (12,4, 1,7) del marco, con su banco de granito al borde del paseo y el pilón en (10,6, 1,3).
- **La mesa** (`_mesa`) está en (17,9, 1,2): un asiento redondo abierto al este y al oeste, con respaldo al sur. La acacia queda detrás.
- **La estatua** (`_statue`), sobre el montículo de la fuente. Es una figura del juego (`chara.gd`) pasada a mármol blanco, como el fraile de bronce de Santa Ana: una mujer con moño y un cántaro al hombro izquierdo, del que cae el agua a la fuente (Luis). Donde mejor se ve la real es en Street View: p14_n.
- **La fuente** (`_fountain`) está en x = 128,3. Se coloca sola entre el borde norte del juego y el paseo, porque el callejón del juego pasa unos 2 m más al sur que el real. El sauce y la palmera quedan a cada lado.

## Vistas

Las de las piezas (en metros del mapa; el prefijo `ps_`, porque `pz_` se lee en el marco de la plaza):
`python tools/run_tests.py "vistas=ps_prensa:136.02,436.45,1.6,132.95,431.64,0.9,60;ps_monolito:142.02,441.97,1.7,144.49,448.47,1.0,65;ps_mesa:150.06,445.04,1.7,148.46,450.42,0.6,65;ps_fuente:254.36,481.22,1.7,256.52,476.04,1.1,65;ps_estatua:255.05,480.19,2.0,255.94,477.68,2.05,40"`, y después `hojas.py ... piezas=F1,F2,F3,F4`.

`python tools/merkocarry/vistas.py SV c03_n c04_n c06_n c09_n c12_n c16_n p01_e p05_e p09_e p13_e p01_n p11_n p13_n` y después `python -I tools/paseo/hojas.py SV [foto=...]`.
