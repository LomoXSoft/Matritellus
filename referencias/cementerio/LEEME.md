# El cementerio

Luis, 25/11/2026: «Vamos a poner las con el cementerio». Para llegar, eligió un cambio de zona como el de Borderlands 2: «que te acerques al cambio de zona y que un botón te transporte a la siguiente. Así podremos meter zonas fuera del pueblo sin ampliar el mapa». Y se puede ir «a pie y en coche».

**Aprobado.** Luis, 25/11, al ver las vistas (`guion/fotos/cementerio/cementerio_01_vistas.jpg`): «Bien», con tres respuestas:
- «no hace falta que ponga Madridejos a la hora de volver. Con que ponga Núcleo Urbano me basta. Así distinguimos distintas zonas que siguen siendo Madridejos»;
- el azafrán: «Bien, ponlo en los dos»;
- el horario: «Abierto 24 horas. De noche quita la música chill que tenemos y deja solo el leve sonido del viento de vez en cuando. Que dé algo de mal rollo».

## El cambio de zona (`zonas.gd`)

- **Dónde.** El cementerio real está al norte del pueblo, por la carretera vieja de Madrid a Cádiz, pasado el borde norte del mapa. No se amplía el mapa: hay una «zona» aparte.
  - La zona es un círculo del plano con centro en el medio del cementerio, (491.9, −2439.7), y 210 m de radio, con su propio suelo. Lo cierra una pared invisible redonda (72 cajas), unos 14 m más allá de la puerta de zona, para que nadie se salga del mapa. Luis: «un círculo invisible con centro en el cementerio y que llegase poco más lejos que las puertas de zona».
  - `limite.gd` no cuenta como fuera del mapa estar dentro de una zona (`in_zone`).
- **Las dos puertas.** Son dos arcos de acero sobre la carretera, con un cartel oscuro y una cortina que brilla.
  - La del pueblo está al final de la carretera vieja, en (289.9, −1806), y dice CEMENTERIO.
  - La de la zona está en (363.1, −2292), en la misma carretera, y dice NÚCLEO URBANO. Así se distinguen las zonas, que siguen siendo Madridejos.
  - Entre las dos se ve la carretera pintada sobre el llano, con su raya del centro y las de los bordes.
  - El campo tiene vida (Luis: «El suelo está muy plano y vacío. No había cambiado como se hace para que salgan malas hierba/arbustos/arboles sueltos de vez en cuando y darle más vida?»).
    - Las matas del pueblo (`matojos.gd`) solo salen cerca de las manzanas de casas, y la zona está a 450 m de la última, así que allí no salía nada.
    - `zonas._scrub()` siembra la zona con las mismas matas de hierba seca, matas secas y arbustos verdigrises, en las mismas manchas sueltas. Salen más espesas en las cunetas y al pie de la tapia.
    - De vez en cuando sale un olivo, un almendro o un grupo de pinos piñoneros, como alrededor del pueblo.
    - No se quedan en el círculo, para que no se vea el borde: las matas llegan 200 m más allá (lo que se ven desde la pared con la distancia de dibujo más larga) y los árboles, más espaciados, hasta 1400 m del centro.
    - Nunca salen en la carretera, junto a las puertas, dentro del mapa ni en lo que es del cementerio (`cementerio.keep_off`: la tapia y lo de dentro, la plazoleta, la isleta, la acera y, para los árboles, la franja de delante hasta la fila de árboles del otro lado de la carretera).
    - Los árboles son del mundo, como los del pueblo: sólidos, se caen si los atropellas con el coche y vuelven al día siguiente. Salen siempre los mismos.
    - Con `--sin-matojos` no se ponen, igual que las del pueblo.
  - La carretera no se corta en el cementerio: sigue recta hacia el norte, por fuera del círculo, hasta donde acaba de verdad, en (462.9, −2955), 515 m al norte del centro, donde salen los ramales de la A-4 (OpenStreetMap). Luis: «la carretera en el cementerio se corta muy pronto y se nota mucho que es una zona aparte». Solo se ve; la pared redonda no deja seguir por ella.
  - A lo largo de ella siguen las farolas (cada 30 m, en su lado), la fila de árboles del otro lado (cada 18 m, hasta z −2700 al norte, como en la ortofoto del PNOA, y hacia el sur hasta el pueblo) y la acera clara con su bordillo rojo y blanco, hasta poco antes del final al norte y hasta la puerta del pueblo al sur (`cementerio._roadside()`). Luis: «la acera, los pinos y las farolas se cortan donde se cortaba antes la carretera». Van por la línea de la carretera y no por la del cementerio (las dos se separan un tercio de grado), y se cortan en las puertas de zona.
  - **La A-4** (`autovia.gd`; Luis: «hacia el norte/oeste podríamos ver la autovía A4 uniéndose a la carretera, con .PNG de coches y camiones viajando»):
    - por donde va de verdad (OpenStreetMap, `tools/cementerio/autovia.py` → `godot/data/autovia.json`): sus dos calzadas a 45–60 m de la tapia este, dentro del círculo, y hacia el norte hasta el horizonte. Al final de la carretera vieja, un lazo te sube a la calzada hacia el sur y un ramal baja a ella el tráfico que viene del norte;
    - dos carriles y arcenes por sentido, líneas blancas, quitamiedos en la mediana, y la valla de malla del lado del cementerio, que no deja pasar;
    - el tráfico son dibujos (`assets/autovia/trafico.png`): los coches del propio juego en varios colores y cuatro camiones hechos con piezas (tráiler de caja, de lona, cisterna y rígido: el kit solo trae pickups), vistos desde 16 lados, que se giran hacia ti y enseñan el lado desde el que los ves. Van a velocidad de autovía guardando la distancia, los camiones solo por el carril de la derecha, y de noche con los faros y los pilotos encendidos (`trafico_luces.png`);
    - solo se ve y se mueve con la cámara dentro de la zona: el mapa del pueblo no tiene la A-4 al norte.
  - **El pueblo a lo lejos** (`lejanias.gd`; Luis: «mirando hacia el sur se podría ver un .PNG del pueblo, parecido a lo que hicimos con el castillo de la muela»):
    - desde la zona el juego dibuja 1600 m alrededor, y el pueblo está a 1,6–4,4 km. Lo de más allá es una foto del propio pueblo hecha desde el centro de la zona, de 1300 m en adelante, de día y de noche (`lejanias_foto.gd`, modo `lejanias`), convertida en una banda alrededor del horizonte por `tools/cementerio/lejanias.py` (`assets/autovia/pueblo_dia_0..3.png` y `pueblo_noche_0..3.png`, un cuarto de vuelta cada una);
    - se pinta detrás de todo lo que dibuja el juego y delante de las sierras, como si estuviera a 2,4 km: al moverte por la zona se desplaza contra el campo como lo haría el pueblo;
    - de día, la foto de mediodía con la luz de la hora; de noche, la de noche, con las ventanas encendidas. Solo dentro de la zona, y no en el Modo Silent Hill.
