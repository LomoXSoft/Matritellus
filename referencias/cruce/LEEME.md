# El cruce de los semáforos («las cuatro esquinas»)

Luis, 21/11/2026, con siete capturas de Street View: «Donde se cruzan la calle santa ana, la calle los arcos, la avenida de la Constitución, la calle salvador y la calle Cervantes se llama "el cruce de los semáforos" o "las cuatro esquinas" porque tienen muchos semáforos y señales. Te pido ahora colocar estos donde corresponde. Antes igual tendremos que hacer unas pocas fachadas. Sugiero ir una por una y empezar por el edificio de soliss seguros (última foto) y que llamaremos seguros sopiss, tendrá luces de apagado o encendido según su horario y en su interior saldrán dos NPCs genéricos hablando de seguros cuando abierto, y una señora de la limpieza cuando cerrado. Se podrá ver desde fuera, pero no pasar. Vayamos poco a poco que es una parte pesada del proyecto y con muchas partes».

## Estado

| Parte | Estado |
|---|---|
| «Seguros Sopiss» (esquina oeste, entre el Salvador y la calle Cervantes) | Hecho el 21/11; **aprobado por Luis el 22/11** («Visto bueno a sopiss») |
| «Clínica Dental» del «Dr. Josué Escudero» (esquina suroeste, entre Cervantes y los Arcos) | Hecha el 22/11; **aprobada por Luis el 22/11** («Visto bueno»), sin el azafrán |
| La casa blanca de Santa Ana 2 (esquina sureste, entre Santa Ana y los Arcos) | Hecha el 22/11; **aprobada por Luis el 22/11** («No se pone Azafrán. Visto Bueno. Siguiente») |
| La casa crema del mirador (esquina noreste, entre la avenida y Santa Ana) | Hecha el 22/11; **aprobada por Luis el 22/11** («Visto bueno. Sin azafrán. Pasamos a semáforos») |
| La casa beige de enfrente del Salvador (esquina noroeste) | Hecha el 22/11; **aprobada por Luis el 22/11** («Visto bueno. Sin azafrán. Pasamos a semáforos») |
| Semáforos, espejo y señales del cruce | Hechos el 22/11 (`cruce.gd`); a la espera del visto bueno de Luis. El ciclo y los coches son de Sistemas (`semaforos.gd`) |

## El cruce en el mapa

- La avenida de la Constitución llega por el norte (vía 150) y sigue hacia el sur como calle de los Arcos (271). Santa Ana sale al este (134). Al oeste salen dos: el Salvador (147, entra al cruce en sentido único) y la de abajo.
- **La calle de abajo se llama «Calle del Teniente Infante» en el mapa (vía 20, de OpenStreetMap) y «Calle Cervantes» en la placa real** de la fachada del edificio rojo; Luis también la llama Cervantes. La placa del juego dice «Calle Cervantes». **Luis, 22/11: «No renombres»**: el nombre del mapa se queda como está.
- **Azafranes escondidos.** Luis, 22/11: «Quita ese azafrán escondido, sigue proponiendolos y yo te digo en cada proyecto si lo añadimos o lo quitamos». Desde ahora, en cada edificio se propone dónde iría y no se pone hasta que él lo diga. El de la clínica se quitó; el de Sopiss, que aprobó sin comentarlo, sigue en el portal de los pisos.
- Las esquinas, según las fotos:
  - Oeste, entre el Salvador y Cervantes: el edificio rojo (`salvador_24`).
  - Noroeste, al norte del Salvador: una casa beige de dos plantas, con un semáforo y un armario gris en su esquina.
  - Noreste, entre la avenida y Santa Ana: la casa crema del mirador, con el semáforo de báculo alto que vuela sobre la avenida.
  - Sureste, entre Santa Ana y los Arcos: la casa blanca de zócalo de piedra, con semáforo y papelera.
  - Suroeste, entre Cervantes y los Arcos: la clínica dental, de piedra oscura (`arcos_2`). Google Maps la sitúa en «C. Cervantes, 52»: otra prueba de que ese tramo es la calle Cervantes.
- Los semáforos, el espejo y las señales que se veían en cada edificio ya están puestos: sección «Semáforos, espejo y señales». Las farolas de brazo de las fachadas siguen sin poner.

## Fuentes y herramientas (`tools/cruce/`)

- Street View de noviembre de 2024 en las cinco calles (y 2021, 2019, 2013, 2012 y 2009 en casi todos los puntos). **Las fotos no están en el repositorio**: son de Google.
  - `capturas.py CARPETA` baja las vistas del edificio rojo y escribe `views.json`. Todas las cámaras: `python tools/molino/panos.py cerca MX048pEYVrMizUfLzgdf8A 111 68 34`.
  - `mide.py VIEWS.json FRENTE vista:u,v …` da, para un píxel, los metros a lo largo de una fachada y la altura. La posición que da Google de cada cámara falla uno o dos metros: `fit=` la corrige con dos puntos conocidos de la misma cámara.
