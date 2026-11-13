# Líneas de misiones y Puntos Cívicos — diseño (palabras del usuario, 13 de noviembre de 2026)

> En vez de «muertos» o «golpeados» (la puntuación que tenemos arriba a la derecha que no es dinero ni azafrán) las
> vamos a cambiar por P.C. (Puntos Cívicos).
>
> **Misiones principales**: las que hacen avanzar la historia. Una sola línea de misiones secuencial.
>
> **Misiones secundarias**: distintos personajes con distintas líneas de misiones secuenciales individuales. Por
> ejemplo, al completar la del móvil de V.I.P. y hablar con Josefa te añadirá al final que «se conoce todos los
> negocios del pueblo» y que vayas a hablar con ella si quieres más recados. Esto desbloqueará su línea secundaria de
> misiones de Josefa, en la que irás conociendo y desbloqueando negocios. Terminar la de V.I.P. desbloqueará todas las
> tiendas de informática (de momento solo V.I.P.); su siguiente misión será una de ir a recogerle un menú a La Cocina
> de Henry (de momento será recoger el jamón asado y volver a dárselo; en el futuro quiero que «Recoger el jamón
> asado» sea un minijuego) y al completarla desbloqueará todos los restaurantes (como todos los kebabs, lo que
> desbloqueará la línea de misiones de Don Luis).
>
> Terminar la misión de Alberto te dará P.C. por primera vez (1 punto por cada firma conseguida más 5 puntos de firmas
> que ha conseguido Alberto); aquí te hará un tutorial explicándote que haciendo favores a la gente, aparte de dinero,
> puedes conseguir puntos cívicos que puedes utilizar para transformar el pueblo, y como ejemplo te pondrá que gastes
> los 10 puntos que ya tienes en «desbloquear» el puente. Te acercas, pulsas botón de acción y lo desbloqueas, con lo
> que ya se puede andar por él y «se evita» que lo derrumben (en la historia del juego).
>
> A partir de aquí las misiones principales dan 5 P.C., las secundarias 3 P.C. y los minijuegos 1 P.C. Luego habrá
> otra serie de misiones recurrentes que será **Trabajos**, pero estas solo darán dinero.

## Lo que contestó al preguntarle
- Un negocio sin desbloquear está **cerrado para ti**: no vende nada y de él no salen recados (Don Luis solo charla).
- **El jamón de los jueves se queda** como secundaria recurrente y da 3 P.C. cada entrega a tiempo.
- Minijuegos: **1 P.C. la primera victoria de cada día** del juego.
- Las secundarias hechas antes del tutorial de Alberto **se pagan al llegar** a él (se guardan a cuenta).

## Lo construido
- **Marcador**: donde salían los atropellados sale ahora P.C. (icono de escarapela). No se enseña hasta que Alberto
  los explica. Los atropellos se siguen contando por dentro para la pantalla final.
- **Negocios** (`game.gd` `negocio()`, `missions.gd` `BUSINESSES`): informática, al acabar la misión del móvil;
  restaurantes, al acabar el recado de Josefa. Sin restaurantes: Henry y Don Luis solo charlan y no hay llamada de los
  jueves. Con ellos: los dos venden, Don Luis te cuenta su misión la primera vez que le hablas y después la tiene en
  el mostrador («¿No tenías un recado pa mí?»).
- **Línea de Josefa** (`missions.gd` `LINES`): «El menú de la Josefa» — a La Cocina de Henry a por el jamón asado y
  vuelta, sin reloj. Paga 20 €, +10 de confianza, 3 P.C. Se puede rechazar como cualquiera. El jamón hay que
  ganárselo en el motín (abajo).
- **Alberto**: al entregar las firmas explica los P.C. y te da 5 + 5 (más lo que se te debiera). Paso nuevo de la
  misma misión, `puente`: el puente está vallado por el ayuntamiento («PROHIBIDO EL PASO») y no se puede pisar; te
  acercas, botón de acción, 10 P.C., cae la valla y se cruza andando. Ahí se da la misión por cumplida.
- **P.C. por misión**: principal 5 (clave `pc` del paso para decir otra cosa), secundaria 3, minijuego 1.
- **Trabajos**: sin hacer; no hay ninguno escrito.

## Decisiones mías, por confirmar
- Con el puente vallado tampoco se pasa por la calle de debajo a pie (andando, el puente era un escalón de la propia
  calle): hay que dar la vuelta a la manzana hasta desbloquearlo.
- La Chiki sigue subida al puente, dentro de la valla.
- Al desbloquear informática no cambia nada en V.I.P. (el boxeo con Fonsi sigue abriéndose como antes): solo queda
  apuntado en la Agenda.
- Los diez euros de la hucha de Alberto se cobran al entregar las firmas; la misión se sella al desbloquear el puente.
- La Agenda (Secundarias) enseña cada línea, los negocios que conoces y tus P.C.