- **Cómo se usa.**
  - Al acercarte a una puerta, a pie (5 m) o en coche (9 m, parado o despacio), sale el botón «Ir al Cementerio» o «Volver al Núcleo Urbano».
  - Al pulsarlo apareces al otro lado, a 10 m de la otra puerta, de espaldas a ella. Si vas en coche, apareces con el coche.
- **Cuándo no se puede ir.**
  - Con la pasma detrás: estrellas, persecución o la cuenta atrás del borde del mapa. Sale «¡Con la pasma detrás no te vas a ningún lao!».
  - Sale «Ahora no puedes irte de aquí.» en estos casos:
    - en la riña o con el coche en el taller;
    - durante una llamada o un desmayo por comer de más;
    - en cualquier trabajo (reparto, jornal, los pedidos de Henry y de Javi, la carrera de taxi de Koke);
    - en el sabotaje de Don Luis, mientras sigues al camión.
  - Sistemas dio la lista. Con los recados sin reloj (Tomasa, la Pili, el Recress, el menú o el jamón) sí se puede cruzar.
  - En el Modo Chavisca sí se puede ir.

- **La zona en el plano** (`zonas._plan()`; de las ocho cosas del repaso, 25/11). Antes el minimapa salía vacío en la zona.
  - `minimap.gd` (de Sistemas, avisado) tiene solo líneas metidas: `static var extras` y un bucle en `_draw()` que las pinta después de las calles y antes de la ruta, tanto en el minimapa redondo como en el mapa entero.
  - `zonas.setup` la rellena una vez. Lleva la carretera de la zona, la A-4 y sus ramales (solo al norte del borde del mapa), la tapia del cementerio y sus dos paseos, la valla de la planta, sus seguidores y sus dos plantas lejanas, la entrada de la planta y la nave.
  - Cada cosa es `[clase, puntos, medio ancho]`. Las clases 0 a 2 se pintan como las calles del pueblo (asfalto, tierra, senda) y la 3 como el contorno de una manzana. Los puntos van a 30 m como mucho (`_dense()`), porque el minimapa redondo solo pinta los tramos cercanos.
  - El mapa entero sigue encajado en el pueblo: la zona queda por encima de su borde norte. Enseñarla ahí sería cosa de `game.gd` (de Sistemas).