- `postes.py VIEWS.json vista:u,v vista:u,v …` cruza los rumbos al pie de un poste desde dos o más cámaras y da su sitio en el mapa; con `top=vista:u,v`, su altura. `capturas.py` baja también las 42 vistas `x_` de los semáforos y las señales.
- `manzana.py` dibuja las parcelas de Catastro sobre la ortofoto (`tools/ign/cruce.jpg`, `cruce_fino.jpg`). La ortofoto no sirve para el tejado: el edificio sale tumbado y borroso.
- `alturas.py` da el terreno del juego alrededor: casi llano (de 0,67 a 0,84).
- `dibujos.py` dibuja los rótulos propios de Sopiss en `godot/assets/sopiss/`, y `dibujos_clinica.py` los de la clínica en `godot/assets/clinica/`. Tras cambiarlos: `Godot --headless --path godot --import`.
- `hojas.py sopiss`, `hojas.py clinica`, `hojas.py stana2`, `hojas.py mirador`, `hojas.py beige` y `hojas.py cruce` montan las hojas de `guion/fotos/cruce/`; con `CARPETA SV` montan además la comparación con Street View, fuera del repositorio.

## Lo que comparten los edificios del cruce (`godot/scripts/esquina.gd`)

Los cinco edificios del cruce (`sopiss.gd`, `clinica.gd`, `stana2.gd`, `mirador.gd` y `beige.gd`) extienden `esquina.gd`, que a su vez extiende `obra.gd`. Ahí está lo común: las esquinas entre fachadas (`_miter`), el contorno metido o sacado (`_inset`), el recorte (`_clip`), el tejado (`_planes`, `_roof_over`, `_roof_y`), los aleros (`_eaves`), las medianeras (`_party_wall`) y los sólidos finos del contorno (`_ring_solids`).

El tejado se define con faldones: cada uno sube desde la línea de un muro con la misma pendiente, y el tejado es el más bajo de todos en cada punto. Así cierra solo con cualquier contorno. La prueba comprueba que las piezas cubren justo el contorno.

Una casa en L con tejado a dos aguas en cada ala (la casa beige) se hace con dos tejados: cada ala se cubre entera, sobre su propio contorno convexo, con sus tres faldones (su calle, el patio y la otra calle para la limatesa de la esquina). La esquina queda debajo de los dos; el más alto tapa al más bajo y la limahoya sale sola donde se cruzan. La cuenta de superficie sigue cuadrando en cada llamada.

## Semáforos, espejo y señales (`godot/scripts/cruce.gd`, `world.cruce`)

Luis, 22/11: «Visto bueno. Sin azafrán. Pasamos a semáforos». Sin horneado y sin casa del mapa: `cruce.gd` extiende `esquina.gd` y se construye después de la casa beige. Su marco es el del mapa, con y = 0 en la calzada del centro del cruce. Lo que pisa el suelo se rompe de un golpe, como el mobiliario de `props.gd`; lo que cuelga de una pared es fijo.

### Cómo se midió

- 42 vistas `x_` de Street View de noviembre de 2024: anillos desde las dos cámaras del cruce y desde la más cercana de cada calle, y lo que ve quien llega por cada una.
- `postes.py` cruza los rumbos a un mismo poste desde dos o más cámaras. Con tres esquinas conocidas falla unos 0,7 m, lo que falla la posición que da Google de cada cámara.
- Por eso cada cosa se coloca por su sitio a lo largo de la fachada más cercana y su distancia a ella. `_stand()` la arrima a la pared donde la acera del juego es más estrecha que la real: nunca a menos de 0,2 m del asfalto.

### Qué hay

| Esquina | Qué |
| --- | --- |
| Noroeste (casa beige) | Poste con la cabeza de quien baja la avenida y una de peatones. Armario gris contra la pared, entre la esquina y el poste. Prohibido el paso al Salvador, con su placa «EXCEPTO SERVICIO DE RECOGIDA DE RESIDUOS» |
| Noreste (mirador) | Poste con dos cabezas de peatones ante el chaflán. Báculo de 5,9 m con un brazo de 4,4 m sobre Santa Ana: cabeza con tablero en la punta, otra cabeza baja y una de peatones. Prohibido parar, en la avenida |
| Sureste (casa blanca) | Poste con cabeza para Santa Ana y una de peatones, y la papelera. En la esquina, prohibido girar a la derecha sobre un STOP, para quien sube por los Arcos. Prohibido el paso a Santa Ana |
| Los Arcos | Un poste a cada lado con cabeza y cabeza de peatones (el del oeste, en la esquina de la clínica). Prohibido aparcar, pequeño y plano en la pared de la clínica, con su flecha blanca dentro |
| Sopiss | Espejo redondo y STOP en un mismo poste ante su fachada a la avenida. Prohibido autobuses a Cervantes. En su fachada al Salvador, el ceda el paso en su poste pegado a la esquina y una cabeza en escuadra |
| La calzada | Línea de detención en cada calle que trae coches y el paso de cebra de la avenida al norte del Salvador. Los demás pasos son los del pueblo (`world.gd`) |

