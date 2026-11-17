# Estado del proyecto

Resumen corto para las sesiones que trabajan en Matritellus. Lo largo (carpetas, publicación, quién toca qué) está en `README.md`. Actualízalo al cerrar un trabajo.

## Sin publicar

El detalle de cada pieza está en su LEEME de `referencias/` o `tools/`, en `guion/` y en el historial de git.

- **Creador (17/11): la criba de peinados, primera tanda** («Pásame capturas de un personaje básico con cada peinado en marrón. Voy a hacer criba»). **Visto bueno del usuario (17/11), por Sistemas: «Visto bueno a todo lo pendiente y paramos».** La criba sigue abierta para más adelante (ropa, sombreros y lo que quiera quitar).
  - Moño (1) más grande. Cresta (6) con pinchos en lugar de bolas y los lados rasurados con el gris del Rasurao. Los vecinos que los llevan cambian con ellos: La Chiki, Josefa y la madre del alcalde (moño) y Kevin (cresta).
  - Rapao (3) fuera del creador (`Creator.RETIRED`); una partida con él pasa al Rasurao (33). Los vecinos que lo llevan siguen igual, como pidió Sistemas: Nocturno Correa, el Niño Negro Gordo de Pueblo y Katakumba69.
  - Nombres nuevos: Dos coletas → «Ensaimadas» (en: Side buns), Calvo por arriba → «Degradado Inverso» (Reverse fade), Rapao a máquina → «Tazón» (Bowl cut).
  - Tupé (8) rehecho por la foto del usuario («Ahora mismo es solo una bola, debería ser algo como la foto»): un tupé alto peinado hacia arriba y atrás, hecho desde cero con Blender (`tools/creador/tupe.py` → `assets/creador/pelo/pelo_tupe.glb`; ningún modelo libre lo tenía), con los lados y la nuca en degradado del color del pelo (`chara._degradado`). Con gorra o sombrero, solo el degradado. Lo llevan Kebab Luis y el comentarista del Recress.
  - Fotos para la criba: modo `criba_pelo` (`solo=8,13` para sacar solo esos; personaje básico, pelo marrón, cada peinado de frente, de lado y de espalda, sin tráfico y esperando a que la pantalla esté clara). Ficheros: `chara.gd`, `creator.gd`, `loc.gd`, `selftest.gd`. `creador` 19/19.

- **Sistemas (16/11): cartas desde Correa** («Nueva mecánica: Envío de cartas»). Aprobado el 17/11 con todo lo pendiente: «Visto bueno a todo lo pendiente y paramos. Que quiero hacer un release pronto».
  - Correa abre de 8:00 a 20:00, de lunes a viernes (cambiado en `correos.gd` con el visto bueno de Pretil; él rehízo la placa del horario). Tras la primera ventanilla, **Diurno Correa** de 8 a 14 y **Nocturno Correa** de 14 a 20 (nombres provisionales del usuario). Son mayores y funcionarios; el Diurno es alegre y el Nocturno, malhablado, chulesco y vacilón. Sus frases se rehicieron el 16/11 a petición del usuario: «más malhablados y con un comportamiento chulesco y vacilón, sin miedo a decir palabras fuertes».
  - Al hablarles sale la burbuja: Hablar, Enviar una carta y Salir. Hablar cuenta sus seis batallitas de la mili, las mismas en los dos y cada uno a su manera (`mili_<k>_<diurno|nocturno>`).
  - Enviar abre la hoja de la carta: «Para:» con los vecinos con nombre que conoces, texto libre de hasta 400 letras, «Firmao:» con tu nombre del Padrón (en una partida de antes del Padrón, sin nombre, sale primero la hoja del Padrón y luego la carta), Enviar y Volver, y cae el sello «CORREA». Con mando sale un teclado en pantalla; LB/RB cambian el destinatario, B borra y Start envía. Solo una carta al día.
  - Al día siguiente, entre las 10 y las 20, el destinatario te llama: +5 de confianza si la carta era amable, +3 si no era ni amable ni mala y -3 si era mala. Cada vecino tiene dos llamadas buenas y dos malas (`carta_bien_<id>`, `carta_mal_<id>`, 26 vecinos), más dos de cada para el resto del pueblo (`carta_*_x`).
  - Amable o no se decide por las palabras (`cartas.gd judge`): una lista de palabras y frases buenas y otra de malas, con los insultos del pueblo de `palabros.md`. Un «no» justo antes le da la vuelta. Si la carta no tiene ni de unas ni de otras, o tiene igual de las dos, es una carta normal: +3 y una llamada amable (el usuario: «No kind as +3»).
  - Un detalle a revisar: en una llamada mala de la Maruja, ella insinúa que el jugador nació antes de la boda de sus padres («tempranillo»).
  - También: los dos en la gacha y en el árbol de relaciones; mientras sale la burbuja de respuestas o la hoja de la carta, el jugador ya no anda (antes, con W se movía a la vez que la mano).
  - Ficheros: `cartas.gd` (nuevo), `game.gd`, `touch.gd`, `loc.gd`, `gacha.gd`, `correos.gd`, `selftest.gd` (modo `cartas`, también en la completa) y `guion/relaciones.json`. `cartas` 17/17.

