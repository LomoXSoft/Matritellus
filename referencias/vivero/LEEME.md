# «Vivero de Empresas» (Avenida de la Reina Sofía)

El vivero de empresas del pueblo: el antiguo centro de salud, envuelto hacia 2014 en una segunda piel de ladrillo
claro puesto en celosía. Luis, 27/11/2026, con una foto de su fachada: «Ponte ahora con el Vivero de empresas. Que se
pueda pasar y tenga horario». En el juego pone «Vivero de Empresas» y, en el portón, VIVE / RO con MADRIDEJOS de canto.

**Estado**: APROBADO por Luis el 28/11/2026 («Ponlo, y visto bueno»). Lleva un azafrán escondido en el patio,
detrás de la maceta del olivo del fondo. No hay commit.

## Dónde y quién

- Sobre la casa del mapa `rsof_10`, que Texturas entregó con `"rsof_10": ["obra"]` en `casas_calles.gd` (la línea
  vieja está en el commit 8c49e83). `rsof_12` y `abj_rs14` siguen siendo suyas. Sin rehorneado.
- Código: `godot/scripts/vivero.gd` (la fachada, sobre el kit `obra.gd`) y `godot/scripts/vivero_dentro.gd` (el
  interior, un decorado aparte). Se construye solo si la casa está entregada, o con `--vivero` en las pruebas.
- Dibujos: `tools/vivero/dibujos.py` → `godot/assets/vivero/` (`celosia.png`, `celosia_abierta.png`, `puerta.png`,
  `placas.png`, `minusvalidos.png`, `rotulo.png`, `carteles.png`, `tablon.png`, `pantalla.png`). Si se redibujan hay
  que importarlos (`--headless --path godot --import`).
- En `world.gd`, `entradas.gd` y `selftest.gd` solo se han añadido líneas.

## Fuentes

- La foto de Luis (de frente a la fachada) y una fotoesfera de febrero de 2020 de Google Maps, para la fachada.
- Las fotos publicadas de la rehabilitación y las del propio vivero, para el interior. La planta es nuestra, sobre
  el contorno de la casa.
- Horario de Google Maps: de lunes a viernes de 9:00 a 14:00; cerrado el fin de semana.
- Las capturas de Maps se quedan fuera del proyecto; en `guion/fotos/vivero/` solo hay capturas del juego.

## La fachada (marco del sitio)

- Origen en el extremo oeste de la fachada (A = (−245.47, 221.13), 0,49 m antes del `o` de la casa), `x` a lo largo
  de la fachada hacia el este (EU = (0.9354, 0.3537)), `z` hacia la calle. Largo 11,85 m.
- **La avenida cae 1,3 m a lo largo de la fachada** (suelo a −7,40 en el extremo este y a −8,72 en el oeste; la casa
  apoya a −7,53). El nivel del sitio es el del extremo este; **el portón y el porche tienen su propia cota,
  `gate_y`** (el suelo más alto bajo el portón + 4 cm), para que el umbral quede en la acera. La celosía baja hasta
  el suelo por delante y el frente viejo («detras») tapa lo que se vería por debajo.
- Celosía: toda la fachada, de 12 cm de grueso, 45 cm por delante del frente viejo (blanco). Remate en tres tramos:
  7,23 m al oeste, escalón a 7,55 m y caída suave hasta 6,93 m al este (`TOP`).
  - Medida en la foto de Luis (76,8 px por metro): un hueco cada 40 cm en cada hilada de huecos, hiladas cada 15 cm,
    cada una desplazada medio paso. Cada dibujo cubre 0,4 × 0,3 m (`TILE`).
  - **Los huecos «cerrados» no son huecos**: son ladrillos metidos hacia dentro bajo uno que vuela. Van pintados en
    `celosia.png` (opaca). Solo las zonas abiertas (`OPENS`: ante el porche, ante las dos ventanas viejas y la
    banda de azulejos azules sobre la marquesina) usan `celosia_abierta.png`, con los huecos transparentes.
  - Color: ladrillo melocotón claro (`BRICK` en `dibujos.py`; `BRICK_EDGE` en `vivero.gd` para los cantos).
    Medido el 28/11 en `vivero_frente.png`: (212, 196, 177) en el juego contra (238, 213, 196) en la foto. El
    tono coincide; el juego queda un 10 % más oscuro por su luz.