Son 7 cabezas para coches, 7 de peatones, 11 chapas con el espejo y 14 pies en el suelo (con el armario). No hay edificio: no se propone azafrán.

### Se rompen de un golpe

Luis, 22/11, al ver el cruce: «Increíble. Solo añadiría que se puedan romper con un golpe, una vez rotos pasan a funcionar como ámbar. Se arreglan igual que el resto de objetos rompibles».

- Lo que pisa el suelo son 14 piezas sueltas (`_parts`): los cinco postes con semáforo, el báculo, el armario, la papelera y los seis postes de señales (el del espejo entre ellos). Cada una es un cuerpo propio, congelado, con sus mallas y su caja.
- `props.gd` las adopta (`adopt()`, añadida para esto): un coche (`sweep`) o un puñetazo (`punch`) las tumba como al resto del mobiliario, con su cuenta de roturas y lo que le importa a los Tricornios. `props.gd` avisa a `cruce.gd` en el momento de la caída (meta `on_knock` de cada cuerpo; `_watch()` queda de red por si no lo hiciera). Una señal o la papelera caídas se retiran a los 40 s, como el resto del mobiliario (el resto se esconde y vuelve; las del cruce se borran y `repair()` las rehace); un poste con semáforo, el báculo o el armario llevan además la meta `keep` y se quedan tirados hasta `repair()`. Las dos metas son ganchos que Sistemas añadió a `_knock` para esto.
- Lo que cuelga de una pared no se rompe: el ceda el paso y la cabeza en escuadra de Sopiss, y el prohibido aparcar de la clínica.
- Si cae un poste con semáforo, el báculo o el armario, `broken` pasa a `true` y **todo el cruce** parpadea en ámbar, sin muñecos: lo enseña `cruce.gd` y no hace caso de lo que le manden mostrar, aunque lo guarda. Una señal o la papelera caídas no cambian las luces.
- `semaforos.gd` (Sistemas) lee `broken` y trata el cruce como en su ámbar de madrugada: los coches de la avenida y de los Arcos hacen el STOP y el resto pasa.
- `repair()` levanta todo lo caído y las luces vuelven a lo último que se les mandó. Se arreglan al día siguiente, como el resto del mobiliario (decisión de Luis del 22/11, «Al día siguiente», que llegó por Sistemas): `props.gd` (`mend()`, de Sistemas) llama a `world.cruce.repair()` cuando hay algo caído (`broken` o `down > 0`), ya es otro día que el de la última caída y no se ve el punto de parada de la avenida. Hasta entonces el semáforo caído sigue tirado y el cruce en ámbar. Al cargar la partida todo está en pie. `fallen()` da los sitios donde el arreglo cambiaría lo que se ve (el de cada pieza caída y donde yace), por si hace falta mirarlos todos y no solo uno.
- `down` dice cuántas piezas hay caídas y `part(nombre)` da una pieza por su nombre (la prueba).

### Las luces: reparto con Sistemas

Las lentes brillan con su propio material (sin luces nuevas). `cruce.gd` da la pieza y las funciones; el ciclo y los coches son de Sistemas (`semaforos.gd`, `game.semaforos`).

- `heads`: una entrada por calle que trae coches, con `name`, `stop` (centro de su carril en la línea), `a` y `b` (nodos del mapa, buscados por posición al construir), `group` y `state`.

| `i` | `name` | `a` → `b` | `stop` | `group` |
| --- | --- | --- | --- | --- |
| 0 | `avenida` | 850 → 1116 | (111,9, 52,8) | 0 |
| 1 | `salvador` | 1092 → 1093 | (106,9, 58,8) | 1 |
| 2 | `santa_ana` | 973 → 974 | (121,6, 69,1) | 1 |
| 3 | `arcos` | 185 → 193 | (114,5, 80,9) | 0 |

