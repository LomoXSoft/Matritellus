# «Pollos Asados Javi»

Luis, 21/11/2026, con una foto del mostrador real: «Siguiente edificio asador de pollos juli (que llamaremos Javi). Abrirá en horario comercial y dentro estará Javi, del Asador de pollos. Te dará misiones de reparto como las de Henry pero de pollo en vez de jamón y lo martes y domingos en vez de los jueves. Se podrá desbloquear después de completar la misión de Josefa del jamón, al llegar el próximo día de reparto o al hablar con él (su cara empezará a salir en el mapa y te lo mencionará Josefa cuando hables con ella). Javi será bajito, hermoso, con gafas, calvo y vestido de negro básico. Se podrá acceder al interior, que estará diseñado (adjunto foto). Pasa a sistemas lo que le toque».

Es el asador real de la calle de los Arcos. **En el juego se llama «Pollos Asados Javi»** (Luis, al ver el primer rótulo: «En vez de Asador de Pollos mejor llamarlo Pollos Asados»): los rótulos son dibujos propios (`tools/asador/dibujos.py`), sin el nombre real ni sus teléfonos. Los scripts y las carpetas conservan el nombre `asador`.

## Reparto del trabajo

- **Edificios Especiales (Pretil)**: la fachada y el interior.
- **Sistemas**: el personaje Javi (bajito, gordo, con gafas, calvo, de negro), su cara en el mapa, sus diálogos, los repartos de pollo de martes y domingos, el desbloqueo tras la misión del jamón de Josefa y la mención de Josefa.

## Dónde está

- Google lo da en «C. Arcos, 6», pero en Catastro el número 6 es la casa blanca de tres plantas de al lado. El asador es la casa ocre contigua: Catastro 4390040VJ5649S, la casa `arcos_4d` de Texturas, con frente de (108.93, 110.18) a (108.96, 103.04).
- `casas_calles.gd` la cede con `"arcos_4d": ["obra"]`. La línea antigua de Texturas está en `arcos_4d_antes.txt`. Sin rehorneado.

## Scripts

- `godot/scripts/asador.gd` (`world.asador`, paso «the roast chicken shop»): la fachada sobre la casa del mapa. `door` (ante la puerta de la tienda), `open_at(day, hour)`, `set_open(on)`, `is_open`, `dentro`.
- `godot/scripts/asador_dentro.gd` (`world.asador.dentro`): el interior, un decorado aparte en (2100, −1400) al que se entra por la flecha verde de la puerta (`entradas.gd`).
  - Para Sistemas: `javi_spot` y `javi_h` (tras el mostrador, mirando a la puerta), `client_spot` y `client_h` (ante él), `counter_front`, `open`, `saffron_spot`.
  - No se modela a nadie: Javi es de Sistemas.
- Prueba: `python tools/run_tests.py asador` (18 capturas y 5 comprobaciones); `_asador_checks()` va también en la completa.

## Qué hay

**Fachada** (Street View de noviembre de 2024): casa de dos plantas, ocre mostaza sobre zócalo de piedra clara, 7,1 m de frente. De izquierda a derecha: la puerta de la vivienda tras su cortina, el buzón, la caja blanca del contador y la tienda (puerta y cristal blancos tras una reja plegable de malla, con toldo beis). Sobre la tienda, el rótulo; entre los dos balcones, la banderola vertical «POLLOS ASADOS», perpendicular a la pared. Arriba, dos balcones con las persianas bajadas y el brazo de una farola; en el tejado, una buhardilla blanca.

**Interior** (la foto de Luis, tomada desde detrás del mostrador): mostrador de acero con tela morada, mampara de cristal sobre postes de aluminio y diez bandejas (aros, croquetas, nuggets, patatas, alitas, pisto, empanadillas, pimientos, albóndigas y patatas asadas); la caja registradora en su extremo; suelo de barro rojo, felpudo, puerta blanca y cortinas naranjas. Detrás: el asador con cuatro espetones de pollos que giran mientras está abierto, su campana, la freidora, el frigorífico y la mesa de trabajo. Del lado del cliente: la nevera de bebidas, cajas de pan, la carta, el aviso de reparto de martes y domingos, un reloj y una gallina de loza.

Hay un azafrán escondido en el rincón de la ventana, tras las cajas de pan (`"id": "asador"`, `"hidden": true`).

## Horario

El que fijó Luis (21/11): **martes y domingos de 7:00 a 16:00; cerrado el resto de la semana.** Son los días de los pollos y de los repartos. Un cartel en el cristal lo dice (`HOURS` en `asador.gd`).

Cómo se llegó a él:
- Primero pidió «horario comercial» y abría todas las mañanas y las tardes de lunes a sábado.
- Después mandó el horario del asador real (martes 11:00–15:00, domingos 11:30–15:00).
- Por último: «Pon que esos días abre a las 7:00 mejor. Y cierra a las 16:00».

- Cerrado: la reja echada. Abierto: la reja plegada a los lados, la puerta hacia dentro y luz.

## Trampas

- **El primer sitio del decorado tenía dos olivos del mapa dentro.** Al elegir sitio para un decorado hay que mirar también los árboles (`trees` del mapa) y los cultivos, no solo las calles y los otros decorados.
- **La puerta del decorado tiene que estar en el centro de su pared**: la cámara de `entradas.gd` da por hecho que la sala es simétrica respecto a `in_door`.
- **Mirando hacia dentro (+z), +x queda a la izquierda.** La caja registradora está en −x: a la derecha del cliente que entra y a la izquierda en la foto de Luis, tomada desde detrás.
- **La comprobación «no se dibuja la casa genérica» no vale contando hijos**: las casas van en mallas unidas. La prueba mira que `HOUSES["arcos_4d"]` sea `["obra"]`.
- Después de añadir o cambiar los PNG: Godot con `--headless --path godot --import`.

## Lo que es aproximado

- El rótulo dice «Javi · Pollos Asados · Comidas preparadas»; no lleva teléfonos.
- La carta no lleva precios: los pondrá el sistema de comida si hace falta.
- El interior real es más estrecho y oscuro; el del juego es una sala de 4,4 × 6,4 m para que quepa la cámara.
- Nadie pasa detrás del mostrador salvo Javi.