## El cementerio (`cementerio.gd`)

- **Las medidas.** Salen de la ortofoto del PNOA (`tools/ign/cementerio_todo.jpg`, a 0,15 m por píxel) y de Street View de 2024.
  - Las esquinas de fuera de la tapia son NO (430.3, −2534.6), NE (579.6, −2512.0), SE (551.6, −2345.3) y SO (406.0, −2366.8).
  - Los lados miden 151 m (norte), 147 m (sur), 169,5 m (oeste) y 169 m (este). Está girado unos 8,6°.
  - Todo se mide en u (hacia el este, a lo largo de la tapia norte) y v (hacia el sur, a lo largo de la oeste). Para que las cuatro esquinas caigan en su sitio, el paso a coordenadas del plano es bilineal (`P(u, v)`).
- **La tapia.** Es encalada, de 2,4 m, con albardilla gris y el pie sucio por fuera.
- **El pórtico.** Está en la tapia oeste, de v 63 a v 105, y tiene 9,5 m de fondo.
  - Las dos alas tienen tejados a cuatro aguas de teja vieja: el alero a 3,2 m y la cumbrera 1,6 m más arriba. Llevan un zócalo gris.
  - En el centro, el frente levantado tiene un pináculo en cada esquina, a 4,95 m. Entre los dos pináculos va un frontón ancho y bajo, de bordes blancos, hasta 6,1 m.
  - Sobre el frontón hay un tejadillo de teja de tres caras, como media pirámide, que sale medio metro de la pared. Arriba van un remate de ladrillo y la cruz de hierro.
  - La ventana estrecha en arco está 1,4 m al sur del centro, y bajo ella, el banco de piedra blanca.
  - Primero hice un cuerpo saliente con un frontón estrecho. Al compararlo con Street View 2024 a tamaño completo, lo cambié por el frontón ancho, que es lo que se ve.
  - A cada lado del frente levantado hay un arco. Los dos son huecos de verdad con su medio punto (Luis, 25/11: «sale el hueco de entrada rectangular y luego clippeado un arco»): antes el hueco era rectangular y el arco, una cara fina pegada delante.
    - el del norte está cerrado con una reja; su vano oscuro queda 45 cm metido en el muro, bajo su bóveda (`SHUT_R`, `SHUT_SPRING`, `SHUT_DEEP`);
    - el del sur está abierto: es la entrada a pie, de 1,5 m, y un coche no cabe. El pasadizo es una bóveda de medio punto de lado a lado (`_vault()`, con normales suaves), y por dentro del cementerio sale con el mismo arco. El techo sólido baja a 2,3 m, para que la cámara del juego se quede bajo la bóveda.
  - Tiene cuatro ventanas con reja y, por dentro, dos puertas de madera.
  - Los tejados son de teja vieja, gris y parda.
  - Al norte, detrás de la tapia, hay un almacén bajo.
- **Delante, la plazoleta.**
  - Adoquines grises desde la carretera hasta el pórtico.
  - Una isleta en forma de D, con su lado recto a la carretera, que lleva:
    - bordillo rojo y blanco y tierra;
    - enebros, matas y arbustos rojizos de otoño;
    - dos cipreses, un árbol detrás de la señal y la señal de dirección prohibida.
  - Delante del centro de la isleta no hay ciprés, y desde la carretera se ve el pórtico como en la foto.
  - Al sur, una acera de baldosa clara a lo largo de la carretera.
  - Contra la tapia, el armario de la luz.
  - Seis farolas con el brazo curvo sobre la carretera.
- **Dentro.**
  - Suelo de grava, con el paseo de losetas que sale del pórtico hacia el este, entre cipreses.
  - La avenida ancha de en medio, de u 76,5 a u 97, con 16 panteones de familia sacados de la ortofoto:
    - capillas de granito con frontón, cruz y puerta de hierro;
    - recintos con verja;
    - losas altas.
  - Las tumbas, 4532, en 58 cuadros (ocho columnas y ocho filas):
    - van en parejas de filas espalda con espalda, con un pasillo de 1 m entre pareja y pareja (el jugador mide 0,76 m de ancho);
    - son de mármol blanco casi todas, también de granito gris o negro y alguna crema;
    - tienen lápida, libro abierto o cruz alta, y muchas un jarrón con flores;
    - **no llevan nombres ni fechas**: la mitad lleva grabado «R.I.P.» o «D.E.P.» y nada más (ver «Los retoques»).
  - El cuadro del sureste, más vacío, está a medio llenar.
  - Fuera de la tapia oeste hay cipreses pequeños, y al otro lado de la carretera, árboles anchos.