- `walk`: los pasos con semáforo de peatones: 0 `avenida` (grupo 0), 1 `santa_ana` (grupo 1) y 2 `arcos` (grupo 0), con `at` y `on`. Cervantes y la boca del Salvador no tienen.
- `set_light(i, "verde" | "ambar" | "rojo" | "off")` cambia todas las cabezas de esa calle. `set_walk(i, on, dark := false)` enciende el muñeco verde o el rojo; con `dark`, ninguno.
- `auto`: mientras sea `true`, `cruce.gd` lleva un ciclo propio, solo de luces (`CYCLE`, `show_phase()`). `semaforos.gd` lo pone a `false` al arrancar. `restart()` lo devuelve. `lights()` y `put_back()` guardan y reponen lo que muestran: la prueba los usa para dejarlas como estaban.
- Sistemas necesita que los nombres sean exactamente `avenida` y `arcos`: de 1 a 7 de la madrugada, con el ámbar intermitente, sus coches hacen el STOP.
- Luis decidió que los semáforos solo paran a los coches del pueblo: al jugador saltárselo no le cuesta nada.
- Santa Ana es de sentido único hacia el cruce en la realidad. Luis decidió que lo sea solo su último tramo (del nodo 969 al 974): `ONE_WAY_FIX` en `map_data.gd`, de Sistemas, sin rehornear. Con eso la línea de Santa Ana cruza toda la calle y su `stop` cae en el eje.

### Lo que es aproximado

- Las posiciones, a unos 0,7 m. En la acera este de la avenida y en la este de los Arcos, que en el juego miden medio metro, el poste va casi pegado a la pared.
- El ceda el paso y la cabeza del Salvador vuelan de la pared: ahí la calzada del juego llega a la fachada.
- Las líneas de detención van donde las pide el paso de cebra del juego, no donde están las reales.
- El espejo no refleja: es un disco de cristal claro con su aro negro y su dorso naranja.
- No se han puesto: las farolas de brazo de las fachadas (la del Salvador en la casa beige, dos en el piso de la clínica), los carteles de dirección y el semáforo siguiente de la avenida hacia el norte, una señal redonda de Cervantes al oeste de la clínica y un disco visto de espaldas junto a la clínica que no he identificado.

### Prueba

`python tools/run_tests.py cruce --timeout 400`: 5 ok. Comprueba que están las piezas, que cada llegada es un tramo del mapa abierto en ese sentido y para sobre su asfalto, que cada luz responde sola, que el ciclo propio nunca abre dos grupos a la vez ni deja cruzar ante coches en verde, que los 14 pies quedan fuera del asfalto y paran un rayo (capa 16, la del mobiliario), y que un puñetazo tumba una señal sin tocar las luces, tumba un semáforo y todo parpadea en ámbar, y `repair()` lo levanta. Hojas: `python tools/cruce/hojas.py cruce`.

## «Seguros Sopiss» (`godot/scripts/sopiss.gd`, `world.sopiss`)

Es la oficina real de Soliss Seguros. En el juego: «SOPISS · Seguros de toda la vida», con rótulos propios. Sin horneado: se construye sobre la casa `salvador_24` del mapa, que Texturas pasó a `["obra"]` en `casas_calles.gd` (su línea vieja está en las notas compartidas de Texturas).

### Medidas

- Contorno: la parte 1 de Catastro 4391002VJ5649S, tal cual. 16,43 m al Salvador, 8,51 m a la avenida y 5,14 m a Cervantes; la esquina del Salvador con la avenida es aguda (75°).
- Alturas medidas en las fotos, sobre la acera de la avenida: huecos de la oficina hasta 3,1 m; banda fucsia de 3,3 a 4,05; primer piso a 4,55; segundo a 7,9; alto del muro, 10,9 m. Es más alta por planta que las casas de alrededor, como en la realidad.

### Qué hay

- **A la avenida**: escaparate y entrada acristalada con marcos de madera sobre dos escalones; el panel blanco «La mutua de La Mancha»; la placa «Avenida Constitución»; dos balcones por planta; el letrero «Salamanquesa» entre los de arriba (el real es de otro negocio).
  - **El letrero es un neón**: azul de día y, de noche, luz amarilla, con algo de esa luz en la pared. Luis, 22/11: «El neon de salamanquesa podría brillar en amarillo por la noche». Se enciende y se apaga con el cielo (`sky_fx.night`), esté la oficina abierta o no (`set_neon`, `neon`, `neon_lamp`). El dibujo es blanco y el color lo pone `sopiss.gd`.
