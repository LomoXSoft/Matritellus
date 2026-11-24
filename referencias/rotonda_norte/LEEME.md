# La rotonda de la entrada norte

Luis, 24/11/2026, con dos capturas de Street View (noviembre de 2024) y dos enlaces de Maps: «Un poco más adelante hay una rotonda bastante bonita. Me gustaría que fuese lo siguiente que hacemos».

Es la rotonda donde la carretera vieja de Madrid a Cádiz entra en el pueblo y se cruza con la avenida de la Constitución, unos 70 m al sur de los carteles de la entrada ([LEEME](../entrada/LEEME.md)).

**Aprobada.** Luis, 24/11: «Visto bueno. Dentro de la boca de la tinaja».

## Qué tiene

- **El suelo**, de fuera a dentro:
  - el bordillo pintado a franjas rojas y blancas;
  - una corona de ladrillo rojo puesto a lo largo del anillo, que sube un poco hacia el centro;
  - un bordillo blanco;
  - el césped.
- **El cartel**:
  - una chapa oxidada de 4,60 × 0,86 m, con los bordes rotos como cortados con soplete, sobre tres patas;
  - dice MADRIDEJOS pintado a mano en blanco, como el real; la I es de un solo trazo;
  - su punta este está enrollada hasta el césped;
  - mira a quien llega de Madrid; por detrás es óxido sin letras.
- **La portada**:
  - dos pilares de ladrillo claro, el dintel con una hilada saliente encima, un tejadillo de teja árabe vieja, y una reja sobre un poyete con su remate de ladrillo;
  - es del mismo ladrillo por las dos caras. Al principio puse la cara sur encalada y Luis lo corrigió: «Por detrás no es blanca. Es del mismo material que delante». Al sol parece blanca; en la foto de octubre de 2019 se ve que es ladrillo.
- **La tinaja**:
  - tumbada sobre la panza, con la boca levantada y mirando al norte-noroeste; se ve oscura por dentro;
  - en la hierba, a su lado, un foco alargado, y otro pequeño a su pie (apagados).
- **Las señales azules de rotonda**: tres, ante el norte, el sur y la avenida de la Constitución. Ante la calle del este no hay ninguna, porque en Street View no se ve.

## Dónde y cuánto mide

- **Sin rehorneado.** Es la isleta del anillo que ya tiene el mapa (la carretera 98). `rotonda_norte.gd` la busca cerca de (276.9, −1555.75), como hace la rotonda de los Tricornios.
- **La isleta real** sale de círculos ajustados a la ortofoto del PNOA (`tools/ign/rotonda_norte.jpg`): centro en (275.87, −1555.66), 6,94 m de radio hasta fuera del bordillo y 4,56 m el césped.
- **La del juego** se ajusta al anillo del mapa, que está 1,1 m más al este y deja una isleta de 6,34 m: una isleta más grande invadiría el carril.
  - Lleva el centro y el tamaño del anillo.
  - El césped casi mantiene su tamaño real (4,40 m); lo que falta lo pierde la corona de ladrillo.
- **Lo que hay encima** tiene su tamaño real y su sitio real, medido desde el centro real de la isleta.
  - Los sitios salen del rumbo desde tres cámaras de Street View (norte, sur y este). La ortofoto confirma la portada y la tinaja.
  - Portada: (273.74, −1555.28). Mide 2,20 m de ancho, con pilares de 0,44 m; 2,80 m hasta el dintel y unos 3,5 m hasta la cumbrera.
  - Tinaja: (278.8, −1554.75). Mide 1,6 m de largo y 1,05 m de ancho.
  - Cartel: su punta este real está en (278.3, −1559.4). En el juego va 0,25 m más hacia dentro, porque el césped es más estrecho.
- **Hacia dónde miran.** El cartel y la portada miran a 350°, al norte-noroeste. Así, desde la cámara del este se ven de canto y desde la del sur, de frente, igual que en Street View.

Cámaras de Street View (en `selftest.gd`, modo `--rotonda_norte`):
- u `hSeTcdZuFLrITD1QwTZiXw` (280.93, −1572.73), al norte, noviembre de 2024 (el segundo enlace de Luis);
- s `oommR1cWWSAo6ZKgyLrqyw` (275.16, −1533.53), al sur, 2025;
- e `crXvnnZZo_uNWUu5edeLWg` (294.37, −1561.59), al este.

## Lo que queda fuera

- Lo de las esquinas, fuera de la isleta (el pino, los armarios grises, el banco, el poste rojo), se queda como lo tiene el mapa.
- Los focos de la tinaja no se encienden de noche.

## Scripts y prueba

- `godot/scripts/rotonda_norte.gd` (`world.rotonda_norte`, sobre `obra.gd`).
- `tools/rotonda_norte/dibujos.py` → `godot/assets/rotonda_norte/`:
  - `chapa.png`: la cara del cartel con las letras, en la letra Ink Free de Windows;
  - `oxido.png`: el óxido de detrás y de la punta.

  Después de cambiarlos hay que importar.
- `python tools/run_tests.py rotonda_norte`:
  - saca las vistas desde las cámaras de Street View, con su mismo rumbo y ángulo para compararlas, dos de noche, cinco de cerca y dos del azafrán;
  - pasa `_rotonda_norte_checks()`, que va también en la prueba completa, tras los carteles de la entrada. Comprueba:
    - que la isleta no invade el carril y que lo de encima queda dentro;
    - que el anillo del mapa está a menos de 1,5 m de la isleta real;
    - que hay tres señales;
    - a qué altura se pisa el césped, la corona y la calzada;
    - que el bordillo, la portada, el cartel y la tinaja paran al que choca;
    - lo del azafrán (abajo).
- Capturas del juego en `guion/fotos/rotonda_norte/`. Las fotos de Street View no se guardan en el repositorio.

## Azafrán

**El azafrán escondido** está dentro de la tinaja, justo detrás de la boca (`_saffron()`, `"id": "rotonda_norte"`). Lo eligió Luis, y al verlo dio el visto bueno.
- Todas las flores de azafrán las viste `pickups.gd`: la flor sube y gira, y lleva un halo de 1,45 m y un aro a sus pies.
  - Aquí va todo al 35 % (`SAFFRON_K`) para que quepa en el hueco de la tinaja.
  - El halo queda sobre el eje, a 0,18 m de la panza hacia la boca (`SAFFRON_AT`).
- **Cómo se ve.** Al asomarse a la boca, desde el noroeste, se ve la flor brillando en lo oscuro. Desde la carretera del norte apenas asoma un poco de brillo en la boca.
- **Cómo se coge.** Se coge de pie delante de la boca (el juego coge una flor a menos de 1,26 m), y cuenta una vez por partida.
- Lo comprueba `_rotonda_norte_checks()`: que la flor está apuntada, que su halo cabe en el hueco de la tinaja y que hay sitio para ponerse delante de la boca. El modo `--rotonda_norte` saca las vistas `azafran` (asomado a la boca) y `azafran_bordillo` (desde el bordillo).
- Captura: `guion/fotos/rotonda_norte/rotonda_norte_03_azafran.jpg`.