- **Sistemas (16/11): las respuestas de una charla, en una burbuja sobre el diálogo** («Las opciones de diálogo (no las de misión, sino como las del alcalde…) no necesitan poner todo el zócalo para sacarlas. Basta con una burbuja encima del diálogo. Tipo animal crossing»). Veredicto: «Looks pretty dope» (16/11).
  - Lo que te pregunta queda en el cuadro de diálogo y las respuestas salen en una burbuja amarilla sobre su esquina derecha, con una mano en la elegida. Arriba y abajo la mueven, aceptar o interactuar la toma; también con el ratón (se suelta mientras dura) o con el dedo. La que no se puede tomar (sin dinero) sale en gris.
  - Son: la pregunta del alcalde («Usted pensará que estoy loco, ¿verdad?»), la cuenta del Fonsi y su revancha, el combate en la trastienda, el mostrador de Don Luis y el de Henry, y La Chiki. Cada uno dice ahora su pregunta en voz alta (`ask_*` en `loc.gd`).
  - Las ofertas de misión (aceptar/rechazar, Sí/No del teléfono, la apuesta del Recress) y los menús del ajedrez (nivel, color, coronar, la partida a medias) siguen en la tarjeta.
  - `game.gd` (`ask`, `_ask_pick`, `_ask_move`; `_choose` pasa a la burbuja si está abierta), `hud.gd` (`show_answers`, `set_answer`, `hide_answers`), `touch.gd`, `entradas.gd`, `pintadas.gd`, `ajedrez_humano.gd`, `selftest.gd`.

- **Pretil (17/11): el Merkocarry (el Merkocash de Santa Ana 60), a mano y con rehorneado, con su aparcamiento hasta Magallanes** (`merkocarry.gd`, `world.merkocarry`). Veredicto, con la nave de la Mayordomía: «Visto bueno, está bastante bien» (17/11). Hojas en `guion/fotos/merkocarry/`.
  - Sobre la parcela 4790703 del Catastro, salvo la esquina del Cristo junto a la Mayordomía (un metro menos, por la calle del juego) y el pasillo descubierto de la entrada del parking. Su fachada de Santa Ana era la casa `stana_60d` de Texturas, ahora `["obra"]`. La nave de la Mayordomía del Cristo del Prado (4790711) no es suya y queda como estaba.
  - Santa Ana: rótulo «MERKOCARRY» nuestro con sus colores, franja verde, insignias sin marca, escaparates con carteles, puerta de cristal, focos, barandilla. El Cristo: muro con zócalo de piedra, tejadillo azul, puertas, la entrada del parking con su cartel, cancelas de celosía y el pilar de la P. El Suspiro: muro largo azul, blanco y azul, puerta de lamas, la puerta de clientes y el muro bajo con valla. Magallanes: muro alto y valla. Dentro: porches en U para los coches, plazas, paseo cubierto hasta la puerta trasera, paso de cebra, farolas.
  - Horario (Google y su cartel): de lunes a sábado de 9:30 a 21:00, domingo cerrado. Abierto: cancelas abiertas, luces, coches de clientes (6; 9 en horas punta). Cerrado: cancelas cruzadas y sólidas, aparcamiento vacío.
  - Rehorneado con el OK de Sistemas y Texturas, sobre el map.json de la 0.0.12: igual que el ensayo. Relieve, nodos, 656 calles y árboles sin cambios; `clr` sube en 2 nodos (Cristo 2.1 → 2.7, Suspiro 3.6 → 3.7); se va `stana_60d`; 26 paredes del bloque del Catastro menos y 6 nuevas, todo a menos de 120 m.
  - Toca `tools/bake_godot.py` (bloque MERKOCARRY), `map_data.gd` (`merkocarry`), `world.gd` (constante, variable, paso, `_build_merkocarry`) y `selftest.gd` (modo `merkocarry`, `_merkocarry_checks` tras `_bancosancho_checks`). Imágenes nuevas importadas (`--headless --import`). `merkocarry` 5/5, `relief` 19/19, `casas solo=stana_` 4/4.
  - «Tiene muy buena pinta. Pega un póster de Roster Energy cerca de cada entrada y luego les haces un interior al que se puede acceder por las dos entradas» (17/11): pósters de Roster junto a las cuatro entradas (Santa Ana, puerta trasera, pilar del parking, puerta de clientes). El interior es `merkocarry_dentro.gd`, un set aparte en (1100, 1850): cajas, fruta, estanterías de cash & carry, palés, congelados, bebidas y carnicería. Se entra por la flecha de Santa Ana o por la de la puerta del aparcamiento, y se sale por cualquiera de las dos.
  - `entradas.gd` (de Sistemas): las dos puertas en `shops()` y `_same_set`, para que dentro de un set con dos puertas valgan las dos salidas. `entradas` 4/4, `noche` 5/5, `merkocarry` 7/7.
  - La nave de la Mayordomía (Catastro 4790711, calle del Cristo): «es otro edificio distinto. Pero puedes ponerte con él ahora» (17/11). Es `mayordomia.gd` y la construye merkocarry.gd en un mapa horneado con `merkocarry.nave`. Lleva zócalo de piedra, revoco crema, chapa beige hasta 6,2 m, el portón de los pasos con arcos en relieve, ventana con reja, puerta gris, placa «MAYORDOMÍA», la caja de la luz y el espejo convexo. Su frente queda un metro detrás del Catastro, como la esquina del Merkocarry. Rehorneado con el OK de los dos: solo se va el bloque de la 4790711. `merkocarry` 8/8.
  - La placa se queda con «MAYORDOMÍA» («Solo mayordomía está bien», 17/11).