## La planta solar de enfrente (`planta_solar.gd`)

- **Qué es.** Luis, 25/11, con una captura de Street View de su puerta: «En frente del cementerio hay una planta solar. Estaría bien añadirla también». Está al oeste de la carretera, frente al cementerio. La crea `zonas.setup` si la zona lleva `"solar": true` (`zonas.solares`).
- **Las medidas.** Salen del PNOA (`tools/ign/cementerio_solar.jpg`, a 0,25 m por píxel, y `cementerio_solar_oeste.jpg`, entera) y de Street View de 2024 para la puerta. Todo va en coordenadas del plano.
  - El recinto es una cuña de 330 m entre campos, que llega a la carretera por un cuello con la puerta en su extremo sur (`FENCE`, `GATE_S`, `GATE_N`).
  - La valla es de malla sobre postes finos, de 1,8 m (el mismo shader de malla que la de la A-4). Es sólida donde el círculo de la zona deja llegar a ella. No se entra.
  - La puerta es ancha y baja, de tubo y malla entre dos postes, con el cartel blanco en su mitad sur. Dice **«PLANTA INDUSTRIAL» en azul y «AGROSOLAR» en rojo**: el nombre es de Luis (25/11: «Y el cartel "Planta Industrial Agrosolar"»), en las dos líneas y los colores del de verdad, sin su letra pequeña (`SIGN`).
  - Detrás de la puerta hay una caseta blanca. Hay chatarra junto al lado norte del cuello y el lado este (palés, bidones, sacas, chapas) y un coche blanco viejo (`Modelos.make_from`, solo el modelo).
  - La entrada es de tierra pisada, de la carretera a la puerta. `cementerio._roadside()` no planta ningún árbol de la fila en ella (`SolarS.DRIVE`).
- **Los seguidores.** Son 28, en siete filas de cuatro (`TRACKERS`, uno por uno del PNOA). Cada uno es una mesa de 16 × 13 m (seis filas de módulos con una rendija entre cada dos) sobre un mástil de acero de 6,5 m con pie redondo de hormigón.
  - Las mesas son una sola malla en un MultiMesh; los mástiles van en la malla del sitio.
  - **Siguen al sol** (lo puse por mi cuenta y Luis lo confirmó el 25/11: «Los seguidores déjalos que sigan al sol»), todas a la vez (`track()`, desde `zonas.tick`): miran a `game.sun` y se inclinan de 8° a 55°. De noche se quedan casi planas (12°), ya vueltas hacia donde sale. Giran como mucho a 5° por segundo: al anochecer se las ve volverse todas al este. `track(true)` las pone de golpe (para las fotos).
  - En la ortofoto todas miran al suroeste: el sol de la tarde.
- **El campo.** Las matas de la zona crecen también dentro, menos en la entrada, la caseta, el coche y el pie de cada seguidor (`keep_off(false)`); ningún árbol suelto dentro (`keep_off(true)`).
- **Las plantas de paneles fijos** (`_farms()`, `FARMS`). Son las dos grandes que hay pasado el camino, al oeste y al noroeste, medidas del PNOA (`tools/ign/cementerio_fijas.jpg`, a 1 m por píxel).
  - Son filas de mesas bajas de este a oeste, inclinadas 28° al sur, una fila cada 6,5 m por todo el contorno de cada planta.
  - Se ven a lo lejos detrás de los seguidores, a 250 m o más de donde se puede andar. Por eso van en una sola malla, sin patas y sin sombras.
  - Ningún árbol suelto crece en ellas (`keep_off(true)` las incluye).

## Las ocho cosas del repaso (25/11)

Luis pidió un repaso («Daría un repaso por si hay alguna propuesta o mejora posible»), le propuse ocho cosas y contestó: «Haz las 8. Y el cartel "Planta Industrial Agrosolar"». Están hechas todas y **aprobadas el 25/11** («Muy buena pinta todo. Solo unos retoques [...] Por lo demás visto bueno»), con los retoques de más abajo:

1. **Azafrán escondido en la planta** (`planta_solar_puerta`): ver «Azafrán».
2. **Velas en las tumbas.** Yo propuse lamparillas y Luis corrigió, con dos fotos: «cambiaría lamparillas por velas, que son las que se suelen poner». Son las velas de cementerio: tubos altos de plástico rojo con la cera blanca en la boca.
   - Hay de una a tres al pie de una tumba de cada siete, unas enteras (24 cm) y otras más gastadas (16 cm). Van en los MultiMesh de las tumbas (`candle` y `wax`).
   - Qué tumbas las llevan sale de dónde está cada tumba, no del generador de azar: todo lo demás de las tumbas queda como estaba (también el jarrón del azafrán).
   - De noche brillan (`_candle_glow()`, nodo `velas`): un punto rojo que parpadea sobre cada una, cada una a su ritmo. No son luces del juego: es un MultiMesh de cuadros que suman su color y miran siempre a la cámara. De lejos el punto conserva su tamaño en pantalla (hasta 6 veces), así que desde la carretera el cementerio se ve salpicado de ellas. De día no se dibuja (`cementerio.tick()`, desde `zonas.tick`).
3. **La zona en el minimapa** (`zonas._plan()` y `minimap.gd`): ver «El cambio de zona».
4. **La nave blanca** junto a la puerta de zona (`afueras.gd`): ver «Las afueras».
5. **Las plantas de paneles fijos**: arriba.
6. **El rumor de la A-4** (`autovia.gd`, `_tick_hum()` y `hum_level()`).
   - Suena de día dentro de la zona, más fuerte cuanto más cerca de las calzadas: de −13 dB junto a su valla a −30 dB a 340 m. La A-4 pasa a unos 30 m de la tapia este del cementerio.
   - **De noche sigue sonando, mucho más bajo**: 16 dB menos que de día (`HUM_NIGHT`), por debajo de las ráfagas de viento. Yo lo había dejado callado de noche, para que la noche fuera solo del viento, y Luis lo corrigió: «Dejar el rumor de la autovía por la noche, pero mucho más bajo».
   - El bucle (`godot/assets/autovia/rumor.wav`, 16 s) lo hace `tools/cementerio/rumor.py` con ruido al que se le da forma en frecuencia, sin grabaciones de nadie. Su final empalma con su principio. Después de rehacerlo hay que importar.
   - Va por el bus `SFX` y se para con la pausa y con el mapa abierto.
7. **Los carteles azules de la A-4** (`afueras.gd`): ver «Las afueras».
8. **Troncos encalados** (`cementerio._whitewash()`, nodo `troncos_encalados`): cada árbol de la fila del otro lado de la carretera lleva una funda blanca de cal hasta 1,1 m, como en Street View 2024.
   - Es un MultiMesh sobre los troncos que dibuja el mundo. Si un coche tumba el árbol, su cal se va con él y vuelve con él (`tick()` mira `tree_info[i]["down"]`).

## Los retoques (25/11)

Con el visto bueno de las ocho cosas, Luis pidió cuatro retoques. Están hechos y **aprobados el 25/11** («Déjalos. Creo que no queda nada. Visto bueno»). Los dos carteles que añadí por mi cuenta, «TALLER OFICIAL» y «CHAPA Y PINTURA», se quedan:

1. **«R.I.P.» y «D.E.P.» en las lápidas** («Poner R.I.P y D.E.P grabado en algunas lápidas (50% de todas ellas)»).
   - Una tumba de cada dos lleva una de las dos palabras, mitad y mitad. Sigue sin haber nombres ni fechas.
   - Va grabada en la lápida de pie, en su cara que mira a los pies de la tumba. Si la tumba no tiene lápida de pie (libro o cruz), va tumbada en la losa, para leerla desde los pies.
   - Letras oscuras en piedra clara y doradas en piedra oscura; miden 9 cm de alto.
   - Qué tumbas la llevan sale de dónde está cada una, como las velas: lo demás de las tumbas no cambia.
   - Son dos dibujos (`godot/assets/cementerio/lapida_rip.png` y `lapida_dep.png`, 256 × 72) que hace `tools/cementerio/lapidas.py` con la letra que trae Pillow (Aileron, CC0). Después de rehacerlos hay que importar. Van en los MultiMesh de las tumbas (`rip` y `dep`) y se dibujan hasta 70 m.
2. **El rumor de la A-4 de noche**, mucho más bajo: ver el punto 6 de arriba.
3. **La nave es el taller «Recoveco»** y funciona como los del pueblo: ver «Las afueras».
4. **Los seguidores siguen al sol**: se quedan como estaban.

## Las afueras (`afueras.gd`)

