# Referencia: el kebab de la calle Santa Ana («Tele Dürum»)

Pedido por Luis el 15-11-2026: «Podemos proseguir con el Kebab de la calle santa ana, el Tele Kebab) lo llamaremos
Tele Dürum. Tiene una maquina de bolas en la entrada. Así que podrías buscar un asset o algo que pegue con la
estética». Primera versión enseñada el mismo día (hojas en `guion/fotos/tele_durum/`).

Y después, el mismo día: «Podríamos abrir el negocio de 18:00 a 04:00 (puertas abiertas y luces encendidas) además de
añadir el kebab girando que ya tenemos hecho en kebab luis. Y verjas de las ventanas subidas cuando abierto y bajadas
cuando cerrado». Hecho y enseñado (hoja `03_horario.jpg`). Su veredicto, el mismo día: «Perfecto. Visto bueno».

El modelo es `godot/scripts/teledurum.gd` (sobre `obra.gd`). Herramientas: `tools/teledurum/`.

## Dónde
Calle de Santa Ana, lado sur, mirando al norte; Catastro `4690021VJ5649S`. En el juego es la casa `stana_44` del mapa
(frente de 10,36 m), la misma que usa la misión del sabotaje (`sabotaje.gd`). Hasta ahora la describía una línea de
`casas_calles.gd` (de Texturas, con el nombre «Tele Durum»); ahora va marcada `["obra"]` y la dibuja `teledurum.gd`
sobre el mismo marco. Sin rehorneado.

## Marco
El de la casa en el mapa: origen en el extremo izquierdo del frente visto desde la calle (el este), `x` a lo largo del
frente, `z` sale a la calle, `y` = 0 su suelo.

## Fuentes
- **Street View**: noviembre de 2024 (lo que manda), octubre de 2019 y marzo de 2013 desde las mismas cámaras; 13
  vistas en `tools/teledurum/capturas.py`. Todas las cámaras: `python tools/molino/panos.py cerca 3a7t9FkO19DA-Qbf5sZTpg 361.5 130 24`.
  La calle es estrecha: la cámara de enfrente está a 3,7 m de la fachada.
- La descripción de Texturas en `casas_calles.gd` (en el historial de git) sirvió de base.

## Lo que hay
- **Planta baja** (hasta 4,1 m): ladrillo marrón sobre un zócalo de azulejo claro. De izquierda a derecha: la puerta de
  madera de la casa con su montante de barrotes (x 0,15–1,1); una ventana (1,35–3,1); la entrada del local
  (3,55–6,15) con puertas de cristal de carpintería dorada retranqueadas y la carta en la jamba; y una ventana ancha
  (6,7–10,1). Los tres huecos del local tienen persiana gris (ver «El horario»).
- **Rótulos**: sobre la entrada, el cartel rojo con el nombre, una pizza a un lado y el asador al otro; a su derecha
  uno pequeño crema. Un aparato de aire, las cajas de contadores, un cable.
- **Planta alta**: vuela 0,45 m sobre la acera; revoco crema con chorretones, tres ventanas recercadas en ladrillo con
  persianas marrones, otro aparato de aire, cornisa de ladrillo y tejado de teja.
- **En la acera**: la máquina de bolas, roja, sobre su pie, con el globo lleno de bolas de colores, a la izquierda de
  la entrada; y la papelera de la calle.

## En el juego
- El nombre es «TELE DÜRUM» (de Luis), con «PIZZERÍA» encima; el cartel pequeño dice «Tele Dürum» y lleva un garabato
  donde iría el teléfono. Los dibujos (pizza, asador) son nuestros. Sistemas cambió el nombre en la misión, en los
  textos y en `guion/` el mismo día.
- **La máquina de bolas** se hizo con piezas del propio juego. Se buscó un modelo libre en Poly Pizza, OpenGameArt y
  Sketchfab (CC0 descargable) y no había ninguno; en Sketchfab los hay con licencia de atribución, pero la descarga
  pide que Luis inicie sesión. Si aparece uno que le guste, se cambia.
  - Desde el 16-11 es un nodo aparte, dibujado por `gacha.gd` (`GachaS.machine()`), para que pueda vibrar.
  - Funciona: echas 1 € y te toca una figura de un vecino (el «gacha» que pidió el usuario).
  - `_gumball` la coloca, le pone su sólido y guarda el nodo en `gumball_node`.
- No se entra (el frente sigue siendo sólido, también con las puertas abiertas). Desde la calle se ve el local
  entero: mostrador rojo, carta iluminada, asador, nevera de bebidas, mesas junto a las ventanas. Sin personajes.
- Prueba: `python tools/run_tests.py teledurum` (18 fotos a cuatro horas del día y 4 comprobaciones). Como es la casa
  de la misión, además `sabotaje`.

## El horario
Abre de 18:00 a 04:00 (`OPENS`, `SHUTS`, `open_at(hora)`). `_process` lee `game.clock` y llama a `set_open`.
- **Cerrado**: las tres persianas bajadas (ventanas y entrada), luces apagadas. Es el nodo `_shut`.
- **Abierto**: las persianas recogidas en sus cajones, las dos hojas de cristal abiertas hacia dentro, fluorescentes
  en el techo, una lámpara sobre la puerta, las brasas tras el asador y cuatro luces. Es el nodo `_open` más `_lights`.
- **El asador** (`_spit`) es el de Kebab Luis (`kebab.gd`), pieza por pieza y con los mismos colores: varilla, once
  tajadas, parches tostados, la cebolla y el plato; gira a la misma velocidad (`turn`), solo mientras está abierto.
- Lo que cambia con el horario se construye aparte del resto (`_states`, `_commit_to`): dos nodos que se enseñan o se
  esconden. Las ventanas y el local se construyen siempre; cerrado, las persianas los tapan.
- La comprobación del horario **no mueve la hora del juego** (lo pidió Sistemas: esperar fotogramas a las 23:00
  dentro de la completa despierta al Recress, a los vecinos de noche…): prueba la regla `open_at` y pone cada estado a
  mano con `set_open`. Las fotos del modo sí mueven la hora, porque ese modo va solo.

## Lo que es aproximado
- **Las posiciones de los huecos**: ajustadas comparando el juego con Street View desde el mismo sitio; ±0,3 m.
- **Las alturas**: planta baja de 4,1 m y alero a 7,3 m, deducidas de la misma comparación (el mapa daba 6,4 m).
- **La acera** del juego ahí mide medio metro: la máquina y la papelera van pegadas a la pared.
- **El interior** es inventado, y el horario lo puso Luis (no es el del sitio real). **La trasera y los costados** son el contorno del mapa, lisos; el tejado, a dos aguas.