- **Pretil (17/11): el recinto ferial y mercadillo, a mano (con un rehorneado para cerrar sus calles)** (`ferial.gd`, `world.ferial`). Veredicto, con el parque del Paseo del Cristo: «Genial. Ha quedado increíble» (17/11). Hojas en `guion/fotos/ferial/`.
  - «Son una entrada con fuente, una entrada con columnas con enredaderas, y tres caminos asfaltados con aceras amplias»:
    - la fuente en la isla de la rotonda (bordillo, adoquín rojo, vaso de piedra con barandilla, agua, surtidor);
    - la pérgola de columnas y arcos con hiedra junto a la calle del norte;
    - los tres caminos con bordillos y tierra compactada entre ellos, en vez de césped y aceras, con farolas y contenedores;
    - la explanada del mercadillo, de baldosa a cuadros con pórticos de acero azul.
  - Toca `world.gd` (constante, variable, paso «the fairground» antes de «details», `_build_ferial`) y `selftest.gd` (modo `ferial`; `_ferial_checks` tras `_correos_checks`), avisado antes a Sistemas. `ferial` 2/2.
  - «El recinto ferial sin líneas de tráfico. Y tampoco deben circular coches por ahí» (17/11):
    - En el horneado se cierran al tráfico sus 7 calles sin nombre (`FERIAL_ZONE`, k 2, pedestrian, `paved` 4, con el pasillo de calle de coches), con el OK de Sistemas y Texturas.
    - `ferial.gd` pone el asfalto sin pintar y `empedrado.gd` salta `paved` 4 (una línea, OK de Texturas).
    - Rehorneado igual que el ensayo: sin cambios en relieve, nudos, clr, casas ni paredes; un árbol más; ningún callejón sin salida nuevo.
  - El parque del Paseo del Cristo, al norte del recinto («te faltaría la parte que se ve desde Paseo de Cristo», 17/11), en `ferial.gd` `_park()`:
    - la fuente ovalada dentro de una pérgola de hiedra en semicírculo abierta al Paseo;
    - la pérgola de la calle Huerta, con su seto;
    - la fuentecilla con barandilla detrás de la pérgola del recinto;
    - setos, árboles propios, aceras de baldosa a cuadros y el quiosco de la esquina.
    - Un rehorneado solo de árboles (`ferial_park`: el mapa no planta los suyos ahí, 20 menos), con OK de Sistemas y Texturas. `ferial` 2/2, sin errores de script.
  - La calle principal: «La linea roja es la "calle" principal del recinto (las fuentes están en mitad). Se divide en camino empedrado (azul) y asfalto (rojo)» (17/11).
    - Una recta (`AXIS_P`, `AXIS_D`) por la fuente de la rotonda, la fuentecilla y la fuente ovalada: asfalto en el recinto, adoquín en el parque.
    - Las fuentes y los huecos de las pérgolas y setos van sobre ella. Sin rehorneado. `ferial` 3/3.
  - «el camino empedrado tiene enredadera por encima y faltan dos fragmentos de enredadera abajo (donde hay dos bares con dos terrazas)» y «Las fuentes funcionan?» (17/11):
    - un túnel de hiedra sobre el camino empedrado;
    - dos bloques de hiedra de cuatro filas a los lados de la fuentecilla, con las terrazas de los bares debajo (`world.extra_terrazas`);
    - el agua en movimiento y los surtidores de la fuente de la plaza (`plaza.gd` WATER_SHADER y JET_SHADER) en las tres fuentes.
    - `ferial` 4/4.
  - El Auditorio y los aseos públicos («para el auditorio solo un hueco en el muro por donde pasar y para los baños una entrada con flecha a otra ubicación», 17/11), en `ferial.gd` `_auditorio()` y `_aseos()`, sin rehorneado. «Está casi casi perfecto» (17/11), con dos retoques ya hechos: el poyo para sentarse al pie del muro crema y el escenario de piedra en vez de la tierra. Visto bueno (17/11, transmitido por Sistemas para el release: «Visto bueno a todo lo pendiente y paramos»).
    - El Auditorio: muro crema con su poyo por fuera (blanco, más alto y sin poyo hacia el aparcamiento, con dos carteles de minusválidos), el hueco junto a los aseos con la puerta verde abierta, la acera de baldosa por fuera, el escenario de piedra de un metro con su escalerita, nueve filas de bancos blancos en cuatro bloques (calcadas de la ortofoto) y tres postes con focos.
    - Los aseos: casita crema con tejado a cuatro aguas; por la flecha verde de su puerta doble se entra a su interior, un decorado aparte (`aseos_dentro.gd`, nuevo, en (-1280, -1870)).
    - Toca `entradas.gd` (una línea en `shops()`, OK de Sistemas) y `selftest.gd` (modo `ferial`: fotos, entrada y salida por la flecha; `_ferial_checks`).
  - Detalles: `referencias/ferial/LEEME.md`.
