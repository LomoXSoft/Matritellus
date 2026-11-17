# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Sin publicar

El detalle de cada pieza está en su LEEME de `referencias/` o `tools/`, en `guion/` y en el historial de git.

- **Sistemas (17/11): menos tráfico y menos luces de noche** («Baja y vuelve a medir»). Medido en el PC del usuario, a pantalla completa, en la Plaza:
  - Antes: 69 fps de día y 44 de noche; conduciendo, 82 fps de media.
  - Después: 70 fps de día y 65 de noche; conduciendo, 92 fps de media, con la mediana de 13,0 a 11,7 ms.
  - El 16/11 eran 78 de día y 62 de noche. Lo que falta hasta entonces es la física y el contenido nuevo (unos 10.000 nodos más).
  - Coches en circulación: de 14 a 10 (con «Tráfico: ligero», de 8 a 6), en `traffic.gd` MAX_CARS y `game.gd`. Luces reales de las farolas: de 32 a 16 (`lights.gd` POOL).
  - Visto en la medida: el primer coche de cada tipo que se construye da un tirón de unos 22 ms, hasta que hay coches guardados para reutilizar. Con el tráfico quitado se ganan unos 2 ms, más de lo que cuestan 2 coches: hay un coste fijo del tráfico.
  - `selftest.gd`: la completa pedía MAX_CARS ≥ 14; ahora ≥ 10. Esa comprobación solo corre en la completa, que no se ha pasado.
  - Coches construidos durante la carga (`traffic.prewarm`): un Panda y un Z15 más, y un Pitufo, un Tricornio y una grúa ocultos. Los coches patrulla salen en tres de cada diez apariciones y no se guardaban para reutilizarlos. El primer coche en la calle pasa de dar un tirón de 22 ms a uno de 9 ms. La carga tarda 0,1 s más. `grua` 29/29, `limite` 6/6.
  - La carga dura 45 s en el PC: 26 s son las casas, en un solo paso (`buildings`), que antes tardaba 19,5 s.
- **Sistemas (17/11): la carga, de 45 a 32 s, y el tres en raya con el alcalde mientras carga** («El tres en raya con el alcalde suena bien. Podemos además quitar el LomoXGames de la pantalla de carga… Pero primero trata de ver si podemos hacer algo con las casas»).
  - **Las casas a mano** (1.916) tardaban 31 s: 26 en generar sus piezas en GDScript, vértice a vértice en un SurfaceTool. Ahora tardan 14 s.
    - `casas.gd` (con el visto bueno de Texturas): las piezas se juntan en listas empaquetadas (`Acc`) y la malla se hace de una vez; `box()` calcula sus 8 esquinas una sola vez. La tela sigue con su SurfaceTool.
    - La geometría es la misma: con `--casas-lento` (el camino viejo) y sin él, sobre los mismos datos, salen 28.307.422 vértices, 651.850 con uv y la misma suma de posiciones y normales (`--timing --casas-suma`).
  - **Las casas, en tandas** (`world.gd`): un paso «houses» propio, en tandas de 30 ms. El paso devuelve true mientras quedan casas, y `world.build()` y el bucle de carga lo repiten. La pantalla de carga contesta entre tanda y tanda.
  - **La pantalla de carga** (`game.gd`, `raya.gd`, `loc.gd` `alcalde_raya_*`, `raya_score`): sin el logo de LomoXGames, que sale después en la intro. En su lugar, un tres en raya contra el alcalde: tú con las X y él con las O, empezando por turnos. Juega bien, pero tres jugadas de cada diez las hace sin pensar, así que se le puede ganar. Lleva marcador, y sus frases son finas, como las suyas.
    - El suelo también va por partes («Solo el suelo»): el terreno, los seis tipos de campo, los caminos de tierra, las aceras, los paseos, el asfalto, las marcas, los pasos de cebra y la caché, en el orden de siempre (la caché los guarda por orden). Lo más largo que queda de un golpe son las aceras (1,4 s) y el asfalto (1,1 s), y solo la primera vez tras cambiar el mapa: luego el suelo sale de la caché en 1 s. `relief` 19/19.
    - Las pruebas siempre cortan el suelo de nuevo (no usan la caché a propósito). En una partida, solo tarda unos 5 s la primera vez después de cambiar el mapa.
    - Sigue congelándose en los vecinos (2,4 s) y en los árboles (1,9 s): el usuario dice que no merece la pena trocearlos.