Lo crea `zonas.setup` si la zona lleva `"afueras": true` (`zonas.afueras`), después de la A-4. Va sobre `obra.gd`, en coordenadas del plano.

- **La nave blanca.** Es un taller de camiones al oeste de la carretera, justo al norte de la puerta de zona. Mide 51 m de frente por 27,5 de fondo (PNOA: `tools/ign/cementerio_nave.jpg`, a 0,125 m por píxel; Street View 2024 desde la carretera, sin guardar ninguna foto).
  - Son dos bloques blancos con un mismo frente (`NAVE_S`, `NAVE_N`): el del sur, más bajo (8,3 m), con tejado azul de franjas claras y cuatro portones enrollables cerrados; el del norte, más alto (9,9 m), con tejado blanco, tres huecos abiertos y el portón del taller (ver abajo).
  - Los tres huecos abiertos dan a una sala de verdad de 7 m de fondo, con dos pilares delante: tiene el foso, un banco de trabajo, un armario rojo, bidones y pilas de neumáticos. Se entra andando.
  - **Se llama «Recoveco»**: el nombre es de Luis (25/11: «en vez de Iveco llamarla Recoveco»). Lo lleva en letras azules grandes en lo alto del bloque bajo, donde la de verdad lleva la marca de su fabricante, con letra nuestra (`NAME`). Además lleva un cartel azul «TALLER OFICIAL» entre el tercer y el cuarto portón, y otro «CHAPA Y PINTURA» sobre el portón que funciona.
  - **Es un taller como los cuatro del pueblo** (`_workshop()`, `taller`): el portón al norte de los huecos abiertos (`SHOP`) sube cuando llegas, a pie o al volante. Dentro hay un hueco de 9 m de fondo con la llave girando donde va el coche. Paras dentro, te dicen el precio, pitas, baja la persiana, lo arreglan y lo pintan, y entonces se cobra.
    - El hueco, la persiana y los trastos son los de `garage.gd` (el mismo script de los talleres del pueblo), metidos en un agujero del bloque norte.
    - **No está en `game.garages` ni en `props.repairs`**, a propósito. Los de esas listas están todos dentro del mapa: la grúa lleva los coches al más cercano, y las pruebas del borde y del relieve los cuentan (suelo llano, a 150 m del borde). Este está fuera del mapa.
    - Por eso `afueras.tick()` (desde `zonas.tick`) hace por él lo que `game.gd` hace por los otros: mueve la persiana y, con el coche parado dentro, dice el precio una vez y pone `game.at_shop` y `game.at_garage`. A partir de ahí el aviso, el pitido, la reparación, la pintura y el cobro son los de `game.gd`, sin tocar ese archivo.
    - `game.gd` borra esos dos valores cada vez que conduce el coche (no encuentra taller suyo allí), y `zonas.tick` va después: por eso hay que ponerlos en cada momento.
    - Arreglado un coche, no se ofrece nada más hasta que sale del hueco.
    - Lo que no hace: el aviso «Mételo pa dentro» en la puerta con el coche abollado (sale de la lista de `game.gd`), el cuadro azul en el minimapa y la luz de la puerta de noche. Son de Sistemas, si se quieren.
  - Delante hay una solera de hormigón de 9,5 m y tierra pisada hasta la carretera. `cementerio._roadside()` no planta árboles de la fila delante de ella.
  - La mitad norte cae dentro del círculo de la zona: se llega andando hasta ella. Todo es sólido.
- **Los carteles** (`_board()`, `_km_sign()`):
  - Uno azul en la carretera vieja antes del enlace, en el lado del cementerio, pasada la acera (`SIGN_Z`): la A-4 a Madrid de frente y a Córdoba a la derecha. El ramal del enlace solo entra en la calzada que va al sur (OSM).
  - El mismo cartel otra vez en el propio enlace, que se ve de lejos.
  - En la A-4, a la derecha de la calzada sur y pasado el ramal (`KM_Z`), el cartel alto de distancias: Puerto Lápice 18, Manzanares 57, Córdoba 283. Queda detrás de la valla, al este del cementerio: no se llega a él.
- Las matas y los árboles de la zona no crecen en la nave, en su explanada ni al pie del cartel (`keep_off`).

## De noche

- Dentro de la zona, de noche (`moment == "night"`, de 21:30 a 6:30), no suena la música de ir a pie (el lofi), ni los grillos ni los perros del pueblo. Se oye el viento de vez en cuando, y muy bajo el rumor de la A-4: una ráfaga baja cada 8 a 24 segundos (`zonas.hush()` y `_tick_wind()`).
  - La radio del coche, si la pones, sigue sonando.
  - En `game.gd` (`_update_audio`) van dos líneas, con el OK de Sistemas.