- **Pretil (17/11): Correa, la oficina de correos de la calle Zaragoza 1, junto a la plaza, a mano y con rehorneado** (`correos.gd`, `world.correos`). Veredicto, con la verja, los rótulos de noche y el interior: «Está increíble, visto bueno» (17/11). Hojas en `guion/fotos/correos/`.
  - El nombre es del usuario: «En vez de Correos la llamaremos Correa (Servicio Postal Correa). El rótulo debería ser Correa, no Correos». Los rótulos amarillos con base azul dicen «CORREA», con una corneta propia sin corona.
  - Va sobre el contorno de la parcela 4193608 del Catastro. Era la casa `zaragoza_b608` de Texturas, ahora `["obra"]`. Lleva planta baja de ladrillo con el portón de madera bajo el arco, tres ventanas, la entrada metida con rampa y barandilla, la ventana de la esquina norte entre pilastras crema y la alarma; arriba revoco crema con fajas de ladrillo, persianas, terraza, cornisa gris y tejado de teja. Horario: de lunes a viernes de 8:30 a 14:30.
  - Rehorneado con el OK de Sistemas y Texturas, igual que el ensayo: relieve, calles, nudos y clr sin cambios; se va `zaragoza_b608`; 1 tejado plano y 1 pared menos. Toca `tools/bake_godot.py` (bloque CORREOS), `map_data.gd` (`correos`), `world.gd` (constante, variable, paso, `_build_correos`) y `selftest.gd` (modo `correos`; `_correos_checks` tras `_merkocarry_checks`, que se salta en un mapa sin la oficina). `correos` 3/3, `plaza` 8/8.
  - «añade abierto/cerrado (verja en la entrada, iluminación del cartel,...) e interiores» (17/11): cerrada, una verja de barrotes cierra la entrada (sólida); abierta, recogida en su caja. Los rótulos se encienden al anochecer. Interior en `correos_dentro.gd`, un set aparte en (1300, -1850): ventanillas, turnos, apartados, venta, pupitre, buzón, casillero, paquetes. Se entra por la flecha verde (`entradas.gd`: una línea en `shops()`, avisado a Sistemas). `correos` 5/5, `entradas` 4/4.
  - Detalles: `referencias/correos/LEEME.md`.
  - Detalles: `referencias/merkocarry/LEEME.md`.

## Versión

