# Un torneo en los Galaxy Recress — línea de Civismo (palabras del usuario, 13 de noviembre de 2026)

> Nueva misión secundaria de la serie de Civismo (iniciada por el puente y Alberto). Tras finalizarla, esta nueva se
> podrá activar hablando con Alberto; si no lo haces, a las 12 horas in-game te llamará él. Te dice que qué tal llevas
> las actividades cívicas y si has hecho mucho por el pueblo (su personalidad es en parte que le gusta mucho «lo de
> pueblo» aunque vive fuera, en capitales, el 90 % del tiempo). Te dice que por desgracia el pueblo está un poco
> abandonado de actividades cuando no son fiestas y que le vendría muy bien algo de vidilla (cinemática enfocando
> zonas «malas»: sucias, sin terminar su actividad de civismo, edificios especiales cerrados — el puente, el de esta
> misión, y la antena de comunicaciones y urgencias como ejemplos). Le salta una estrella en la cabeza de tipo eureka
> con un sonidito y te habla de los Galaxy Recress, un centro recreativo donde la gente iba a jugar videojuegos hasta
> mediados de los 2000 y que lleva unos 20 años cerrado. Se os ocurre un torneo de Tokken 9, el juego de lucha del
> momento. Tres partes:
>
> 1. El alcalde, en el ayuntamiento (NPC genérico en la puerta, de momento), sin acento manchego, hablando en
>    «político»; al final reconoce que no hay dinero: el único modo es que lo pongas tú; si no lo tienes, te espera
>    ahí. El dinero se recupera x2 al terminar. Pagado, te manda a la copistería a por carteles; él irá llamando a gente.
> 2. La copistería (NPC genérico en la puerta, de momento): el alcalde ya ha llamado; raro que paguen por adelantado,
>    pero no se queja; te da los carteles (x5); ella es más de ver Nerflis; te recomienda cinco comercios. Los objetos
>    de misión salen en verde con contorno en las conversaciones y los objetivos en rojo con contorno negro.
> 3. Pegado el último cartel, Alberto te llama: hay muchísima gente. Fundido, gente en las puertas y un cartel del
>    torneo a cada lado. Alberto te saluda; el alcalde ha llamado a gente y pegado carteles. Dentro (transporte como la
>    trastienda de V.I.P.): máquinas, gente jugando y picándose; paneos de las pantallas. Final: Katakumba69 contra
>    DoomAssasin78, «más conocido como el alcalde». «¿Qué? Yo nací siendo alcalde…». Gana el alcalde, confeti. «Esto
>    me ha sabido a poco»: te reta a doble o nada; puedes negarte pero todos te vacilan (Alberto, y una señora: «¡¡Revientale
>    la puta cara!!» — «Mamá, por favor, aquí no») hasta que aceptas. La partida de Tokken 9 se queda de momento en
>    «te acercas, pulsas Acción y ganas». Final: el alcalde no se lo cree; campeón; confeti; suena Traktor FM bajito.
>    De noche, fuera, su mujer: «En 30 años no te he visto perder ni una vez a ese juego»… «Ya… Jeje»… «Creo que el
>    pueblo se va a animar mucho a partir de ahora…». La cámara sube a la luna. Fundido, tú en la puerta: misión
>    cumplida. Los recreativos quedan reabiertos.

Y además, en el mismo mensaje:

> - Si alguien tiene que llamarte y no lo consigue te dará una hora in-game antes de volver a intentarlo; si mientras
>   te llaman te intenta llamar otra persona, espera a que cuelgues y te vuelve a llamar a los 10 minutos in-game
>   llamándote «Don Ocupado» o «¿Qué pasa, que no tienes cobertura?» o «¿Con quién hablabas, con tu novia/o?».
> - Los NPCs que tengan una misión para ti tendrán un marcador en el mapa con la «foto DNI» en un círculo de outline
>   negro, y una pequeña flecha verde 3D girando sobre él, invisible a más de 30 m y al 100 % según te acercas.

## Lo construido

- **Centralita** (`godot/scripts/llamadas.gd`): todas las llamadas pasan por ella. Suena 22 s; si no lo coges, se
  apunta la llamada perdida (como antes, −1 de confianza) y vuelve a llamar a la hora de juego (salvo las que solo
  tienen sentido una vez, como la de Don Luis diciéndote que vuelvas, si ya te está esperando). Si comunica, espera a
  que cuelgues y llama a los 10 minutos de juego empezando por «¡Hombre, Don Ocupado!», «¿Qué pasa, que no tienes
  cobertura?», «¿Con quién hablabas tanto rato, con tu novia?» o «Comunicando, comunicando…». Prueba: `--selftest --llamadas`.