- **Sistemas (17/11): los coches lejanos, por su carril sin física** («Si, coches lejanos sin física completa»), en `traffic.gd` (`_rails`, `_rail_move`, `_off_rails`).
  - Un coche del tráfico a más de 110 m, o a más de 70 m fuera de cámara, se congela y avanza por su carril a su velocidad: escoge en los cruces como siempre y frena tras el que lleva delante. Vuelve a ser un coche con física a menos de 60 m, o a menos de 90 m en cámara, con la velocidad que llevaba y solo si no pisa a otro coche.
  - Nunca van por carril la grúa en un aviso, los coches que van a un sitio ni el tuyo con piloto automático.
  - Medido con los 10 coches (lejos los 10): la física pasa de 11,0 ms por tick a 7,5–8,2 ms. Los fps salieron demasiado variables (62–68 con lo mismo) para ver ahí la ganancia.
  - `--perfil` llena ahora el tráfico antes de medir, compara con los coches lejanos con física completa (`traffic.rails = false`) e imprime todas las marcas del tick; hay marcas nuevas (audio, cielo, luces, comida y reloj, puertas y flechas, «what is near»).
  - `sentido` 2/2 (antes fallaba a veces), `grua` 29/29.
- **Sistemas (17/11): las vallas amarillas de obra** («Las hit-boxes de la vallas amarillas son enormes, puedes golpearlas desde muy lejos»), en `props.gd`.
  - Antes: una caja de 2,5 × 1,05 × 0,35 m (la profundidad de los pies hasta arriba), y un puñetazo contaba hasta a 1,9 m (2 m con el bate).
  - Ahora: el panel (7 cm de grosor) y sus dos pies como cajas aparte. Al puño o al bate, la valla solo cuenta si su recorrido pasa a menos de unos 36 cm del panel, es decir, hasta 1,3 m. Los coches la tumban como antes.
  - Prueba nueva: `valla` (y en la completa).
- **Sistemas (17/11): subirse de un salto a un capó, a un techo o al pretil de piedra** («Se podría dar la hitbox de los coches un poco menos cúbica. Me gustaría poder subirme a un capó de un salto»; «saltar ... en la barandilla de piedra del pretil. Pero el personaje siempre se cae»).
  - **Los coches** (`car.gd` `_stepped`): en vez de una caja hasta el techo, cajas una tras otra a lo largo, cada una tan alta y tan ancha como la carrocería allí (el capó bajo, la cabina, el maletero), sin los retrovisores; como mucho 6. Salen de la nube de puntos de cada modelo, una vez por marca. `top_at(p)` dice a qué altura queda el coche sobre un punto.
  - **Tú** (`chara.gd` `_stand`, `game.gd` `car_floor_at`): un rayo hacia abajo desde un poco por encima de tus pies, en el centro y en cuatro puntos a 25 cm, busca la primera cosa sólida (el mundo o un coche). Si tus pies están a su altura o hasta 35 cm por debajo, te quedas de pie encima. Así vale para capós, techos, el pretil del Petril, muretes y escalones. Si sales andando por el borde, caes. Los vecinos no saltan y siguen como antes.
  - Ya no hay norma de «por encima de un coche no se salta»: la forma nueva del coche frena el salto que no llega.
  - **Si el coche se mueve, te lleva** (`_ride_car`): avanzas y giras con él. Si es del tráfico, se para y te pita.
  - Prueba `salto` 11/11: un saltito al costado de un coche no te sube; un salto mantenido al capó te deja de pie en él; bajas andando por el lado; al pretil desde su plaza, y de vuelta. Fotos `salto_capo` y `salto_pretil`.
  - `vuelcos` 1/1 con la forma nueva: ninguna marca vuelca, conduciendo a fondo por el pueblo ni a todo giro o en zigzag.
    - La barra avanza por pasos, no por tiempo: tras las casas, que son la mitad de la carga, marca un 15 %.
  - Pruebas: `relief` 19/19, `casas solo=cruz_` 4/4 y `raya` 3/3 (nuevo, también en la completa, con foto `raya_carga`). La completa no se ha pasado.