- Portón azul al oeste (2,0 × 2,05 m): chapa perforada con las letras. En su horario está abierto, girado hacia
  dentro contra la pared del porche; fuera de él, cerrado. Detrás, el porche (2,95 m de alto) y las puertas de
  cristal del vestíbulo, justo detrás del portón. Junto a él, dos placas blancas (nombre y horario).
- Marquesina fina de canto azul a media altura (de x 3,26 a 9,15), con azulejos azules en los huecos de encima.
- Ventana de marco azul marino sobre la marquesina (`UPPER`) y, debajo, la banda de ventanas de la planta baja
  (`BAND`): cristales blancos esmerilados entre paneles azules, el último oscuro.
- En la acera: la señal de la plaza de minusválidos y un árbol joven junto al extremo este.
- De noche y cerrado se apagan el vestíbulo y los cristales (`set_open`, `_states`).

## El interior (`vivero_dentro.gd`)

- Decorado aparte en (−550, 1550), a 225 m de cualquier calle. Se entra por la **flecha verde** ante el portón, solo
  en su horario. El muro de manzana del mapa pasa por la fachada: el porche se ve pero no se pisa.
- Marco: `z` hacia dentro, la puerta en z = 0, `x` positivo a tu izquierda. 12 × 24 m. Suelo en `MapData.decks`.
- Habitaciones (`ROOMS`, para la cámara): recepción (mostrador, el nombre en la pared, dos butacas rojas, el tablón
  de corcho), pasillo entre los dos despachos de cristal y el patio, **patio al aire libre** (la celosía en sus
  paredes, sillas de mimbre negro, olivos en macetas), coworking bajo tres lucernarios (dos islas de mesas, 14
  puestos, sillas de colores, la escalera volada de roble contra la pared azul, con una cuerda: el piso de arriba
  no existe), sala de reuniones (pantalla «PLAN DE EMPRESA») y office. Los aseos son una puerta cerrada.
- **Azafrán escondido** (Luis, 28/11: «Ponlo»): en el patio, en el suelo entre la maceta del olivo del fondo y la
  pared (`_saffron`, `saffron_spot`, `"id": "vivero"`, `"hidden": true` en `game.flowers`). Está al aire libre: va
  en `_open_air` para que `_indoors` no lo meta en la capa de interiores y le dé el sol.
- No hay nadie dentro: las figuras las decide Luis.
- 10 luces sin sombras, solo sobre la capa de interiores. Detrás de toda la pared de la fachada hay un sólido
  entero (la banda de ventanas no es una salida).

## Pruebas

- `python tools/run_tests.py vivero --timeout 600`: 10 vistas de fuera (abierto, cerrado y de noche), 12 de dentro y
  7 comprobaciones (entrega, construido, la fachada te para y el umbral queda a 0–0,3 m de la acera, horario y
  estados, decorado lejos y cerrado, paseo por todas las habitaciones, el azafrán está, le da el sol y se llega a
  él). OK 7/7 el 28/11.
  - Una pasada (la de las 04:05, la primera con el azafrán) dio 6 de 7: fallaron tres paseos (pasillo, despacho 1
    y reuniones). **No se ha repetido en tres pasadas más sin tocar nada (7 de 7 las tres) y no sé la causa.**
    Pista sin comprobar: `casas_calles.gd` había cambiado dos minutos antes (Texturas), así que esa pasada rehízo
    la caché de las casas. Si vuelve a salir, hay que imprimir `short` y la habitación de cada paseo.
- `zfight solo=vivero.gd`: 0,07 m² exactos (el escalón bajo el portón, por debajo de la acera).
  `zfight solo=vivero_dentro.gd`: 0,28 m² (caras de abajo de tableros y sillas).
  - Antes eran 0,87 y 1,1 m², y eran de verdad: el alféizar de ladrillo de la banda coincidía con el alféizar azul,
    y los marcos de la puerta del vestíbulo y de la del patio coincidían con el canto de sus paredes. Ahora la banda
    no lleva alféizar de ladrillo y los marcos van dentro del hueco.
- `aceras-suelos`: OK (12) el 28/11 sin tener que reescribir el archivo.