- **Publicada:** 0.0.12 (16/11/2026). https://github.com/LomoXSoft/Matritellus/releases/tag/v0.0.12 — completa: 735 ok, 0 fallos.
  - **Android vuelve a arrancar (Sistemas):** la 0.0.11 se cerraba en la pantalla de carga («Vulkan device was lost»). Durante la carga se dibujaba el pueblo a medio construir detrás de la pantalla negra; ahora no se dibuja nada en 3D (`disable_3d`) hasta que está todo construido. Probado en el Realme RMX5051 del usuario: llega al título.
  - **Texturas:** calle de Jesús y María, 27 entradas (`jym_*`), y las casas de otras calles que dan a ella (Arroyuelo Bajo 42, Reina Sofía 45 y 26, Plaza del Toledano 1).
    - Comparadas con el Catastro, cuyas fotos aquí son buenas; el 30, que no tiene foto, va por Street View 2024. Son todas viviendas.
    - Lo que aún no se parece (también en `guion/repaso_casas.md`):
    - En el `b410` faltan los ojos de buey redondos.
    - El zócalo de piedra blanca de dibujo del 11, el 9 y el 7 sale liso.
    - Los toldos verdes del `b015` salen como rayas finas.
    - Bake: 27 casas nuevas; solo cambian las piezas de `domingo_23`, `clara_1a` y `tinf_jm19`. Un nudo de `clr` baja de 3,1 a 2,5. `casas solo=jym_`: OK. Pretil lo ha comprobado con `toledano` (4/4): `jym_tol1` no pisa la plazuela. Hojas en `guion/fotos/tanda34/jym_1..5.jpg`.
  - **Texturas:** calle del Romero, 29 entradas (`romero_*`), con las casas de otras calles que dan a ella (Delicias 16, Roma 7).
    - Comparadas con el Catastro, cuyas fotos son buenas, y con Street View 2024 en la casa nueva de la calle Roma (2024, sin foto) y en el 24.
    - Los portones de madera clara de tono `b8904a` o `a8803a` salen amarillos. En las calles nuevas van ya en `7a5a38`; los de calles aprobadas quedan en la lista del repaso.
    - Bake: 29 casas nuevas; cambian las piezas de `stana_9`, `valencia_7`, `valencia_8`, `valencia_10`, `regidor_7` y `rafael_6`. Un nudo de `clr` baja de 3,5 a 2,5. `casas`: OK. Hojas en `guion/fotos/tanda34/romero_1..6.jpg`.
- **Publicada antes:** 0.0.11 (16/11/2026): el rendimiento (la rejilla de los suelos: de 65 a 84 fps en la Plaza), el salto, los niños, los chismes, el Padrón, el creador nuevo y tu casa, la rotonda, el IES, el MasAhorro, la Noche, el banco y la copistería, y muchas calles.
- **Sin publicar (Texturas, 16/11): restos del centro, 13 entradas (aprobadas: «Visto bueno y continuar»).** Son casas que seguían con la pared genérica junto a la Plaza y la calle Real.
  - Zaragoza: el pasaje con su torre (`zaragoza_6`), Correos (`zaragoza_b608`; desde el 16/11 es `["obra"]` de Pretil, `correos.gd`, a petición del usuario; la línea de antes está en las notas compartidas) y la tapia de la travesía (`zaragoza_t1`). También los traseros de cuatro casas de la calle Real y uno del Arroyuelo Alto que dan a Zaragoza (`zaragoza_r53`, `r55`, `r59`, `r63`, `a20`: entradas con `only` 1 sobre la misma RC).
  - Colón: `colon_3`, `colon_14b` y `colon_s11`, el ala de dos plantas de `salvador_11`.
  - Salvador: `salvador_c3` (con su costado a la Constitución) y `salvador_cv5`.
  - Todas comparadas con Street View 2024. `colon_3` está reformada desde la foto del Catastro, y va su fachada de ahora.
  - Bake (dos pasadas, avisando a Pretil): 13 casas nuevas, 656 calles, ni `clr` ni nudos ni relieve cambian y el `merkocarry` sigue. `colon_3` va en línea con `colon_5`, a 2,4 m de la línea de Colón, porque el Colón del juego está 3 m corrido. `casas`: OK. Hojas en `guion/fotos/tanda34/centro_6..8.jpg`.
- **Sin publicar (Texturas, 16/11): restos de Ramón y Cajal, Madrid y la Avenida de la Constitución, 12 entradas (aprobadas: «Visto bueno y continuamos»).**
  - Ramón y Cajal: `cajal_b021`, `cajal_rs2` (el costado largo de la casa de esquina de la Reina Sofía, con su fachada a la avenida como `lado`), `cajal_24d`, `cajal_22d` (el mirador redondo, con `paño ... out= r=`), `cajal_25` y `cajal_10d`.
  - Madrid: `madrid_b308`.
  - Constitución: `constitucion_18`, `19`, `21`, `29` y `35`, casas de esquina del final del Palo y de Madrid.
  - Se describen por las fotos del Catastro (2013-2018) y por Street View 2024 donde se ve; en Ramón y Cajal Street View está demasiado cerca.
  - **Quitadas:**
    - `palo_35` y `palo_37`: su fachada es ya el taller «df Mecánica» de `garage.gd` (en `GARAGES` del bake, de 72,4/-45,3 a 90,7/-38,9). La pared genérica que queda allí es la que viste ese taller.
    - `madrid_24`: el frente que da `house_street.py` queda a 8,9 m de la calle, metido detrás de otras piezas. Queda para el repaso.
  - Bake (tres pasadas, avisando a Pretil): 12 casas nuevas, 656 calles, nudos, relieve, `garages` y `merkocarry` iguales. Un nudo de `clr` en Ramón y Cajal (-156, 148) baja de 2,8 a 2,3. `casas`: OK. Hojas en `guion/fotos/tanda34/cajal_1..3.jpg`.