- **A la calle Cervantes**: un escaparate, la placa «Calle Cervantes» y un balcón por planta.
- **Al Salvador**: la ventana de la esquina bajo el final de la banda, el ventanal, la ventana esmerilada, el portal de hierro de los pisos, la caja de contadores y la bajante; arriba, por planta, tres balcones, una ventana con reja y un ventanuco de celosía.
- **Tejado** a cuatro aguas de teja vieja sobre alero ancho de madera, chimenea de ladrillo y una valla vieja «SEGUROS SOPISS» sobre su armazón (en la foto hay una valla ilegible ahí).
- **La oficina**, a la vista por los cristales, que son de verdad: mostrador con el frente fucsia, mampara con el nombre, tres mesas con pantalla y silla, archivadores, cuatro sillas azules de espera bajo el escaparate y una planta. No se entra: los muros son sólidos.
- Un azafrán escondido en el portal de los pisos (`"id": "sopiss"`, `"hidden": true`).

### Horario y luces

El de la oficina real, según Google Maps: **de lunes a viernes de 9:00 a 14:00 y de 17:00 a 20:00; sábados y domingos, cerrado** (`HOURS`).

- Abierta: lámparas encendidas, sala iluminada, banda con algo de luz propia y «ABIERTO» en la puerta.
- Cerrada: sala en penumbra y «CERRADO». La luz del juego llega al interior de día y de noche; por eso, con las lámparas apagadas, los colores de la sala se oscurecen (`DIM`). Sin eso, abierta y cerrada se veían igual.
- En el juego anochece a las 21:00, así que la oficina nunca está abierta de noche. La captura `_noche_luz` de la prueba fuerza las luces solo para verlas.

### Para Sistemas

Los personajes son de Sistemas (`sopiss_gente.gd`); aquí no se modela a nadie.

- `desk_spots`: `[agent_spot, client_spot]`, tras el mostrador y delante, cara a cara. También `agent_h` y `client_h`.
- `clean_spots`: una ronda de seis puntos por la sala.
- `floor_h`: el suelo de la oficina, 0,33 m sobre la acera. Está en `MapData.decks`: `MapData.foot(p)` da esa altura dentro.
- `is_open`, `open_at(day, hour)`, `set_open(on)`, `room` (el contorno de la sala), `door`, `portal`.
- Los muros son sólidos finos por el contorno, no un prisma macizo: quien está dentro no queda metido en un sólido.

### Lo que es aproximado

- El interior es inventado: una oficina verosímil. En las fotos solo se ven las sillas azules, una mesa y una persona sentada.
- El tejado es una reconstrucción: cuatro faldones con la misma pendiente. La medianera del fondo sube hasta 1,4 m por encima del alero.
- Las barandillas son todas del mismo dibujo (barrotes y una banda de aspas); las reales llevan volutas.
- La acera a cuadros crema y rojo de las calles laterales no está: la acera es la del juego.

### Pruebas de Sopiss

`python tools/run_tests.py sopiss`: 42 capturas y 4 comprobaciones (construido y con la casa cedida; las tres fachadas paran y los sitios de la gente están en el suelo de la oficina; las luces y el cartel siguen el horario, nada en la calzada, el azafrán; el neón es azul de día y amarillo de noche, y sigue al cielo). `_sopiss_checks()` va también en la completa.

## La casa beige del Salvador (`godot/scripts/beige.gd`, `world.beige`)

Luis, 22/11: «Vamos a tratar de terminar el cruce de los semáforos para poner definitivamente los semáforos». Es la última esquina. Sin horneado: se construye sobre la casa `salvador_c3` del mapa, que Texturas pasó a `["obra"]`.

### Medidas

- Catastro 4391110VJ5649S, de 1976, con siete partes. La casa son dos alas de una crujía en L alrededor de un patio: 12,59 m a la avenida (de 3,6 a 4,05 m de fondo) y 20,25 m al Salvador (de 4,9 a 6,5 m).
- Dos plantas: 6,25 m al alero, alféizares de arriba a 3,45 m.
- Vistas nuevas en `capturas.py` (las `g_`) y frentes `gs` (Salvador) y `ge` (avenida) en `mide.py`. Cámaras ajustadas con `fit=`: CN2 en (112,16, 51,62) y S1 en (100,17, 56,12). La cámara S2 de Google lee la pared medio metro más cerca de lo que está.
- El terreno es casi llano: 0,65 en el extremo oeste del Salvador, 0,88 en la esquina y 0,96 en el extremo norte de la avenida.

### Qué hay