- **Marcas** (`godot/scripts/marcas.gd`): quien tiene una misión para ti (la historia, Josefa, Don Luis, Alberto, el
  alcalde esperando el dinero) sale en el minimapa y en el mapa grande con su foto de carné en un círculo con borde
  negro, y lleva encima una flecha verde que gira: no se ve desde más de 30 m y está entera a 10 m. Prueba: `--marcas`.
- **Textos de misión**: en los diálogos, `*objeto*` sale en verde con contorno y `#objetivo#` en rojo con contorno negro
  (`loc.gd` `rich`).
- **Los recreativos** (`recress_sala.gd`): el local con el rótulo RECREATIVOS y la persiana de la Calle de Zaragoza
  (la casa que el Catastro numera 8: la construyó así la sesión de texturas, pegada a la 10). Encima, «GALAXY RECRESS»
  apagado hasta que reabre; luego, encendido, con la persiana subida. Dentro (un decorado en el campo, como el de
  V.I.P.): ocho máquinas con sus pantallas, la máquina de la final con dos taburetes y una pantalla grande para el
  público, el rincón del comentarista, luces de colores y cañones de confeti.
- **La misión** (`recress.gd`): todo lo de arriba, con estas piezas:
  - Alberto: en persona, la escena entera (los rincones tristes: una cuba de escombros, el puente, los recreativos, la
    antena, urgencias; la estrella; el paneo a los recreativos). Por teléfono, a las 12 horas, solo te pide que pases
    a verle.
  - El alcalde: discurso de político; sin dinero, la misión queda en pausa (el resto del pueblo, tuyo) y él te espera
    con su marca en el mapa.
  - La copistería: Calle Teniente Infante (Catastro 4190004VJ5649S); te da cinco carteles. Sirven para cualquier comercio:
    los del mapa (supermercados, farmacias, librerías, bares, la peluquería, talleres), los del juego (V.I.P., Henry,
    el kebab, el quiosco) y las tiendas con rótulo de las casas hechas a mano. E delante de la fachada y se pega.
  - El torneo, la final, el reto (negarse una vez trae la de la madre), la partida (E en la máquina = ganas), el final
    con Traktor FM bajito, la noche con la mujer del alcalde y la luna, y tú en la puerta: misión cumplida.
  - Dentro no suena música hasta que te declaran campeón: entonces, Traktor FM bajito.
  - Después los recreativos están abiertos: se entra por la persiana como en V.I.P.; Katakumba69 se queda allí, con
    unos cuantos más jugando en las máquinas; las máquinas dicen «Tokken 9 todavía no se puede jugar: muy pronto».
- **La estrella del eureka** (`tools/make_eureka.py` → `assets/recress/eureka.png`): dibujada aquí, con su «ding» de
  tres notas hecho en el juego. No se ha copiado nada de Animal Crossing.
- **Pantallas**: las dos imágenes que mandaste llegaron como fotos fijas (el chat convierte los GIF). Se mueven con un
  efecto propio: barrido de tubo, parpadeo, golpes con destello y temblor, y cada máquina alterna entre las dos.
- **Cámara de las escenas** (idea del usuario): en cualquier cinemática del juego, si la cámara queda dentro de la cabeza
  de alguien o a un palmo, ese personaje no se dibuja mientras siga tan cerca (`game.gd` `_clear_lens`). Para el juego
  sigue ahí (habla, grita, cuenta). Las cabezas miden casi un metro, así que los primeros planos van a unos 2 m. En la
  calle de los recreativos, los coches aparcados delante no se ven mientras dura la escena (luego vuelven).
- Prueba de la misión entera: `--selftest --recress` (con `--shots --window`, fotos en `godot/shots/recress_*.png`).

## Decisiones mías, por confirmar

- **Dinero**: el alcalde pide **50 €** (provisional). Al final te lo devuelve x2 (el premio del torneo), y como le
  ganas a doble o nada, el doble: **200 €** en total. Más 3 P.C. de misión secundaria.
- **El local**: uso la tienda de RECREATIVOS que ya estaba hecha (casa 8 según el Catastro) en vez de la 10.
- **Por teléfono**: la llamada de las 12 horas no repite la escena; Alberto te pide que vayas a verle y allí te la cuenta.
- **Si pierdes** la partida, el alcalde te dice «¿Otra?» y vuelves a sentarte (de momento no se puede perder).
- **Nombres provisionales**: «El alcalde», «La de la copistería», «La mujer del alcalde», «Una señora mayor» (su madre:
  no se dice hasta el «Mamá, por favor»), «El comentarista», «Katakumba69».
- Los GIF de las pantallas: si los dejas en `referencias/recress/`, saco sus fotogramas y van animados de verdad.