- **Pretil (17/11): la Pizzería Toti, Salvador 2 y la manzana de la Casa Grande.**
  - La Pizzería Toti (`toti.gd`, sobre `cajal_3`), con su terraza y el horario de Google Maps; Salvador 2 (`salvador2.gd`, sobre `cajal_1`): «Ha quedado estupendo». Pruebas `toti` y `salvador2`.
  - La Casa Grande (el nombre del usuario para la casa de la cultura), la biblioteca y la escuela de música y danza, entre los Arcos, Argentina y el Callejón Pando (`cultura.gd`), con el arco y su torrecilla. Rehorneado con el OK de Sistemas y Texturas (`CULTURA_RC`): solo cambió la manzana.
  - Con las fotos de la web del Ayuntamiento que mandó el usuario: el escudo de verdad sobre la puerta, dibujado a mano como relieve (`tools/cultura/escudo.py` → `godot/assets/cultura/`), y la portada (jambas de sillares, dintel en abanico, cornisa). Tras «Debería estar igualada», el zócalo de granito va seguido a la misma altura a los dos lados de las puertas. Las ventanas bajas de los Arcos bajan hasta el zócalo, con reja saliente y dintel de ladrillo.
  - El usuario: «Casa grande está perfecta». Después, con dos fotos: «La entrada de la biblioteca no se parece en nada». La biblioteca rehecha: su fachada va 2,8 m metida tras un cuerpo que sale a la calle, con la puerta, el tejadillo y un rellano con escalones (sin rampas, como dijo). La escuela de música: alturas desde su calle (2 m más alta), paños blancos en columnas a Argentina y el frente al aparcamiento como en las fotos.
  - `cultura` 2/2 (fotos nuevas `cultura_portada`, `cultura_escudo`, `cultura_entrada_este`, `cultura_entrada_oeste`). Hojas en `guion/fotos/cultura/`. Visto bueno a todo (17/11: «Perfecto. Visto bueno»).

## Versión