- **Sin publicar (Texturas, 16/11): calle de San Isidro, lo que quedaba: 6 entradas (aprobadas: «Visto bueno y siguiente»)** (`sanisidro_53`, `51`, `8`, `6`, `4`; `sanisidro_35b` porque ya había un `sanisidro_35` con otra RC).
  - Comparadas con las fotos del Catastro y con Street View 2024.
  - Aquí la línea de la calle pasa por encima de las fachadas del Catastro. Los frentes siguen la pared que deja el bake (`frente_gen.py`). En el 51 y el 53, donde la calle tuerce, los frentes van paralelos a la calle a 2,1 m de su línea, que es el `clr` de ese nudo.
  - Las casas de las esquinas, cuya fachada principal da a las Monjas, a Tembleque o al Florido, se quedan para cuando se hagan esas calles. También se queda un cuartito de 9 m².
  - Bake (avisando a Pretil, sobre su mapa con la nave): 6 casas nuevas; calles, nudos, `clr`, relieve, `garages` y `merkocarry` iguales. `casas`: OK. Hojas en `guion/fotos/tanda34/sanisidro_1..2.jpg`.
- **Sin publicar (Texturas, 16/11): calle de Tembleque, primer tramo, 20 entradas (`tembleque_*`; aprobadas: «Visto bueno y seguir»)**, del número 1 al 25 y del 4 al 14.
  - Comparadas con las fotos del Catastro, que son buenas, y con Street View 2024 en el 1 (Catastro 2026), el 9b (sin foto) y el 11.
  - Quedan dos tramos de Tembleque, unas 26 casas, y las esquinas con San Isidro.
  - Bake (avisando a Pretil, sobre su mapa con `correos`): 20 casas nuevas; calles, nudos, `clr`, relieve, `correos`, `merkocarry` y `garages` iguales. Solo cambian las piezas de `rosa_15` y `rsm_t27`. `casas solo=tembleque_`: OK. Hojas en `guion/fotos/tanda34/tembleque_1..4.jpg`.
- **Sin publicar (Texturas, 16/11): calle de Tembleque, el resto, 25 entradas (`tembleque_*`; aprobadas: «Visto bueno y siguiente»)**: del 14c al 28 y del 48 al 54 en los pares; del 55 al 97 en los impares, con las esquinas de San Isidro (59, 28 y 61).
  - Comparadas con las fotos del Catastro y con Street View 2024 en el 73, el 85 y el 54, que no tienen foto. Con esto Tembleque queda entera.
  - **Quitada:** `tembleque_57`. El Catastro solo le da 2 m de fachada, y su frente caía detrás de la casa de la esquina (`tembleque_59`), entre piezas sueltas. Su foto parece mostrar parte de la fachada larga del 59.
  - Bake (avisando a Pretil, sobre su mapa con `correos`): 25 casas nuevas; calles, nudos, relieve, `correos`, `merkocarry` y `garages` iguales. Un nudo de `clr` en (-370, -227) baja de 2,3 a 2,2. `casas`: OK. Hojas en `guion/fotos/tanda34/tembleque_5..9.jpg`.
- **Sin publicar (Texturas, 16/11): calle de las Monjas, tramo sur, 18 entradas (`monjas_*`; aprobadas: «Visto bueno y siguiente»)**: del 73 al 117 en los impares, el 72, el 94 y el 96.
  - Comparadas con las fotos del Catastro, que aquí son lejanas, y con Street View 2024 en el 73, el 81 (sin foto), el 83, el 93 y el 97.
  - El 97 es hoy un solar vallado: va como el muñón de una tapia de 2,2 m.
  - Quedan el tramo norte (unas 34 casas, junto al convento de Santa Ana, que no se toca) y las esquinas con San Isidro y el Florido.
  - Bake (avisando a Pretil): 18 casas nuevas; calles, nudos, `clr`, relieve, `santaana`, `correos`, `merkocarry` y `garages` iguales. `casas solo=monjas_`: OK. Hojas en `guion/fotos/tanda34/monjas_1..3.jpg`.
