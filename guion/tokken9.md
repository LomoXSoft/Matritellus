# Tokken 9 — el juego de las máquinas de los Galaxy Recress

> Palabras del usuario (13 y 14 de noviembre de 2026): «Tokken 9 es un juego de peleas estilo Tekken pero con
> personajes históricos o fantásticos con superpoderes.» Las pantallas de las recreativas son sus seis GIF
> (`referencias/recress/Tokken9_*.gif`). «100 €, devuelve 200 €. […] Puedes proceder con Tokken 9.»

## Lo construido

- **El juego** (`godot/scripts/tokken.gd`): lucha en 2D de lado, al mejor de tres asaltos de 99. Ocupa toda la pantalla
  mientras dura (la fase `"tokken"` de `game.gd`; el pueblo no se dibuja debajo).
- **Luchadores**: los seis de los GIF 1, 2 y 3, recortados de los propios GIF con sus ocho poses cada uno
  (`tools/make_tokken.py`, con OpenCV → `godot/assets/tokken/`). Cada uno tiene su poder:

  | Luchador | Cómo es | Poder |
  |---|---|---|
  | Cleopatra | rápida, golpe rápido muy corto | Rayo de Isis (se lanza; se salta) |
  | Napoleón | equilibrado | Cañonazo imperial (se lanza, rápido) |
  | El Samurái | lento, el de más alcance | Corte de luna (cruza el escenario con la espada) |
  | Drácula | equilibrado | Nube de murciélagos (se lanza, lenta y grande) |
  | El Monstruo | lento, pega y aguanta más que nadie | Diez mil voltios (corre por el suelo: hay que saltarlo) |
  | Velocirraptor | el más rápido, pega y aguanta poco | Salto del Cretácico (se te echa encima) |

- **Escenarios**: los tres de esos GIF (Egipto, Japón, el castillo), limpios de luchadores y ensanchados al triple.
- **Controles** (las mismas acciones del resto del juego, así que valen teclado, mando y táctil):
  - izquierda/derecha: moverse; hacia atrás, además, te cubres;
  - arriba: saltar;
  - Golpe (clic / X): **rápido**; Acción (E / A): **fuerte**; Freno (Espacio / B): **PODER**, con su barra llena.
    Con solo teclado valen también J, K y L;
  - Pausa: para; desde ahí se puede dejar la partida (cuenta como perdida).
  - En el móvil los botones dicen «Rápido» (el grande), «Fuerte» y «Poder»; el caso de `touch.gd` lo añadió la sesión
    principal. No está probado en un móvil de verdad.
- **Lo que hay que aprender**:
  - el rápido es corto y seguro; el fuerte llega más, quita más y te deja vendido si fallas;
  - cubrirse lo para todo, pero gasta la guardia (la barra fina); a cero, «¡Guardia rota!» y te quedas viendo estrellas;
  - **combos y cancelaciones**: un rápido que entra se cancela en un fuerte si lo pulsas enseguida, y el segundo ya
    no se puede parar; un fuerte que entra se cancela en el poder. Lo dice la pantalla al empezar.
- **El alcalde** (DoomAssasin78, con El Monstruo, como en la final): se cubre bien y castiga los fallos, pero juega
  como en los ochenta. No hace cancelaciones y, sobre todo, baja la guardia después del primer golpe: el fuerte
  cancelado le entra siempre. Es justo la excusa que pone cuando pierde.
- **La partida de la misión**: E en la máquina de la final abre el juego; eliges luchador. Si pierdes (o lo dejas), el
  alcalde dice «¿Otra? Cuando usted quiera» y vuelves a sentarte; si ganas, la misión sigue como antes.
- **Partida libre**, con los recreativos abiertos:
  - en la máquina grande, contra **Katakumba69** (Drácula, y es bueno). Jugar con él le sube la confianza (+5 la
    primera vez, +1 después), como cualquier minijuego con un vecino;
  - en las demás, contra la máquina: cada victoria seguida sube un escalón de dificultad; si pierdes, vuelta a empezar.
- **Letras**: una tipografía de puntos hecha aquí (`tokken_letras.gd`), con tildes y eñe.
- **Pruebas**: `--selftest --tokken` (con `--shots --window`, fotos en `godot/shots/tokken_*.png`). Juega por ti contra
  un rival quieto para comprobar cada cosa, y luego hace jugar a la máquina contra sí misma, sin pantalla, para medir
  al alcalde. `--selftest --tokken --balance` enfrenta a todos contra todos.

## Dificultad medida

La máquina jugando contra sí misma (40 partidas cada caso; el «novato» no sabe cubrirse bien ni hace combos, el
«jugador» sí):

- contra el alcalde: el novato gana unas 3 de cada 10 partidas; quien usa el combo, unas 8 de cada 10;
- contra Katakumba69: quien usa el combo gana 1 de cada 10;
- entre los seis luchadores, con la máquina llevando a los dos: ninguno baja de 30 victorias de 72 ni pasa de 49
  (el samurái y el raptor salen algo por encima; Napoleón y El Monstruo, algo por debajo).

No lo ha probado nadie con las manos todavía: los números son de la simulación.

## Decisiones mías, por confirmar

- **Quién lleva a quién**: el alcalde, El Monstruo; Katakumba69, Drácula. Así la final que se ve en la pantalla grande
  (Drácula contra el monstruo, tu GIF 3) es la que cuenta la historia.
- **Los luchadores de los GIF 4, 5 y 6 no están**: el 4 recuerda demasiado a Pikachu y a Agumon; el bebé contra la bomba
  y el gorila contra cien hombres no son un uno contra uno.
- **Nombres de los poderes** y de «El Samurái», «El Monstruo» y «Velocirraptor».
- **La partida libre es gratis**: no hay que echar moneda.
- **En tu partida juegas a la izquierda**, aunque en la sala te sientas en el taburete de la derecha.
- **Solo ocho poses por luchador**: no hay dibujo de salto ni de agacharse (saltan con una de las que tienen), y al
  samurái no se le ve la hoja en dos de las poses de ataque.
