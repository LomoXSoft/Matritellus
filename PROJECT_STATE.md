# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Sin publicar

El detalle de cada pieza está en su LEEME de `referencias/` o `tools/`, en `guion/` y en el historial de git.

- **Parque del Paseo del Cristo (Edificios Especiales, 21/11; pendiente del visto bueno de Luis).** Hecho a mano (`paseo.gd`), sin rehorneado: se tiende sobre el suelo, el césped y la senda del mapa, y se recorta al asfalto del juego. Va de la esquina de la Calle de los Arcos a la placita de la ermita, unos 165 m. Lleva el paseo de baldosa con sus cuadros rojos, apuntado a la puerta de la ermita, las bandas de losas de pizarra, los céspedes con sus árboles, la acera ajedrezada, la plaza de ladrillo con la muela, el parterre de cipreses, la plaza del cruce, la tapia blanca, el murete con verja, la rocalla y el sauce, bancos de hierro y 22 faroles. Quita al cargar los 13 árboles del mapa que caían dentro. `paseo`: 3 ok. Hojas en `guion/fotos/paseo/`. [Detalle](TRASPASO_CLAUDE.md#parque-del-paseo-del-cristo-2111).
- **Residencia de mayores del Cristo del Prado (Edificios Especiales, 21/11; aprobada con el ala rehecha).** Hecha a mano (`residencia.gd`) con rehorneado: el edificio 4587301 del Catastro ya no se levanta. Lleva el bloque de tres plantas de ladrillo con mampostería, la entrada con el medio punto y la escalinata, el cuerpo redondo con la puerta de la Residencia y el ala baja. La fachada del ala a la placita se rehízo con las fotos 360 de Luis: un solo porche, y la fachada 2,85 m detrás de la línea del Catastro, según la ortofoto. `residencia`: 2 ok. Hojas en `guion/fotos/residencia/`. [Detalle](TRASPASO_CLAUDE.md#residencia-de-mayores-del-cristo-del-prado-2111).
- **Ermita del Cristo del Prado (Edificios Especiales, 21/11; aprobada con el murete de piedra y la acera de la esquina).** Hecha a mano (`cristoprado.gd`) con rehorneado: el Catastro la tiene junto a la Residencia como un solo edificio, y solo se quitan las partes de la ermita. Lleva la fachada con su portada de piedra y el campanario, la nave, el crucero, la cabecera, la acera del Paseo con el ajedrezado y el calvario del parque. `cristoprado`: 2 ok. Hojas en `guion/fotos/cristoprado/`. [Detalle](TRASPASO_CLAUDE.md#ermita-del-cristo-del-prado-2111).
- **Matías Pérez 16, retocada con Street View (Edificios Especiales, 21/11; aprobada: «Visto bueno»).** La casa ya iba en la 0.0.18 (`matias.gd`). Ahora tiene el ladrillo salmón a su tamaño, los sardineles del tono del muro, las persianas bajadas y visibles, las cortinas de rosas, la reja de nueve barrotes, dos cajitas blancas y el cable a la altura de los alféizares. `matias`: 2 ok. Hojas en `guion/fotos/matias/`. [Detalle](TRASPASO_CLAUDE.md#matías-pérez-16-retocada-con-street-view-2111).
- **Cámaras al conducir, Tomasa Malvora, chinos del Arroyuelo, fumadores y HUD dev (20/11).** 3 modos de cámara en coche (`V` / cruceta izq. / R3: 3.ª persona, 1.ª persona sin cabeza desde encima de hombros, cinemática tipo GTA con saltos cada ≥5 s o si se aleja), slow-motion + cámara cinemática al saltar por los aires con el coche, interior completo de los chinos del Arroyuelo (`chinos_dentro.gd`) con dependiente hablando en infinitivo, misión de Tomasa Malvora (`tomasa.gd`) con paquete de tabaco giratorio a 6 €, tabaco en el 5 % de los adultos/mayores (0 % niños) y opción de desarrollador para ocultar/mostrar el HUD (`ºª` / `Select`). [Detalle y pruebas](TRASPASO_CLAUDE.md#cámaras-al-conducir-tomasa-malvora-fumadores-y-hud-dev-2011).
- **Tanda de 20 mejoras jugables (20/11).** Rendimiento al pegar carteles, rampas lanzaderas de coches, cinemática nocturna del Galaxy Recress limpia, botón «Salir» en Tokken 9, Rally 9 a 3 vueltas con ruedas corregidas/hitbox dinámica/nitro de alcance, Katakumba69 por diálogo (máquinas contra la CPU), orientación de piezas y perros en el ajedrez, rondas de ocio de 12 NPCs únicos, velocidad diagonal radial, medidor de sospecha + furgoneta rápida con murmullos + arreglo de captura fuera de la furgoneta en el kebab, frases de golpe divididas (bate / atropello / ambas con «¡Ostia!»), conductores uniformados de policía y Guardia Civil, repintado y borrado de búsqueda en taller, pulsar Acción para entrar en interiores, selector/deselector de misión en el mapa grande, pickups 3D flotantes con halo (`pickups.gd`), inventario estilo Animal Crossing con 2 pestañas (`inventario.gd`) y confirmación de salida con ratón en menús. [Detalle y pruebas](TRASPASO_CLAUDE.md#tanda-de-20-mejoras-jugables-2011).
- **Hit The VIP.** La versión local 0.0.18 incluye la recreativa de boxeo contra Fonsi en el Galaxy Recress. [Ubicación, controles y pruebas](TRASPASO_CLAUDE.md#hit-the-vip-en-el-galaxy-recress).
- **Bajar del coche (19/11).** Corregida la salida al frenar y la actualización del aviso de interacción. El filtro `bajar` llega al puente con mando, habla con Alberto y sube a otro coche. [Reproducción y resultados](TRASPASO_CLAUDE.md#salir-del-coche-en-la-misión-del-puente).
- **RALLY 9 (19/11).** El asiento rojo del Galaxy Recress reabierto da acceso a una carrera de dos vueltas con El Tunero, tres rivales, tráfico, nitro, derribos y aftertouch. [Controles, decisiones y pruebas](TRASPASO_CLAUDE.md#rally-9-en-galaxy-recress).

- **Riña del jamón de Henry (19/11).** Un toque barre hasta dos vecinos y una carga hasta tres. La cámara sobre el hombro recoge el bate y evita las fachadas. [Controles, pruebas y capturas](TRASPASO_CLAUDE.md#riña-del-jamón-de-henry).

- **Boxeo de Fonsi (18–19/11).** El combate del V.I.P. permite golpear con ambas manos a dos alturas, cubrir la altura anunciada y responder a una esquiva limpia. La misión de Josefa, el reto del mostrador y la Agenda comparten el combate. [Controles, reglas y resultados de las pruebas](TRASPASO_CLAUDE.md#boxeo-de-fonsi).

- **Creador (17/11): la criba de sombreros y cuatro arreglados** («Sacame todos los sombreros con un personaje básico» / «Trata de arreglar esos 4»). **Visto bueno del usuario a los cuatro (17/11): «Si, esos cuatro lo pasan».**
  - Los cuatro venían de OverScore Proxy y estaban hechos para ir sobre pelo: al ajustarlos a nuestra cabeza salían enormes. Gorra de béisbol (10) y Gorra pa' trás (11): ahora piezas rígidas, como la parpusa, bajadas hasta apoyar en la cabeza (el usuario: «las gorras están flotando»); la de «pa' trás», además, más corta de delante a atrás (el usuario: «le sobra mucho de frente» y luego «es demasiado alargada»), inclinada 8° y con la copa por fuera del pelo de bola de los peinados viejos, que asomaba por detrás. Pañoleta (8): pegada a la cabeza y sin las puntas del nudo, que colgaban cuerpo abajo. Diadema (9), ahora «Cinta» por orden del usuario (en inglés sigue «Headband»): una cinta a la altura de la frente, más estrecha, girada 18° y por fuera del pelo.
  - `tools/creador/pelo.py` acepta tres ajustes nuevos por pieza en `piezas.json`: `cut_below` (quita lo que cuelga por debajo de una altura), `rot_x` (inclina la pieza), `squash_y`/`squash_z` (la acorta o la estrecha) y `over_hair` (un sombrero rígido pasa por fuera del pelo de bola). Fotos: modo `criba_sombrero` (el de `criba_pelo`, ampliado; escribe también los nombres). `ropa` 2/2. Ficheros: los cuatro `gorro_*.glb`, `pelo.py`, `piezas.json`, `selftest.gd`, `loc.gd` (solo el nombre).

## Versión

- **Publicada:** 0.0.18 (20/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.18 — completa: 879 ok y 1 fallo de la propia prueba (la copistería sin pulsar Acción), corregido y comprobado con `recress` (16 ok). Lo hizo Codex en X:\MatritellusGPT: [cambios y pruebas](TRASPASO_CLAUDE.md).

- **Anterior:** 0.0.17 (17/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.17 — completa: 816 ok, 0 fallos.
  - **Sistemas:**
    - Pausa: los coches ya no salen volando al volver (`CarS.held`: sin fuerzas acumuladas con la física parada).
    - El stick en menús, tableros y botones va por pasos con repetición de tecla (`controls.gd _stick`), no una pulsación por cada movimiento: el Steam Controller se desbocaba.
    - Niños: no conducen; los de la calle y el Niño Negro, a casa en horario de colegio y de 23:00 a 8:00.
    - La flecha de misión, sin transparencias por los lados (caras bien orientadas, prepaso de profundidad).
    - Colores en los diálogos: personajes en rojo, lugares en azul, objetos de misión en verde (listas repasadas por Worldbuilding).
    - Rondas de los personajes únicos sin misión (`rondas.gd`); la ruta del colesterol (`ruta.gd`); el ajedrez con cruceta, Y y vista de cine; Brillo en Gráficos; Alberto dice el plazo que toca.
  - **Recreativos:** «Yo no nací alcalde»; mientras el alcalde espera en la máquina, sin flecha de salida, flecha verde sobre él, «Jugar» antes que «Hablar».
  - **Creador:** la pintada de la peña se ve en el creador.
  - **Pretil:** la ermita de San Cristóbal (`cristobal.gd`, rehorneado).
  - **Texturas:** la Calle del Molino, las Travesías de las Viñas y de Portugal, la mitad oeste del Comisario.
  - El detalle de cada pieza está en el historial de git (este archivo, antes de la 0.0.17).
- **Publicada antes:** 0.0.16 (17/11/2026): las casas fundidas por zonas (la peor dirección de 10 a 53 fps), Feliciano, armas nuevas y el swing del bate en la riña, teclado QWERTY, la ermita de San Sebastián, el Buen Suceso y la Travesía de las Cruces.
- **Sin publicar (Texturas, 17/11): calle del Comisario, tramo este, 18 entradas (`com_*`; aprobadas: «Visto bueno y siguiente»).** Con esto la calle queda entera. Del 24 y el 15 al 1, más cuatro casas de la calle de los Cipreses que dan a esta (`com_ci*`).
  - Comparadas con las fotos del Catastro.
  - Sin hacer: Tembleque 40 A, en la esquina, que no tiene frente a esta calle.
  - Bake (en X:, avisando a Pretil): 18 casas nuevas. En `tembleque_75` y `com_b721` solo cambian marcas de medianera. Lo demás igual.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/comisario_5..7.jpg`.
- **Sin publicar (Texturas, 17/11): calle de Granada, tramo este, 16 entradas (`gra_*`; aprobadas: «Visto bueno y siguiente»).** Del 43 y el 46 al 26, más el costado de Cristo 30 (`gra_c30`).
  - Comparadas con las fotos del Catastro. El 41 D no tiene foto; va con Street View 2024.
  - Las casas que atraviesan hasta el Molino y ya tienen su trasera hecha allí (`mol_g*`) no se repiten: el horno solo da un frente por parcela y planta.
  - El 32 va por su parte de dos plantas (`floors: 2`) pero con la altura baja de la foto (3,8 m).
  - Bake (en X:, avisando a Pretil): 16 casas nuevas. En `mol_g35` solo cambia una marca de medianera. Lo demás igual.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/granada_1..3.jpg`.
- **Sin publicar (Texturas, 17/11): calle de Granada, tramo oeste, 14 entradas (`gra_*`; aprobadas: «Visto bueno y siguiente»).** Con esto la calle queda hecha. Del 22 al 4, más el costado largo de Arcos 29 (`gra_a29`).
  - Comparadas con las fotos del Catastro. El 20 no tiene foto; va con Street View 2024.
  - El 8 y el 18 van por su cara estrecha a la calle (2,9 y 2,5 m, la de `frente_gen`). `house_street` les daba una pared de dentro, y lo que asomaba hacia la calle salía con el tejado flotando.
  - Bake (en X:, avisando a Pretil; dos pasadas, la segunda solo para el 8 y el 18): 14 casas nuevas. `mol_g15` solo cambia por su medianera con el 13. Lo demás igual.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/granada_4..6.jpg`.
- **Sin publicar (Texturas, 17/11): calle del Peso, 11 entradas (`peso_*`; aprobadas: «Visto bueno y siguiente»).** La calle queda entera. Del 2 al 24, más un bloque de esquina de cuatro plantas sin dirección (`peso_b008`).
  - Comparadas con las fotos del Catastro.
  - Sin hacer: el recinto del viejo colegio (Juan Carlos I 46 D, ya hecho a mano por `colegio.gd`) y el 10, con 2 m de frente.
  - Bake (en X:, avisando a Pretil): 11 casas nuevas. En `nalda_9` solo cambia una marca de medianera. Ninguna con parte por delante de su frente. Lo demás igual.
  - `casas`: OK. `caridad` (Pretil, sobre este mapa): 3/3 OK; ninguna casa pisa la isla de la Caridad (la más cerca, `peso_b008`). Hojas en `guion/fotos/tanda34/peso_1..2.jpg`.
- **Sin publicar (Texturas, 17/11): calle de Covadonga, 12 entradas (`cov_*`; aprobadas: «Visto bueno y siguiente»).** Incluye casas con número de la calle de los Reyes Católicos (`cov_r*`), la esquina de Constitución 102 (`cov_c102`) y una casa sin dirección (`cov_b012`).
  - Comparadas con las fotos del Catastro. El 5 y la casa sin dirección no tienen foto; van con Street View 2024.
  - Sin hacer:
    - Reyes Católicos 3: una tapia de 55 m metida 11 m, con casetas en la acera. El frente de `house_street` era la pared de dentro, y el muro genérico que deja el horno, recto, cruzaba la calle. Se queda genérica.
    - El 11: sin frente.
  - Bake (en X:, avisando a Pretil; dos pasadas, la segunda para quitar Reyes Católicos 3): 12 casas nuevas. En `constitucion_98` y `cov_6` solo cambian marcas de medianera. Lo demás igual.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/covadonga_1..2.jpg`.
- **Sin publicar (Texturas, 17/11): calle de Santiago Apóstol, tramo este, 12 entradas (`sap_*`; aprobadas: «Visto bueno y siguiente»).** Del 1 al 12 y 5 B, más el costado de Monjas 31 (`sap_m31`) y la esquina de Florido 17 (`sap_f17`).
  - Comparadas con las fotos del Catastro. El costado de Monjas 31, con Street View 2024.
  - Sin hacer: el convento de Santa Ana (3792701, ya hecho a mano por `santaana.gd`) y Monjas 36, que no tiene frente a esta calle.
  - El 4 va por su cara a la calle (`frente_gen`). `house_street` le daba la pared de atrás, 5 m dentro.
  - Bake (en X:, avisando a Pretil; dos pasadas, la segunda solo para el frente del 4): 12 casas nuevas. Un clr de la calle baja de 2,3 a 2,1 m. Lo demás igual.
  - `casas`: OK. `santaana` (Pretil, sobre este mapa): 3/3 OK, el convento no se pisa. Hojas en `guion/fotos/tanda34/santiago_1..2.jpg`.
- **Sin publicar (Texturas, 17/11): calle de Santiago Apóstol, tramo oeste, 12 entradas (`sap_*`; aprobadas: «Visto bueno y siguiente»).** Del 13 y el 14 al 24. Con esto la calle queda entera.
  - Comparadas con las fotos del Catastro.
  - Bake (en X:, avisando a Pretil): 12 casas nuevas. Ninguna con parte por delante de su frente. Nada más cambia.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/santiago_3..4.jpg`.
- **Sin publicar (Texturas, 17/11): calle del Triunfo, tramo del pueblo, 17 entradas (`tri_*`; aprobadas: «Visto bueno y paramos por el momento»).** Del 1 al 18 A, más casas de la calle Nueva (`tri_n7`, `tri_n9`), de la calle de los Pajaritos (`tri_p1`) y de la Avenida de la Constitución 108 (`tri_c108`). Casi todo son almacenes viejos con portones.
  - Comparadas con las fotos del Catastro.
  - El 7, una tapia ciega de almacén, lleva el portón gris del final y dos manchas; sin ellos no llegaba al mínimo de piezas del test.
  - Sin hacer: el 18, una caseta de 14 m² con 2,4 m de frente.
  - Bake (en X:, avisando a Pretil): 17 casas nuevas. Ninguna con parte por delante de su frente. Nada más cambia.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/triunfo_1..3.jpg`.
  - El tramo de las afueras está en la entrada del 21/11.
- **Sin publicar (Texturas, 17/11): Matías Pérez 16 (`matias_16`) pasada a Pretil como `["obra"]`, por orden del usuario («Márcala ya»).** Su línea vieja está en las notas compartidas (`matias_16_antes_de_pretil.md`). `calles.json` no cambia: sigue horneada.
  - Pretil la levanta a mano en `matias.gd`, y sale en la 0.0.18: lo comprobó con la prueba `matias` (2 ok). Solo sale como hueco en las hojas de casas, que dibujan únicamente `casas.gd`.
  - `casas solo=matias_`: OK.
- **Sin publicar (Texturas, 21/11): calle del Triunfo, tramo de las afueras, 16 naves (`tri_*`).** Son almacenes y naves de la calle y de la Avenida de Europa, con su espalda o su costado en el Triunfo: tapias de ladrillo nuevo con portones de chapa, naves de bloque gris, una tapia vieja encalada con el barro a la vista y una nave moderna de paneles.
  - Comparadas con las fotos del Catastro. Para cuatro (`tri_e147`, `tri_x1`, `tri_e143`, `tri_e129`) la foto del Catastro está hecha desde la Avenida de Europa, así que se usó Street View.
  - Tres tapias lisas (`tri_e151`, `tri_e145`, `tri_41`) no llegaban al mínimo de piezas del test. Llevan lo que se ve en las fotos: los postes de delante, las juntas de los paneles y zonas de ladrillo desteñido.
  - Sin hacer:
    - el 35 (`4500005VJ5740S`): un bloque suyo sale 6 m por delante de la fachada;
    - el molino viejo de Reyes Católicos (`4699012VJ5649N`): su tapia de 87 m dobla con la calle, y recta queda metida en la calzada. Mejor a mano;
    - el 11 (`4498016VJ5649N`): el Catastro le da 0 plantas y el horneado no lo construye;
    - el 27: un soportal con 2,8 m de frente;
    - el 18: una caseta de 14 m²;
    - Pajaritos 3: es de otra calle.
  - Bake (avisando a Pretil): 16 casas nuevas. Ninguna con parte por delante de su frente. Nada más cambia: calles, nodos, relieve, árboles (2956) y holguras.
  - `casas solo=tri_`: OK tras los arreglos. Hojas en `guion/fotos/tanda34/triunfo_4..6.jpg`.
  - Aprobada por el usuario («Visto bueno»). Commit `1379d2f` de Sistemas.
- **Sin publicar (Texturas, 21/11): suelo de tierra pardo anaranjado con textura y plantas secas sueltas en todo el pueblo**, a petición del usuario. Los detalles están en `TRASPASO_CLAUDE.md`.
  - El suelo: `world.gd` (`EARTH`, la textura `"tierra"`, `_earth_mat()`), con los caminos de tierra y los barbechos en pardos.
  - Las plantas: `matojos.gd`, un paso «dry plants» de la construcción del mundo, guardado en `user://matojos.cache`. `--sin-matojos` las quita.
  - `casas` (6 casas del Triunfo): OK. `suelos`: OK. El `bench` no cambia (127,8 fps con plantas, 125,4 sin ellas).
  - Hojas en `guion/fotos/suelo/suelo_1..2.jpg`. **Aprobado** por el usuario el 21/11 («Mucho mejor. Visto bueno y siguiente»). Falta probarlo en el móvil.
- **Sin publicar (Texturas, 21/11): calle de los Cipreses entera, 33 casas (`cip_*`).** Hay de todo:
  - almacenes y tapias de ladrillo viejo, de bloque gris o encaladas, con portones de chapa o de tablas;
  - casas bajas con zócalo de piedra;
  - casas de dos plantas de ladrillo o de ocre con balcones de hierro;
  - un bloque de pisos en la esquina, adosados de 2006 y dos casas nuevas (2021 y 2025).
  - Comparadas con las fotos del Catastro. Siete con Street View:
    - el 38 y el 10, que no tienen foto del Catastro;
    - `cip_x1` y el 15, cuya foto del Catastro es antigua: un patio abierto y un solar derribado;
    - Monjas 119, el adosado de la Travesía y el 21 B, para ver qué lado da a esta calle.
  - Al compararlas cambié once cosas: remiendos de ladrillo inventados, tonos de ladrillo y de ocre, una puerta de garaje y unos pilares.
  - `cip_t60`, una tapia blanca, no llegaba al mínimo de piezas: lleva las pilastras y el portón gris azulado de su foto.
  - Sin hacer: Camino de Toledo 56, San Blas 45, Monjas 121, Travesía de los Cipreses 1 y el 5, porque no dan a esta calle; Tembleque 48, que es un solar.
  - Bake (avisando a Pretil): 33 casas nuevas. Ninguna con parte por delante de su frente. Nada más cambia: calles, nodos, relieve, árboles (2954) y holguras.
  - `casas solo=cip_`: OK tras los arreglos. Hojas en `guion/fotos/tanda34/cipreses_1..6.jpg`.
  - **Aprobada** por el usuario el 21/11 («Visto bueno y siguiente»).
- **Sin publicar (Texturas, 21/11): calle de las Viñas entera, 44 casas (`vin_*`).** Hay de todo:
  - los costados de las casas de la Avenida de la Reina Sofía;
  - la hilera de adosados de 1992 tras sus patios, blancos o amarillos con arcos de ladrillo;
  - los bloques de 1990 a 1997 de Buero Vallejo y Juan Antonio Jiménez: piedra abajo, portones de madera y balcones corridos;
  - tres bloques de pisos;
  - almacenes y tapias de tapial;
  - casas de ladrillo de 1985 a 2020.
  - Comparadas con las fotos del Catastro. Doce con Street View:
    - los costados de Reina Sofía, Valdespino 2, el 57 y la plaza de Jesús Requejo;
    - el 43, el 35 y el 9;
    - el 21, que hoy es una tapia y una alambrada;
    - el 22 A, que está sin foto en color.
  - Varias casas están metidas unos 11 m tras sus patios, así que sus frentes se sacaron con más alcance (`--reach=15`).
  - Quitadas tras la primera hoja: `vin_bv12`, `vin_bv11` y `vin_ja8`. Sus fachadas quedaban 4,5 a 8 m detrás de las de al lado, en el mismo lado de la calle, porque dan a Buero Vallejo y a Juan Antonio Jiménez. La cámara de la prueba quedaba dentro de otra casa.
  - Al compararlas se arreglaron:
    - las rejas de Reina Sofía 71;
    - el ladrillo de dos bloques;
    - una puerta de garaje;
    - la tapia `vin_rs67`, que no llegaba al mínimo de piezas: lleva la celosía de hormigón de lo alto.
  - Sin hacer:
    - Paseo del Cristo 2, que no da a esta calle;
    - el 2, con 1,9 m de frente;
    - los tres de arriba.
  - Bake (avisando a Pretil, dos veces, sobre su mapa con el Cristo del Prado y la Residencia): 44 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve y árboles (2954) siguen igual. La holgura baja unos 0,7 m en 21 nodos junto a las casas nuevas; la más justa queda en 3,7 m.
  - `casas solo=vin_`: OK tras los arreglos. Hojas en `guion/fotos/tanda34/vinas_1..8.jpg`.
  - **Aprobada** por el usuario el 21/11 («Visto bueno y siguiente»).
- **Sin publicar (Texturas, 21/11): calle del Florido, tramo norte (de los Silos a la Bajada del Florido), 29 casas (`flo_*`).** La calle tiene unas 84 casas y la Bajada otras 20; se hace en tres tandas.
  - Casas de los años 60 a 80 enfoscadas en tostado, crema o salmón con zócalo oscuro; ladrillo rojo de una planta; dos casas nuevas (2000 y 2001); almacenes con portones de chapa.
  - Comparadas con las fotos del Catastro. Doce con Street View (noviembre de 2024): el 60, que no tiene foto; el 61, el 58 B, el 54, el 68 y el solar del 69, que han cambiado; el 55 (del Catastro, Los Ángeles 15), el 62, el portón del b10, el x5, el 48 y el 50.
  - Puestas a mano:
    - el 68, con la fachada por su pared de delante sobre el hueco de la escalera;
    - el 50, partido por plantas (`only`: la parte de una planta y la de dos, con su frente cada una);
    - el portón del b10 (Bajada del Florido 10), que es su trozo de una planta a esta calle (`only` 1);
    - la tapia del patio del 62, sin referencia (`rc` null, 0,9 m de fondo), porque el Catastro da el patio sin plantas.
  - Al compararlas se arreglaron: la verja del 65, los tonos del 66, el 49, el 55 y la tapia del b10, la puerta del 58, el portón del 62, el friso del 48 y el 50.
  - Sin hacer: Los Ángeles 1, cuya cara a esta calle queda detrás de la casa de la esquina.
  - Bake (avisando a Pretil): 29 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve y árboles (2954) siguen igual; la holgura de un nodo baja de 4,9 a 3,5 m. Ninguna casa tiene partes por delante de su frente ni fachadas escondidas detrás de otra.
  - `casas solo=flo_`: 4 ok, 0 fallos. Hojas en `guion/fotos/tanda34/florido_1..5.jpg`.
  - **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»). Al mandar las hojas lo llamé «tramo sur» por error: es el extremo norte de la calle.
- **Sin publicar (Texturas, 21/11): calle del Florido, tramo medio (de la Bajada al 21 y al 26), y la Bajada del Florido: 34 casas (18 `flo_*` y 16 `bfl_*`).**
  - Casas viejas de tapial enfoscado en tostado o pardo, casas de 1960 a 1980 con zócalo de ladrillo o piedra, y almacenes; en la Bajada, ladrillo rojo y amarillo y dos casas encaladas muy viejas.
  - Comparadas con las fotos del Catastro. Ocho con Street View (noviembre de 2024), porque han cambiado o había dudas: el 41, el 39, el 35, el 30, el 31 y el 31 D (las ruinas son hoy una casa blanca nueva), y en la Bajada el 1 (edificio nuevo de ladrillo de 2025) y el 2.
  - `bfl_10` es la parte de dos plantas de Bajada 10 (`only` 2); su trozo de una planta al Florido ya era `flo_b10`.
  - Al compararlas se arreglaron los tonos del 27, el 23 y los amarillos de Bajada 21 y 23, y el zócalo del 26.
  - Sin hacer: Monjas 65 y 63 (sus caras a la Bajada quedan detrás de otras casas), Bajada 12 y 14 (el trazado del mapa pasa por encima), Bajada 25 y Los Ángeles 26 (sin frente a estas calles).
  - Bake (avisando a Pretil): 34 casas nuevas, ninguna quitada. Solo `flo_50g` cambia, en las aristas que tapa la casa nueva de al lado. Calles, nodos, relieve, árboles (2954) y holguras siguen igual. Sin partes por delante ni fachadas escondidas (comprobado antes de hornear).
  - `casas` de las 34: 4 ok, 0 fallos. Hojas en `guion/fotos/tanda34/florido_medio_1..6.jpg`.
  - **Aprobado** por el usuario el 21/11 («Visto bueno y siguiente»).
- **Sin publicar (Texturas, 21/11): calle del Florido, tramo sur (del 24 y el 15 hasta el final, con el 1 A y el 1 B), y la Prolongación del Florido: 39 entradas `flo_*`.**
  - En el tramo sur: casas viejas de tapial, almacenes, casas de los 70 a los 90 y bloques de tres plantas. En la Prolongación: diez pareadas de 1995 (lado impar), siete adosadas de 2006 con garaje en semisótano (lado par) y cuatro casas de 2006 a 2015.
  - Comparadas con las fotos del Catastro, y con Street View (noviembre de 2024; la Bajada del Rollo, 2026) en el 24 (sin foto), el 15, el 13, el 11, el 9, el 7, el bloque sin número `flo_x2`, el 3, la esquina `flo_x3`, el 2 A y las pareadas del 9 y el 11.
  - Dos referencias llevan dos entradas cada una (`only`): `flo_x2` (bloque de tres plantas) y `flo_x2g` (su almacén, `reach` 6); `flo_x3` (bloque de la esquina) y `flo_x3t` (tapia de bloques).
  - Pareadas impares: el frente va en la cara de la casa de dos plantas, paralelo a la calle y a todo lo ancho (`floors` 2); el porche de una planta de delante se quita con `strip: 2.5`.
  - `flo_br6` lleva `reach` 8: su bloque de dos plantas del fondo queda como casa normal.
  - Al compararlas se cambiaron el ladrillo de `flo_x2` y de las adosadas (a `brick_buff`) y el tono de las rejas del 13 y el 15 de la Prolongación.
  - Sin hacer: Bajada del Rollo 4 (derribada; en el juego queda la casa genérica) y la Prolongación 28 (da al Camino de Consuegra).
  - Bake (avisando a Pretil): 39 casas nuevas, ninguna quitada ni cambiada. Calles, nodos, relieve, árboles (2954) y holguras siguen igual. Sin partes por delante ni fachadas escondidas.
  - `casas` de las 39: 3 ok y 1 fallo (`flo_x3t`, pocas piezas); arreglado, 4 ok, y 4 ok tras los cambios de color. Hojas en `guion/fotos/tanda34/florido_sur_1..7.jpg`.
- **Pendiente:**
  - Texturas:
    - **La calle de la Cruz (`cruz_*`) salió en la 0.0.13 con 31 casas.** Después, ya en X:, quité `cruz_13` y `cruz_17`, cuyo frente quedaba metido en la manzana, y quedaron 29. A `cruz_vg9` y `cruz_21` les puse alero de teja. Rehorneado sin más cambios, y `casas` OK. Las hojas `guion/fotos/tanda34/cruz_1..5.jpg` se mandaron al usuario el 17/11, que dio su «Visto bueno».
    - La travesía del Clavel, que hay que hacer a mano.
    - El repaso de lo que aún no se parece: `guion/repaso_casas.md`.
  - Creador: el resto de la criba de piezas (ropa, sombreros, lo que quiera quitar), cuando el usuario quiera. Lo hecho hasta ahora tiene su visto bueno (17/11).
  - Sistemas: `sentido` falla a veces (coches en contra al dejar conducir al tráfico); ya pasaba antes de los cambios de rendimiento.

## Cómo trabajar (normas del usuario, 15/11/2026)

- **Pruebas:** siempre con `python tools/run_tests.py <modo>`. Es una sola llamada que espera al final, con tiempo límite. Guarda el registro en `logs/` y devuelve un resumen.
  - Tras cada cambio, la prueba del modo afectado (`--selftest --<modo>`; la lista está en `selftest.gd`, `_run`).
  - La prueba completa (`python tools/run_tests.py`), solo en los hitos, antes de publicar o si lo piden.
  - Nada de vigilar pruebas largas a base de llamadas repetidas.
  - Los modos de fotos (`firmas`, `relief`, `casas`, `caridad`…) necesitan ventana: sin ella no escriben nada y se quedan esperando. Desde el 15/11 por la tarde el lanzador la pone solo: si el bloque del modo en `selftest.gd` empieza con `shots = true`, o si se pide `shots` o `vistas=`. `--headless` lo fuerza sin ventana. El tiempo límite corta aunque Godot no escriba nada.
- **Fallos intermitentes:** se investigan uno a uno, con el modo y su `--traza`, y `--repeat N` si hace falta.
- **No releer** archivos ni fotos que no han cambiado.
- **Sesiones a la vez:** cada una toca sus archivos. Se avisa antes de una prueba completa. Para publicar se congela la carpeta.
  - Todas las sesiones trabajan en la misma carpeta, sin carpetas de trabajo (git worktree) separadas: lo decidió el usuario el 15/11. Cada una toca sus archivos y avisa antes de tocar los de otra.

## Fallos conocidos

- **Límite, «everybody comes after you»:** intermitente. A veces el calor sale 98 cuando se pide ≥ 99: baja un poco si el juego va lento, por ejemplo con otro Godot abierto. Falló una vez el 16/11 y pasó 3/3 con `--repeat` justo después.
- **Grúa:** a veces se queda parada a unos 130 m del coche, en la esquina de (871, 254) o (880, 247), detrás de un coche aparcado. Está atenuado con `_room_at` y `_clear_parked`; vigilarlo.
- **Sabotaje:** la furgoneta se atascaba en calles estrechas, sobre todo en (-472, -340), tramos 856-858. Ahora tiene la ruta cerrada; vigilarlo en las completas.
- **Turbo del Julietta:** la segunda pasada se quedaba a 0 km/h de vez en cuando; ahora la prueba usa un coche nuevo.
- **Pruebas con ventana:** `--menu`, `--titulo --shots`, etc. La ventana ya no coge el teclado (`WINDOW_FLAG_NO_FOCUS`).
- **Mirada, «talk to them and they stand still to answer»:** falló una vez en una completa (14/11) y no se ha repetido (`mirada`, `mirada viejo`, `mirada antes` y la completa de la 0.0.3 pasan). Si vuelve, el mensaje dice voz, estado, si el diálogo sigue abierto y cuánto se movió; con «dialogue none», mirar las llamadas de la centralita (desde la 0.0.3 una llamada ya no corta una conversación, que seguramente era la causa).
- **Sin probar en dispositivos reales:** móvil y Steam Machine. Si hay tirones en la Steam Machine, pedir `tirones.txt`.
- **Tokken 9** (publicado desde la 0.0.3; `guion/tokken9.md`): nadie lo ha jugado con las manos. La dificultad del alcalde y de Katakumba69 sale solo de la simulación (`python tools/run_tests.py tokken balance`); cuando el usuario diga cómo lo nota, se retoca `AI["alcalde"]` en `tokken.gd`, sin quitarle que baje la guardia tras el primer golpe. Los botones del móvil y el mando, sin probar.

## Decisiones recientes

- **Pendiente apuntado por el usuario (15/11): niños en la escuela «S. José de Calasanz» en horario escolar.** Preguntó «Habrá niños en Calasanz en horario escolar?» y pidió dejarlo anotado. Hoy el patio está vacío. Para cuando pula los personajes (no antes: no quiere personajes nuevos por ahora): niños solo de lunes a viernes en horario de clase, siempre dentro del patio cerrado (ni en la calle ni atropellables), jugando en el recreo en la torre, el tobogán, los caballitos y la rayuela, y oyéndose al pasar el resto del horario. Falta el modelo de niño y el sistema que los saque y los guarde según la hora (Sistemas). Lo propuesto es idea de Pretil; el usuario solo ha dicho que se anote.
- Misión cumplida: solo el sello ¡APAÑAO! y el dinero en la pizarra, sin cartel.
- Galaxy Recress: el alcalde pide 100 € y devuelve 200 € (lo dijo el usuario). En Tokken 9, por confirmar con él: el alcalde lleva a El Monstruo y Katakumba69 a Drácula, la partida libre es gratis y los nombres de los poderes.
- Límite del mapa: 1950 m, recortado al borde del mapa construido.
- Cristales del Edison: opacos (al usuario no le gustaron los tintados).
- El sol sale por el este desde la 0.0.5.
- Blanco en sombra (desde la 0.0.5): de día la luz ambiente se mezcla más con blanco (`game.gd`, `_apply_sky`), para que el enfoscado blanco se lea blanco en sombra. De noche sigue azul.
- Toro de Osborne (desde la 0.0.5): en la A-4, km 120, pasado el borde sur del mapa; se ve desde la autovía (`toro.gd`, `data/toro.json`, `tools/toro/`).
- Costados de las casas que dan a otra calle: terminados. 42 de 71 descritos (y 5 más de los cortos, de 6 a 8 m) con Street View (líneas `lado` en `casas_calles.gd`, `"flank"` en `casas.gd`); los otros 29 se quedan lisos porque no se ven desde ninguna calle (dan a patios o tienen otra casa pegada delante) o no hay foto.
- Música «urbana»: en Rap-A-Polvo. El usuario no ha dicho nada en contra.
- Galaxy Recress (desde la 0.0.3; diseño en `guion/recress.md`, prueba `recress`): abre de 15:00 a 2:00 y, si estás dentro a la hora de cierre, espera a que salgas. El alcalde pide 100 € y devuelve 200 €. Una llamada no corta una conversación ni una escena (`llamadas.gd`). Pendiente del usuario: los nombres provisionales (el alcalde, la de la copistería, la mujer y la madre del alcalde, el comentarista).
- Habla (desde la 0.0.3): los mancheguismos, sobre todo para los mayores (`generic_old`, `whisper_old`, `ouch_old`). «Apretar» sin diptongo: apreta, apretes. Y en boca de todos (desde la 0.0.9): «tiés» por «tienes» y «ande» por «dónde/donde» («por donde» también: «ande puedas»). Desde el 17/11 (sin publicar) la prueba vigila todas las reglas de la casa (lé, la'é, l'á, -ao/-ío, pa, to, na, vía, cá, semos, entoavía, enga, mu) en lo que dice cualquiera, salvo `HABLA_FINA` (el alcalde, menús, pantallas, carteles) y lo que va entre «». Todo en `guion/palabros.md`, contado con nuestras palabras porque su web es CC BY-NC-ND. José-María Moreno García va en los créditos. Lo comprueba `python tools/run_tests.py palabros`.