- **Sin publicar (Texturas, 16/11): calle de las Monjas, tramo norte, 29 entradas (`monjas_*`; aprobadas: «Visto bueno y siguiente»)**, con la Bajada del Rollo (`monjas_r*`), que el mapa llama también calle de las Monjas, y una casa de la travesía del Rollo (`monjas_tr6`) y otra del Florido (`monjas_fl10a`).
  - Comparadas con las fotos del Catastro. Hay dos solares: el 6 queda sin hacer y el r27 va como tapia baja de ladrillo. La panadería lleva el rótulo «PANADERÍA».
  - **Quitadas:**
    - Monjas 23 (3792802): sus partes entran en el solar del convento (`santaana_zone` 21 m², `santaana_built` 4,8 m²).
    - `monjas_10`: es una casa en L, y el frente que da `house_street.py` cae dentro de la manzana.
    - `monjas_na25` (calle de Nalda 25): su frente es a Nalda.
    - Monjas 22: no da a la calle según el Catastro.
  - Bake (avisando a Pretil): 29 casas nuevas; calles, nudos, `clr`, relieve, `santaana`, `correos` y `garages` iguales. Pretil pasó `santaana`: 3/3, con el convento entero y ninguna casa nueva dentro. `casas`: OK. Hojas en `guion/fotos/tanda34/monjas_4..8.jpg`.
- **Sin publicar (Texturas, 16/11): Avenida de la Constitución, primer tramo, 26 entradas (`constitucion_*`; aprobadas: «Visto bueno y siguiente»)**, del 2 al 42, entre la calle de los Arcos y la de Madrid. Incluye la esquina de Arcos 1 (`constitucion_a1`).
  - Comparadas con las fotos del Catastro y con Street View 2024 en las tiendas:
    - el videoclub de la esquina (17) parece cerrado y va sin rótulo;
    - la tienda de azulejos de la esquina de Arcos (`b808`) es hoy ocre, con un frente de madera oscura;
    - la tienda del 14 lleva el rótulo «SUMINISTROS».
  - Bake (avisando a Pretil): 26 casas nuevas; calles, nudos, `clr`, relieve, `garages`, `correos`, `masahorro` y `cuartel` iguales. Solo cambian las piezas de `stana_2` y `constitucion_18`. `casas`: OK, con una espera porque `ferial.gd`, de otra sesión, no compilaba. Hojas en `guion/fotos/tanda34/constitucion_5..9.jpg`.
  - Quedan dos tramos: del 44 hacia el cuartel (unas 30 casas) y la salida hacia la A-4.
- **Sin publicar (Texturas, 16/11): Avenida de la Constitución, segundo tramo, 27 entradas (`constitucion_44..100`; aprobadas: «Perfecto. Visto bueno y siguiente»)**, de la calle de Madrid hacia el norte.
  - Comparadas con las fotos del Catastro y con Street View 2024 en el 44, 59, 65, 76, 78 y 88.
  - La farmacia del 76 lleva el rótulo «FARMACIA» y la droguería del 57, «DROGUERÍA». La tienda del 44 va sin su nombre.
  - **Quitadas:**
    - `constitucion_65` y `constitucion_63`: sus RC son ya `alemania_c65` y `alemania_c63` del bake, que dan a la calle de Alemania.
    - `constitucion_94`: una de sus partes queda 25 m detrás, y sus piezas salían rotas. Queda genérica.
  - **Un fallo encontrado y arreglado:** una planta escrita `plinth=0` sin material rompe `casas.gd` (`String(null)`), y la casa sale como `null` en `world.casas`. En la planta hay que poner siempre `plinth=<alto>:<qué>`; `plinth=0` vale solo en `paño`.
  - Bake (después del recinto ferial de Pretil, y avisándole): 27 casas nuevas; calles, nudos, `clr`, relieve, árboles, `garages` y `cuartel` iguales. `casas`: OK. Hojas en `guion/fotos/tanda34/constitucion_10..14.jpg`.
- **Sin publicar (Texturas, 16/11): Avenida de la Constitución, salida hacia la A-4, 3 entradas (`constitucion_95`, `101` y `132`; aprobadas: «Visto bueno. Seguimos»).**
  - El 95 es un bar: su rótulo dice solo «CERVECERÍA». El 101 es una casa blanca con balcones y el 132, una nave con portón azul.
  - Con esto la Constitución queda entera. Lo que sigue genérico junto a ella son costados de casas de las calles Ilusión y Sueños, que se harán con esas calles.
  - Bake (avisando a Pretil): 3 casas nuevas; calles, nudos, `clr`, relieve, árboles (2963) y `cuartel` iguales. `casas`: OK. Hoja en `guion/fotos/tanda34/constitucion_15.jpg`.
- **Sin publicar (Texturas, 16/11): calle del Regidor, lo que quedaba, 9 entradas (aprobadas: «Visto bueno y siguiente»).** Son las `regidor_*` y `constitucion_34`.
  - La casa de la esquina con la Constitución (RC 4492801) va partida en dos con `only`:
    - `constitucion_34` es la parte de dos plantas, con su fachada a la avenida;
    - `regidor_c34` es la tapia de una planta del Regidor.
  - La de enmedio (`regidor_2`) toma su frente de la pared que deja el bake.
  - Comparadas con las fotos del Catastro y con Street View 2024 en las tres primeras.
  - Bake (avisando a Pretil): 9 casas nuevas; calles, nudos, `clr`, relieve, árboles y `garages` iguales. `casas`: OK. Hojas en `guion/fotos/tanda34/regidor_1..2.jpg`.