- **Publicada:** 0.0.13 (17/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.13 — completa: 770 ok, 0 fallos. La primera completa dio 8 fallos y la segunda 2, todos arreglados: un menú que dejaba abierto un check anterior, el recuento de paredes, el coche del MasAhorro que nacía dentro del contenedor de ropa, el calor de la persecución del límite, el balanceo de los niños del ajedrez y las firmas que les faltaban a los funcionarios de Correa.
  - **Sistemas:** las respuestas de una charla, en una burbuja sobre el diálogo (visto bueno: «Looks pretty dope»). Las cartas desde Correa: Diurno y Nocturno Correa, sus batallitas de la mili, una carta al día y la llamada del día siguiente (+5 si es amable, +3 si es normal y -3 si es mala). El modo `cartas`.
  - **Pretil:** el Merkocarry, con su interior y la nave de la Mayordomía; Correa, con su verja, sus rótulos de noche y su interior; el recinto ferial, con sus siete caminos cerrados a los coches, el parque del Paseo del Cristo, el Auditorio y los aseos públicos con interior. Además, el MasAhorro ya no pone coches dentro del contenedor de ropa.
  - **Texturas:** los restos del centro y los de Ramón y Cajal, Madrid y la Constitución; San Isidro, Tembleque, las Monjas (con la Bajada del Rollo), la Avenida de la Constitución hasta la A-4, el Regidor, San Rafael, el Callejón Pando y la calle de la Cruz.
  - **Creador:** la criba de peinados: el moño más grande, la cresta con pinchos, el tupé nuevo, el Rapao fuera del creador y tres nombres nuevos (Ensaimadas, Degradado Inverso y Tazón).
  - El detalle de cada pieza está en el historial de git (este archivo, antes de la 0.0.13), en los LEEME de `referencias/` y `tools/` y en `guion/`.
- **Publicada antes:** 0.0.12 (16/11/2026): Android vuelve a arrancar, y las calles de Jesús y María y del Romero.
- **Sin publicar (Texturas, 17/11): Travesía de San Francisco, 9 entradas (`trsf_*`; el usuario dijo «Sí, sigue» al verla).**
  - Comparadas con las fotos del Catastro, que aquí son buenas.
  - Bake (en X:, avisando a Pretil): 9 casas nuevas. Calles, nudos, `clr`, relieve, árboles y las claves de los sitios hechos a mano no cambian. Solo cambian las piezas de `portugal_20b`. `casas`: OK. Hojas en `guion/fotos/tanda34/trsf_1..2.jpg`.
- **Sin publicar (Texturas, 17/11): calle de la Amargura, lo que quedaba, 6 entradas (`amargura_b401`, `b727`, `b743`, `b725`, `b724`, `t1`; el usuario dijo «Sí, sigue» al verla).**
  - `amargura_b401` es el costado de la Plazuela del Toledano 3. Pretil pasó `toledano`: 4/4, y ninguna casa nueva pisa la plazuela.
  - `amargura_t1` es la trasera de una planta de `tembleque_1` (`only` 1).
  - Comparadas con las fotos del Catastro y con Street View 2024.
  - Bake (en X:, avisando a Pretil): 6 casas nuevas. Calles, nudos, `clr`, relieve, árboles y las claves de los sitios no cambian. Solo cambian las piezas de `tembleque_4`. `casas`: OK. Hoja en `guion/fotos/tanda34/amargura_1.jpg`.
- **Sin publicar (Texturas, 17/11): calle de Argentina, lo que quedaba, 3 entradas (`argentina_b029`, `b020`, `b028`; aprobadas: «Visto bueno y seguimos», que vale también para la Travesía de San Francisco y la Amargura).**
  - `argentina_b028` es Cristo 8, una mercería; su rótulo dice solo «MERCERÍA».
  - No se tocan la nave de la Mayordomía (Pretil) ni el centro de salud.
  - Bake (en X:, avisando a Pretil): 3 casas nuevas. Nada más cambia, `merkocarry` incluido. `casas`: OK. Hoja en `guion/fotos/tanda34/argentina_1.jpg`.
- **Sin publicar (Texturas, 17/11): calle de Extremadura, lo que quedaba, 5 entradas (`extremadura_b425`, `b424`, `b441`, `b421`, `b208`; el usuario siguió con «Ves cogiendo datos de Reina Sofía»).**
  - Comparadas con las fotos del Catastro.
  - **Quitada:** `extremadura_b217`, el costado de la Travesía de Portugal 7: salía debajo de la fachada de otra casa.
  - Bake (en X:, dos pasadas, avisando a Pretil): 5 casas nuevas. Nada más cambia; solo se retocan las piezas de `extre_2` y `extre_16`. `casas`: OK. Hoja en `guion/fotos/tanda34/extremadura_1.jpg`.
- **Sin publicar (Texturas, 17/11): Avenida de la Reina Sofía, 14 entradas (`rsof_*`; aprobadas: «Visto bueno y sigue»).**
  - Comparadas con las fotos del Catastro, que aquí son buenas.
  - No está hecho el 1: es de esquina y su fachada a la avenida es un chaflán de 2,3 m.
  - A `rsof_3` se le subió la altura de 3,6 a 6,4 m.
  - Bake (en X:, después de las medidas de rendimiento de Sistemas y avisando a Pretil): 14 casas nuevas. Nada más cambia; la casa más cercana queda a 51 m del Petril. `casas`: OK. Hojas en `guion/fotos/tanda34/rsof_1..3.jpg`.
- **Sin publicar (Texturas, 17/11): calle de las Delicias, primer tramo, 17 entradas (`delicias_*`; aprobadas: «Visto bueno y siguiente»)**, con tres casas de la calle de la Parra que dan a ella (`delicias_p8`, `p10`, `p13`).
  - Comparadas con las fotos del Catastro.
  - Sin hacer el 12: su frente a la calle es de 2,4 m.
  - Bake (en X:, después de la segunda medida de Sistemas y avisando a Pretil): 17 casas nuevas. Nada más cambia; solo se retocan las piezas de `real_80`. `casas`: OK. Hojas en `guion/fotos/tanda34/delicias_1..3.jpg`.
  - Queda el segundo tramo, unas 19 casas, del 26 hacia el este (`del_list.txt` en el scratchpad).
- **Sin publicar (Texturas, 17/11): calle de las Delicias, segundo tramo, 17 entradas (`delicias_21a` a `delicias_55` y `delicias_j41`; aprobadas: «Visto bueno y siguiente»).** Con esto la calle queda entera.
  - Comparadas con las fotos del Catastro. El 21a es un solar con tapia de ladrillo.
  - Sin hacer: Juan XXIII 34 y 32b, que no tienen frente a las Delicias.
  - Bake (en X:, avisando a Pretil): 17 casas nuevas. Nada más cambia. `casas`: OK. Hojas en `guion/fotos/tanda34/delicias_4..6.jpg`.
- **Sin publicar (Texturas, 17/11): calle de la Virgen de Gracia, 24 entradas (`vgracia_*`; aprobadas: «Visto bueno y siguiente»).** Incluye el costado de la calle del Cristo 20 (`vgracia_c20`).
  - Comparadas con las fotos del Catastro; el 16 y el 8d, que no tienen foto, con Street View 2024.
  - Sin hacer: el 36 y el 20 (frentes de 2,4 m) y Cristo 13 y 15 (no dan a la calle).
  - Bake (en X:, avisando a Pretil): 24 casas nuevas. Nada más cambia; el centro de salud queda a 41 m.
  - `casas`: OK, ya con el `casas.gd` nuevo de Sistemas. Hojas en `guion/fotos/tanda34/vgracia_1..4.jpg`.
- **Sin publicar (Texturas, 17/11): calle de las Cruces, 25 entradas (`cruces_*`; aprobadas: «Visto bueno de momento. Ya arreglaremos detalles en el futuro»).**
  - Comparadas con las fotos del Catastro.
  - Sin hacer: el 21 y el 6, con frentes a la calle de 2,6 y 2,2 m. El 6 salía roto, metido en el patio del 4.
  - El 27 lleva `floors: 1` para coger también su franja de una planta del Catastro (0,45 m), que si no salía delante como casa genérica.
  - Bake (en X:, sobre el de Pretil con `cultura`, avisándole): 25 casas nuevas. Calles, nudos, relieve y árboles iguales. Dos clr bajan de 4,5 y 4,7 a 3,9 m, en (-86, 296) y (-76, 301). Cambian las piezas de `extremadura_b441`.
  - `casas`: OK. `petril` (Pretil, sobre el mapa final): OK. Hojas en `guion/fotos/tanda34/cruces_1..5.jpg`.
  - El 12, rehecho tras «Estas no se parecen en nada»: un frente de 9,5 m por la línea de la cochera, que coge sus dos partes del Catastro (`floors: 2`; el porche de debajo del balcón queda detrás). Lleva la pieza nueva `esc` de `casas.gd`: `esc <de> <a> [w=vuelo] [c=barandilla]` en un piso, una escalera de fuera que sube por la fachada hasta el piso de arriba. Horneado otra vez avisando a Pretil: solo cambia `cruces_12`. `casas solo=cruces_12,cruces_8,cruces_11`: OK.
- **Sin publicar (Texturas, 17/11): calle de Fray Benito Romero, 14 entradas (`fbr_*`; aprobadas: «Visto bueno y siguiente»).** Incluye casas con número de la calle de la Luna y de la Travesía de Valencia que dan a ella (`fbr_l*`, `fbr_v3`).
  - Comparadas con las fotos del Catastro. El 11 y la tapia del 1 no tienen foto: van con Street View 2024.
  - En la acera sur, la calle del mapa pasa ~1 m por encima de los frentes del Catastro. Allí los frentes van por la línea de las paredes que deja el horno (`frente_gen`).
  - Sin hacer: el 6 (su frente del Catastro no cuadra con la foto: da a un ensanche que el mapa no tiene como calle), Flor 1 y Luna 13 (sin frente útil).
  - Bake (en X:, avisando a Pretil): 14 casas nuevas. Calles, nudos, relieve, árboles y clr iguales. En `valencia_31` solo cambia la marca de una pared trasera.
  - `casas`: OK, tras darle zócalo y portón a la tapia (sin piezas no pasaba el mínimo del test). Hojas en `guion/fotos/tanda34/fbr_1..3.jpg`.
- **Sin publicar (Texturas, 17/11): calle de los Huertos, 13 entradas (`huertos_*`; aprobadas: «Visto bueno y siguiente»).** Incluye casas con número del Camino de las Huertas (5b, 7, 9, 15, 17) y de El Cerro (`huertos_c1`, `huertos_c3`) que dan a ella.
  - Comparadas con las fotos del Catastro. El 12, con Street View 2024: ya no es blanco con zócalo azul, está pintado de amarillo sobre zócalo rojo oscuro.
  - El 5 A va por la cara de su bloque de dos plantas, con `strip: 1.0` para quitar el escalón de una planta que el Catastro dibuja delante.
  - Sin hacer: Tembleque 103, que solo roza la calle (1 m).
  - Bake (en X:, avisando a Pretil): 13 casas nuevas. Calles, nudos, relieve, árboles y clr iguales. `santo_65` baja 7 cm de base y una pared suya queda a la vista sobre el 12.
  - `casas`: OK. Hojas en `guion/fotos/tanda34/huertos_1..3.jpg`.
- **Sin publicar (Texturas, 17/11): calle de las Cigueras, 5 entradas (`cig_*`; aprobadas: «Visto bueno»).** Con esto la calle queda entera.
  - Comparadas con las fotos del Catastro y con Street View 2024.
  - Dos bloques de pisos. En el de cuatro plantas (`cig_b236`), `strip: 1.0` quita la tira de una planta que el Catastro dibuja delante. El de la esquina con Portugal (`cig_b242`) va con `floors: 2`, para coger su tira de balcones en L, que si no salía delante como casa genérica.
  - El 4 va en dos: la casa de tres plantas (`cig_4`, `floors: 3` y `strip`) y su tapia larga de una planta (`cig_4p`, `only: 1`).
  - Bake (en X:, avisando a Pretil): 5 casas nuevas. Nada más cambia.
  - `casas`: OK (esperando a que el `cultura.gd` de Pretil volviera a compilar). Hoja en `guion/fotos/tanda34/cigueras_1.jpg`.
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