- **A la avenida**: revoco beige sobre un zócalo rojizo gastado. El portal es hondo (0,9 m), encalado por dentro, con un escalón fuera y otro dentro y dos hojas oscuras con clavos al fondo. A cada lado, una ventana con reja negra; los tres huecos, en recerco blanco basto. Arriba, tres ventanas con la persiana bajada y barandilla de hierro. Cables a lo largo.
- **Al Salvador**: revoco gris sin pintar sobre un zócalo rosado. Cuatro ventanas con reja (la primera, de buche), una trampilla baja de madera, una rejilla de lamas y dos respiraderos. Arriba, una ventana estrecha y tres con barandilla. El tercio este de la fachada es ciego. Junto a la esquina, la placa «Calle Salvador» (`godot/assets/clinica/placa_salvador.png`, de `dibujos_clinica.py`).
- **El testero norte**, donde tiraron la casa vecina: muro desnudo con el yeso blanco de la habitación perdida, bordeado de ladrillo roto, con mechinales y desconchones. Lo sucio se queda sucio.
- **El tejado**: alero de dos escalones bajo bocateja vieja. Cada ala tiene dos aguas, a su calle y al patio, con limatesa en la esquina y un hastial en cada extremo.
- **En el patio**: una nave trasera de ladrillo visto, un cobertizo bajo de uralita y dos naves al fondo de la parcela (las otras piezas de la casa en el mapa). Todas lisas.
- **La tapia del solar**, al norte: bloques grises de 2,4 m que escalonan con el terreno. Junto a la casa, un machón y la cancela de chapa roja con su placa amarilla; sigue por la avenida, dobla la esquina y recorre la calle de Colón hasta la última nave de la parcela.
- No se entra. **Sin azafrán**: propuesto a Luis en el fondo del portal hondo de la avenida; no se pone hasta que él lo diga.

### Lo que es aproximado

- El tejado está reconstruido a partir de una sola foto (el hastial del testero norte): la ortofoto no lo deja ver.
- Las ventanas del Salvador pueden estar medio metro corridas: la calle es estrecha y las cámaras leen mal las distancias.
- Barandillas y rejas son lisas.
- Las naves del patio son cajas con una sola agua.
- La tapia real tiene en la esquina un tramo de malla y hierbas al pie: aquí es de bloque toda ella y está limpia.

### Prueba

`python tools/run_tests.py beige`: 14 capturas (sin tráfico) y 2 comprobaciones (construida, con 14 huecos, 6 barandillas, la casa cedida y los tejados enteros; las dos fachadas y la tapia paran, no hay azafrán y nada de lo que pisa el suelo toca la calzada). `_beige_checks()` va también en la completa.

## La casa crema del mirador (`godot/scripts/mirador.gd`, `world.mirador`)

Luis, 22/11, tras aprobar Santa Ana 2: «No se pone Azafrán. Visto Bueno. Siguiente». Sin horneado: se construye sobre la casa `constitucion_2` del mapa, que Texturas pasó a `["obra"]`.

### Medidas

- Catastro 4491809VJ5649S, de 1925: 10,3 m a la avenida, un chaflán de 4,15 m y 9,8 m a Santa Ana. Tiene forma de U alrededor de un patio abierto al este.
- Es alta: 8,3 m a la cornisa, con dos plantas de techo alto sobre un semisótano. Los alféizares de abajo quedan a 1,8 m.

### Qué hay

- **En el chaflán**: el portal tras una cortina marrón, en recerco ocre y sobre un escalón; encima, el mirador, un cuerpo cerrado sobre molduras con su persiana blanca y una barra negra.
- **A la avenida**: tres ventanas con reja negra y recerco ocre, las rejillas del semisótano en el zócalo, la placa «Avenida Constitución»; arriba, un balcón de antepecho macizo con barandilla negra ante dos puertas, y una ventana con dos barras.
- **A Santa Ana**: otras dos ventanas con reja bajo otro balcón igual y la placa «Calle Santa Ana». Después, la parte este, blanca: el portón de arco de medio punto, de madera con clavos y recerco ocre, y una galería de ventanas de madera encima.
- **Zócalo, recercos, balcones y cornisa** en ocre sobre revoco crema. El tejado casi no se ve desde la calle, como en la realidad.
- El acerado llega hasta sus paredes: lo pone `mirador.gd` en una franja ante el chaflán y Santa Ana, porque el del pueblo se quedaba corto y asomaba tierra. Cada punto de la franja sale de la pared hasta el bordillo (`_to_kerb()`, a pasos de 10 cm).
- No se entra. **Sin azafrán**: propuesto a Luis tras el portón de arco; no se pone hasta que él lo diga.

### Lo que es aproximado

- La parte este de Santa Ana es más baja en la realidad y tiene alero de teja; aquí llega a la misma altura que el resto.
- El tejado es una reconstrucción con cinco faldones; el patio queda como un hueco entre muros.
- Las rejas son lisas, con una fila de anillas abajo; las reales llevan volutas.

### Prueba

`python tools/run_tests.py mirador`: 12 capturas (sin tráfico: `g.traffic.clear()` antes de cada una) y 2 comprobaciones (construida y con la casa cedida, el tejado entero; las fachadas paran, no hay azafrán y el acerado propio no pisa la calzada). `_mirador_checks()` va también en la completa.