- Las ráfagas son tres (`godot/assets/cementerio/viento_0..2.wav`), de 7,5 a 11,5 s. Las hace `tools/cementerio/viento.py` con ruido marrón y un filtro que se mueve despacio: aúlla grave y bajo, sin grabaciones de nadie. Después de rehacerlas hay que importar.

## Azafrán

**En la planta solar hay un tercero** (`planta_solar_puerta`, `planta_solar._saffron()`), de las ocho cosas del repaso: está al pie del poste sur de la puerta, por fuera, entre matas de hierba seca (las mismas de los campos). Se coge desde el arcén. La flor va al 70 %.

En el cementerio hay dos azafranes escondidos. Los propuse y Luis dijo «Bien, ponlo en los dos». Cada uno cuenta una vez por partida, como los demás (`game.flowers`, `hidden`; Sistemas lleva la cuenta). Los pone `_saffron()`:
- **`cementerio_tumba`**: en el jarrón de una tumba del rincón sureste, en lugar de sus flores de tela, perdido entre las demás.
  - Es la tumba del final de su fila más cercana a u 139, v 156, con el jarrón del lado de fuera, así que se coge desde el paseo de al lado.
  - La flor va al 55 %.
- **`cementerio_cipres`**: al pie del ciprés de tronco encalado que hay delante del pórtico, al sur del arco abierto, por el lado de la tapia y bajo sus ramas más bajas.
  - El tronco va encalado hasta 0,9 m, como en Street View 2024.
  - La flor va al 70 %.
- `_cementerio_checks()` comprueba que los dos están en el juego como escondidos y que hay sitio para ponerse al lado y cogerlos. El modo `--cementerio` saca `cementerio_azafran_tumba` y `cementerio_azafran_cipres`.

## Lo que queda fuera

- El paso de cebra de la carretera y las naves y olivares de alrededor (los de más de 1300 m salen en la foto del pueblo).
- El horario real (cierra de una a cuatro): Luis lo quiere abierto las 24 horas.

## Scripts y prueba

- `godot/scripts/zonas.gd` (`game.zonas`) y `godot/scripts/cementerio.gd` (`world.cementerio`, sobre `obra.gd`).
- `godot/scripts/planta_solar.gd` (la planta solar, `zonas.solares`, sobre `obra.gd`).
- `godot/scripts/afueras.gd` (la nave blanca y los carteles de la A-4, `zonas.afueras`, sobre `obra.gd`).
- `tools/cementerio/rumor.py` (el rumor de la A-4) y `tools/cementerio/lapidas.py` (las palabras de las lápidas).
- `godot/scripts/autovia.gd` (la A-4, `zonas.autovias`), `godot/scripts/lejanias.gd` (la foto del pueblo, `zonas.lejos`) y `godot/scripts/lejanias_foto.gd` (hace los dibujos).
- Para rehacer los dibujos (si cambian los coches o el pueblo): `python tools/run_tests.py lejanias`, luego `python tools/cementerio/lejanias.py <la carpeta que dice el log>` y luego importar (`--headless --path godot --import`).
- Líneas metidas en `game.gd` (con el visto bueno de Sistemas), `limite.gd`, `loc.gd`, `world.gd` y `selftest.gd`.
- Sin ventana, como la prueba completa: `python tools/run_tests.py zonas sinfotos --headless` y `python tools/run_tests.py cementerio sinfotos --headless` (sin fotos, un minuto cada una).
  - Sin ventana el motor devuelve cada instancia de un MultiMesh sin mover. Por eso las comprobaciones de las matas, de la planta solar y de las palabras de las lápidas leen el registro que guarda el script: meta `"ps"` en cada celda de matas (`zonas.gd`) y meta `"xf"` en los MultiMesh `tumbas_rip_*` / `tumbas_dep_*` (`cementerio.gd`).
  - Con ventana se le pregunta además al motor.