- **Sin publicar (Texturas, 16/11): calle de San Rafael, lo que quedaba, 8 entradas (`rafael_a19`, `n1d`, `fp28b`, `j20`, `j22`, `j25`, `ts1`, `tc2`; aprobadas: «Visto bueno y siguiente»).**
  - Son los costados a San Rafael de casas de esquina de otras calles: la Alegría, la Niña, Fray Petronilo Cobo, Juan XXIII, la travesía de San Rafael y la travesía del Clavel. Van con el frente a San Rafael, comparadas con Street View 2024, porque las fotos del Catastro enseñan la otra fachada.
  - Cuando se hagan esas calles, su fachada principal habrá que describirla como `lado`.
  - **Quitada:** `rafael_a21i` (Alegría 21, un almacén de 27 m): su tejado salía roto.
  - Bake (dos pasadas, avisando a Pretil): 8 casas nuevas; calles, nudos, `clr`, relieve, árboles y `garages` iguales. `casas`: OK. Hojas en `guion/fotos/tanda34/rafael_1..2.jpg`.
- **Sin publicar (Texturas, 17/11): Callejón Pando, 20 entradas (`pando_*`; aprobadas: «Visto bueno y siguiente»).**
  - Comparadas con las fotos del Catastro, que aquí son buenas.
  - El centro de salud (`SALUD_RC`) es de otra sesión y no se toca.
  - Las traseras de la calle de la Cruz que dan al callejón se quedan para cuando se haga esa calle.
  - La pieza `stone` sale como mampostería gris oscura. Para la piedra clara o tostada de estas casas va un color (`c8a47c`, `dccbb0`).
  - Bake (avisando a Pretil): 20 casas nuevas; calles, nudos, `clr`, relieve, árboles y `salud` iguales. Solo cambian las piezas de `argentina_32`. `casas`: OK. Hojas en `guion/fotos/tanda34/pando_1..4.jpg`.
- **Sin publicar (Texturas, 17/11): calle de la Cruz, 31 entradas (`cruz_*`).** Incluye los costados a la Cruz de casas de la calle de la Virgen de Gracia (`cruz_vg*`).
  - Comparadas con las fotos del Catastro y con Street View 2024 en el 8, el 13, el 17 y la nave del 6.
  - **Quitada:** `cruz_6`, una nave de 1974 con una parte de 10 plantas en el Catastro. El bake no la construía, así que queda genérica.
  - Bake (avisando a Pretil): 31 casas nuevas; calles, nudos, relieve, árboles y `salud` iguales. Un nudo de `clr` en (289, 210) sube de 3,1 a 3,2. Solo cambian las piezas de `pando_12`. Hojas en `guion/fotos/tanda34/cruz_1..5.jpg`.
- **Pendiente:**
  - Texturas:
    - **Visto bueno (17/11)** de Jesús y María, Santa María, Toledo, Parto, Mirador, Ejon, San Francisco, Teniente Infante y la Rosa vieja. Lo dio el usuario con «Visto bueno a todo lo pendiente y paramos», según el mensaje de Sistemas al congelar para el release.
    - **La calle de la Cruz (`cruz_*`, 31 casas) queda sin verificar.** Está horneada y `casas_calles.gd` compila, pero la prueba `casas` de esas casas no llegó a correr: `ferial.gd`, de Pretil, no compilaba en ese momento. El usuario no ha visto sus hojas. Al volver, hay que pasar `casas solo=cruz_`, sacar las hojas `guion/fotos/tanda34/cruz_1..5.jpg` y enseñárselas.
    - Cervantes y la travesía de Zaragoza tienen ya su «Visto bueno» (16/11), y el Romero, los restos del centro, los de Ramón y Cajal, San Isidro, Tembleque entera, las Monjas entera, la Constitución entera, el Regidor, San Rafael y el Callejón Pando también («Visto bueno y sigue», «Visto bueno y continuar», «Visto bueno y continuamos», «Visto bueno y siguiente», «Visto bueno y seguir»). La calle del Clavel está entera y aprobada.
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
- Habla (desde la 0.0.3): los mancheguismos, sobre todo para los mayores (`generic_old`, `whisper_old`, `ouch_old`). «Apretar» sin diptongo: apreta, apretes. Y en boca de todos (desde la 0.0.9): «tiés» por «tienes» y «ande» por «dónde/donde» («por donde» también: «ande puedas»). Todo en `guion/palabros.md`, contado con nuestras palabras porque su web es CC BY-NC-ND. José-María Moreno García va en los créditos. Lo comprueba `python tools/run_tests.py palabros`.