## La casa blanca de Santa Ana 2 (`godot/scripts/stana2.gd`, `world.stana2`)

Luis, 22/11, con una captura de Street View: «Vamos a tratar de terminar el cruce de los semáforos para poner definitivamente los semáforos. El siguiente será Calle Santa Ana, 2». Sin horneado: se construye sobre la casa `constitucion_a1` del mapa (sus dos anillos), que Texturas pasó a `["obra"]`.

### Medidas

- Catastro 4690001VJ5649S: 15,0 m a Santa Ana y 4,7 m a los Arcos; detrás, un patio y una construcción aparte de dos plantas.
- Es una casa baja: 5,75 m al alero. Portón de 1,55 × 2,45 m; ventanas de un metro de ancho.
- El terreno del juego baja 20 cm del extremo este a la esquina: el zócalo y los huecos de abajo lo siguen.

### Qué hay

- **A Santa Ana**: en el extremo este, el portón de madera clara con clavos negros bajo una reja de barrotes torneados, entre jambas añil; dos ventanas con reja negra; arriba, tres ventanas de marco añil con persiana marrón y balconcillo de hierro; el tercio oeste, ciego. Dos cables por la fachada y tres desconchones sobre el zócalo.
- **A los Arcos**: una ventana con reja, un portal tras una cortina morada entre jambas añil, una ventana arriba y la placa «Calle Arcos».
- **Zócalo** de mampostería oscura; **cornisa** de molduras blancas con las bocas de las tejas; teja vieja con la esquina a cuatro aguas; chimenea blanca alta.
- La construcción del fondo, lisa, con un faldón de teja.
- Sin número de casa. No se entra.
- **Sin azafrán**: propuesto a Luis junto al portón, y dijo que no (22/11: «No se pone Azafrán»).

### Lo que es aproximado

- La parte de atrás (patio y construcción del fondo) no se ve desde la calle: es un volumen liso.
- El tejado es una reconstrucción con tres faldones.
- La placa de la calle es la misma que la de la clínica de enfrente.

### Prueba

`python tools/run_tests.py stana2`: 12 capturas y 2 comprobaciones (construida y con la casa cedida, los tejados enteros; las fachadas paran y no hay azafrán). `_stana2_checks()` va también en la completa.

## «Clínica Dental» (`godot/scripts/clinica.gd`, `world.clinica`)

Luis, 22/11: «Vamos con el dentista. Lo llamaremos "Clínica Dental" y "Dr. Josué Escudero"». Es el Centro Clínico Dental real. Sin horneado: se construye sobre la casa `arcos_2` del mapa, que Texturas pasó a `["obra"]`.

### Medidas

- Contorno: Catastro 4390018VJ5649S. 12,7 m a la calle Cervantes y 9,0 m a los Arcos. **La esquina se construye viva**, como en las fotos; el contorno de Catastro (y el de la casa en el mapa) la tiene achaflanada un metro.
- Dos plantas: piedra oscura hasta 3,75 m, piso a 4,0 m, alto del muro 6,75 m.

### Qué hay

- **Abajo**: piedra marrón oscura en baldosas grandes, con tiras finas de acero. Letras de acero claro en relieve, «CLÍNICA DENTAL» (una línea a Cervantes, dos a los Arcos), y debajo «Dr. Josué Escudero». Un diente con una sonrisa junto a la esquina, en vez del logotipo y el teléfono reales.
- **A la calle Cervantes**: las puertas de lamas grises del cuarto de máquinas, la puerta de cristal de la clínica con una franja verde, y dos ventanas de cristal de espejo con las palabras en verde y blanco.
- **A los Arcos**: una ventana de espejo, la placa «Calle Arcos» y, pasada la piedra, el portal de la casa entre machones de granito gris en un paño de azulejo crema, tras una cortina rosa.
- **Arriba**: revoco crema, el balcón corrido de chapa oscura acanalada que dobla la esquina, tres balcones de forja con chapa detrás y persianas blancas.
- **Tejado**: teja vieja con la esquina a cuatro aguas, hastial en la medianera oeste y alero de madera con canecillos juntos.
- Sin azafrán: hubo uno en el portal de la casa, tras el borde de la cortina, y Luis lo mandó quitar.
- No se entra y no se ve nada por los cristales: son de espejo, como los reales.

### Horario y luces

El de la clínica real, según Google Maps: **de lunes a viernes de 9:00 a 13:30 y de 16:30 a 20:00; sábados y domingos, cerrado** (`HOURS`).

- Abierta: una luz cálida y tenue en los cristales. De día casi no se nota; Luis no la pidió, es añadido mío.
- De noche las letras quedan iluminadas (`set_night`, sigue a `sky_fx.night`), esté abierta o no.