Pruebas: `--selftest --civicos` (con `--shots`, fotos).

---

# El motín del jamón asado — minijuego (palabras del usuario, 13 de noviembre de 2026)

> El juego de recoger el jamón asado tiene varias partes. Primero, todos los jueves habrá bastante gente amotinada
> cerca de la cocina de Henry porque quieren el jamón asado. Cuando te acerques empezará una cinemática en la que
> Henry sale de la tienda y habla con los clientes diciendo que son demasiados los que quieren jamón y no hay jamones
> para todos, así que habrá que hacer «lo de siempre»: cortes cercanos a vecinos sacando armas cortas (bates con
> clavos, cuchillos, puños americanos); «ya sabéis cómo va, los que queden en pie tendrán jamón asado», dice Henry
> (las cinemáticas tienen que tener tensión y planos de duelo del oeste, rollo El bueno, el feo y el malo).
>
> El minijuego: la primera vez que hagas la misión Josefa te «dará» un bate (no aparece, solo se menciona) y te dirá
> que ya sabrás para qué es, que en cada pueblo hay ciertas costumbres. En la cinemática, al final, saldrá tu
> personaje alzando el bate, la cámara pasará a encima del hombro y empezará el minijuego. Tendrás que dejar
> inconsciente al mayor número de vecinos posibles. Ellos también estarán atacando, será un todos contra todos, pero
> tu personaje siempre tendrá el aggro de 2 vecinos (el heat level de los pitufos se desactiva durante el minijuego);
> todos los vecinos tendrán una barra de vida de 100 puntos y cada golpe que reciban les quitará 25, llegar a 0 les
> deja inconscientes; al jugador le pueden derribar pero no tiene vida, es una prueba de velocidad, ya que tendrás 60
> segundos. Tiene que haber en todo momento al menos 10 vecinos activos peleándose; si hay menos, spawnean de los
> cruces de las calles y van directos a la zona de pelea. La puntuación del minijuego será +5 por golpe acertado, +10
> por golpe de gracia (dejar inconsciente). Completar el minijuego solo dará puntuación de minijuego, pero al
> terminar Henry te felicitará por lo bien que has atizado a la gente con el palo («se te tiene que dar de miedo
> coger aceituna»). Llevar el jamón asado al vecino dará 20 € y P.C. correspondientes.

## Lo que contestó al preguntarle
- La primera vez es cuando se activa el recado de Josefa, sea el día que sea; al terminar, Josefa te dice que «hoy era
  un día especial, pero normalmente todos los jueves son el día del jamón asado y siempre se repite esa cantinela».
  Desde entonces es un minijuego activo todos los jueves.
- El jamón de los jueves **ya no tiene reloj**.
- La pelea da **1 P.C. como minijuego** (la primera del día).
- Se juega en el primer recado y todos los jueves; se puede repetir desde la Agenda, pero ahí **no da P.C.**

## Lo construido (`godot/scripts/motin.gd`; prueba `--selftest --motin`)
- 14 vecinos esperan delante de Henry (gritando «¡Jueves, jamón!») cuando hay recado de jamón, o los jueves de 8 a 21
  una vez jugado por primera vez, hasta que juegas el de ese día. Te acercas a menos de 13 m y empieza.
- Cinemática: plano general bajo de la calle; Henry en su puerta por encima de las cabezas («…lo de siempre»); tres
  primeros planos de manos sacando arma (bate con clavos, cuchillo, puño americano); seis planos de ojos cada vez más
  cortos; Henry («los que queden en pie tendrán jamón asao»); tú alzando el bate.
- Pelea: cámara sobre el hombro derecho, 60 s, barra de vida sobre cada vecino (100; −25 por golpe), siempre dos a por
  ti, refuerzos desde los cruces para que no bajen de diez, Pitufos desactivados. No se puede salir de la calle (15 m).
- Tu golpe (botón de puñetazo) alcanza a quien tengas delante, dos como mucho. Si te derriban estás 1,6 s en el suelo.
- Al acabar: Henry («…se te tiene que dar de miedo coger aceituna»), puntuación guardada (Agenda → Minijuegos:
  «Recoger el jamón asao»), 1 P.C. si es la primera del día, y el jamón en la mano si ibas a por él.
- Entregar un jamón (a Josefa o al vecino del jueves): 20 € y 3 P.C.

## Decisiones mías, por confirmar
- El golpe de gracia vale 10 en total, no 5 + 10.
- Los vecinos aciertan a otro vecino el 60 % de las veces y te derriban a ti el 40 % (con 1,4 s de respiro al
  levantarte).
- No hay niños en la pelea.
- Sin recado, los jueves la pelea se juega una vez; con la llamada del jueves hay otra más ese mismo día.
- La «música» de la cinemática son solo tonos de tensión hechos en el juego: no he imitado ninguna banda sonora real.