- `python tools/run_tests.py zonas`:
  - pasa `_zonas_checks()`. Comprueba:
    - ir y volver a pie y en coche;
    - el coche apoyado en el suelo de la zona igual que en el pueblo;
    - que no deja cruzar con la pasma, la detención, el desmayo, un trabajo o el seguimiento de Don Luis, y que sí deja con un recado sin reloj y en el Modo Chavisca;
    - que el campo tiene matas y árboles sueltos dentro y fuera del círculo, y ninguno en la carretera, junto a las puertas, en el mapa o en lo del cementerio;
    - la pared redonda de la zona (16 rayos alrededor y 2 por la carretera, en los dos sentidos), que pase poco más allá de la puerta de zona, y las cortinas;
    - que la A-4 empalma con el final de la carretera, que la valla para antes de llegar a ella, que solo se ve desde la zona, que lleva coches y camiones sin salirse de su carril y que la foto del pueblo está puesta;
    - las ocho cosas del repaso: el cartel con su nombre; el azafrán de la planta en la lista de escondidos y con sitio para cogerlo; las velas, que brillan de noche y no de día; el rumor de la A-4 de día (más fuerte en la puerta del cementerio que en la de la planta) y callado de noche; los troncos encalados; los tres carteles; la nave con el frente sólido, la sala abierta y sin árboles delante; las filas de paneles fijos; y la carretera y la tapia en el plano;
    - los retoques (`_recoveco_checks()`): las palabras en la mitad de las tumbas, repartidas entre las dos y todas dibujadas; y el taller Recoveco, entrando con un coche como en los del pueblo: persiana bajada sin nadie, arriba al llegar, precio y pitido dentro, persiana abajo, arreglado, pintado y cobrado, y arriba otra vez sin volver a ofrecer nada;
    - la planta solar: 28 seguidores, de cara al sol a mediodía, al este por la mañana, al oeste por la tarde y planos de noche; la valla sólida y la puerta cerrada (un rayo desde la carretera); matas dentro pero ninguna en la entrada ni al pie de un seguidor; ningún árbol suelto dentro ni de la fila en la entrada;
  - saca las puertas de día y de noche, y la vista atrás hacia el pueblo.
- `python tools/run_tests.py cementerio`:
  - pasa `_cementerio_checks()`, que va también en la prueba completa. Comprueba:
    - que está hecho, con más de 3000 tumbas, y dentro de su zona;
    - que la tapia para a quien choca por los cuatro lados;
    - que a pie se entra por el arco abierto y su pasillo, que el coche no cabe y que el otro arco está cerrado;
    - que las tumbas son sólidas y los pasillos entre ellas y los paseos quedan libres;
    - que ningún cuadro pisa un paseo, que ningún árbol pisa la carretera y que hay sitio para aparcar delante;
    - que el jugador, con sus piernas y su cuerpo, entra por el arco hasta el paseo de cipreses y recorre un pasillo entre tumbas en el rincón del sureste;
  - saca:
    - las vistas desde las cámaras de Street View, con su mismo rumbo y ángulo, y una de noche;
    - vistas de dentro y desde arriba;
    - tres con la cámara del juego y el HUD: ante el arco, en el pasadizo y al llegar a la zona;
    - dos de la carretera que sigue al norte (`cementerio_norte`, `cementerio_norte_alto`);
    - tres del campo (`cementerio_campo_oeste`, `cementerio_campo_este`, `cementerio_campo_alto`);
    - los arcos: `cementerio_arco_sesgo`, `cementerio_arco_boveda` y `cementerio_arco_dentro`;
    - las ocho cosas del repaso, todas con `cementerio_ocho_` delante: `cartel`, `azafran`, `troncos`, `velas`, `nave`, `nave_llegada`, `nave_taller`, `nave_dentro`, `nave_alto`, `cartel_a4`, `cartel_km`, `fijas`, `fijas_alto`; de noche `velas_noche`, `velas_paseo`, `velas_tumbas` y `velas_alto`; y con el HUD puesto `minimapa`, `minimapa_planta` y `minimapa_nave`;
    - los retoques, con `cementerio_retoque_` delante: `lapida` (de pie), `lapida_losa`, `lapidas_fila`, `lapidas_paseo`, `nave`, `nave_nombre`, `taller_cerrado`, `taller_abierto` (con un coche dentro) y `taller_dentro`;
    - la planta solar: `cementerio_solar` (desde donde la foto de Luis), `_solar_puerta`, `_solar_alto`, `_solar_seguidor`, `_solar_desde_cementerio`, y `solar` también por la mañana (`_manana`), al atardecer (`_tarde`) y de noche (`_noche`);
    - la A-4 y el pueblo: `cementerio_autovia` (desde la valla), `cementerio_enlace` (hacia el final de la carretera), `cementerio_autovia_alto`, `cementerio_pueblo`, `cementerio_pueblo_alto`, y `autovia` y `pueblo` también al atardecer (`_tarde`) y de noche (`_noche`).
- Capturas del juego en `guion/fotos/cementerio/`. Las fotos de Street View no se guardan en el repositorio.