### Lo que es aproximado

- Las palabras de los cristales y el diente son dibujos propios.
- Las barandillas de forja son de aspas, no de volutas.
- La acera a cuadros de la calle Cervantes no está: la acera es la del juego.

### Prueba de la clínica

`python tools/run_tests.py clinica`: 22 capturas y 2 comprobaciones (construida y con la casa cedida, el tejado entero; las fachadas paran, los cristales siguen el horario, las letras se iluminan de noche y no hay azafrán). `_clinica_checks()` va también en la completa.

### Trampas

- En el shell de esta máquina, un script escrito con heredoc falla si lleva un número impar de comillas simples o tildes: se escribe como archivo.
- La piedra clara sale parda con `granular_concrete`: el zócalo usa el revoco crema con `_glow`.
- Lo que está en `yard` es lo que pisa el suelo fuera del muro. En el Salvador y en Cervantes la calzada del juego llega hasta la fachada: ahí no puede sobresalir ni un escalón.
- Una cámara de prueba a 7 m de la fachada cae dentro de la casa de enfrente: las calles laterales son estrechas.
- Una caja del tamaño de la losa puesta debajo de un balcón le pinta todo el fondo de su color: el goterón es un cordón fino en el borde.
- Un cristal de espejo con luz propia de día sale gris claro y pierde el reflejo: la luz de «abierto» tiene que ser muy tenue (0,07).
- `obra.gd` ya tiene las constantes `IRON`, `STONE` y `DEEP`: un edificio no puede declarar otra con el mismo nombre.
- En las esquinas anchas el acerado del pueblo no llega a las fachadas y asoma tierra naranja. Se tapa con un acerado propio (`W._tmat(…, "pavement", 1.4)`), que busca el bordillo punto a punto (`_to_kerb()` en `mirador.gd`; a ojo se metía 0,83 m en la calzada) y con sus vértices en `yard` para que la prueba compruebe que no la pisa.
- `_inset()` cruzaba dos aristas casi en línea con retranqueos distintos a cientos de metros: salía una barra larguísima atravesando la avenida. Ahora, si las dos aristas son casi paralelas, usa el punto de la segunda. Pasa cuando un vértice del contorno está en la prolongación de un muro (los puntos `PE` y `QS` de la casa beige).
- Pasar una casa a `["obra"]` hace que `casas.gd` deje de dibujar **todas** sus piezas del mapa: el edificio hecho a mano tiene que poner también las naves del patio y del fondo de la parcela (`_block()` en `beige.gd`).
- Una tapia a lo largo de una calle no puede llegar hasta la esquina siguiente a ojo: `_plot_reach()` (`beige.gd`) avanza hasta metro y medio antes del bordillo de la calle que viene, y sus puntos van en `yard` para la prueba.
- `white_rough_plaster` teñido de gris sale a manchas grandes en una fachada larga: el cemento sin pintar va con `painted_plaster_wall`.
- Semáforos: `slab()` no tiene cara trasera. Una chapa que se ve por detrás lleva su dorso dibujado en el marco girado media vuelta (`_sheet()` en `cruce.gd`).
- Pintura de calzada desde un archivo propio: no se usa `W._flat` (su caché va por posición). Va con piezas propias a +0,026 sobre el suelo, en trozos de un metro como mucho, para seguir el relieve.
- El brazo del báculo tiene un largo fijo. Atado al `stop` de Santa Ana, se fue al centro de la calle cuando Sistemas la hizo de sentido único.
- Cada lente es un material por calle y color (`luz_2_rojo`): `_commit()` hace una malla por material, y cambiar el material cambia a la vez todas las cabezas de esa calle.
- `mide.py` da mal los metros a lo largo de una fachada para algo que vuela de ella (una cabeza en escuadra): se mide el pie de la escuadra en la pared.
- Una prueba que juega con las luces las guarda y las repone (`lights()`, `put_back()`), y en su modo de fotos aparta `game.semaforos`: el controlador solo manda una luz cuando cambia.
- Piezas que se rompen: cada una se dibuja con una función guardada (`make`), que `repair()` vuelve a llamar. Mientras se dibuja, `_base` lleva el marco del lugar al del cuerpo (`home()` y `_look()` lo aplican) y `_text()` cuelga el rótulo del cuerpo. Los contadores de la prueba se guardan y se reponen en `repair()`.
- Un parámetro de una función guardada no puede llamarse como una variable de fuera: todas usan `f`.
- En GDScript 4, comparar un String con un bool con `!=` es un error en cada fotograma, no un `true`: una lista que guarda «"dark" o un bool» necesita comparar antes los tipos.
