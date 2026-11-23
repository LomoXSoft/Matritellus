# Los carteles de la entrada norte

Luis, 23/11/2026, con tres capturas de Street View (N-IVa, noviembre de 2024) y dos enlaces de Maps: «Hay dos carteles en la entrada de Madridejos que me gustaría añadir».

**Aprobados por Luis el 24/11/2026** («Visto bueno»), con el azafrán, MADRIDEJOS en los carteles, el escudo con su cinta y el cartel cuadrado.

**Azafrán escondido** (Luis, 24/11: «Si, cambialos por Madridejos. Esconde azafrán en la opción 1»): al pie del muro, por detrás, entre hierba seca. Está a 3,9 m del extremo izquierdo del muro (visto desde la carretera) y a 0,45 m de su cara de atrás (`SAFFRON` en el marco del muro). Lo rodean matas secas iguales que las del campo (las de `matojos.gd`), también a lo largo de toda la espalda del muro, porque las del campo no crecen a menos de un metro de un sitio hecho a mano. Quien llega del norte no lo ve, porque el muro lo tapa. Se coge desde el campo de atrás. En `game.flowers` es `"id": "entrada"`.

Son los dos carteles de la entrada norte del pueblo, junto a la carretera vieja de Madrid a Cádiz (la N-IVa), en la tierra del lado oeste, antes de la rotonda de la avenida de la Constitución:

- **El muro de bienvenida**: un muro encalado de unos 5 m de largo y 3 m de alto. Tiene el borde de arriba ondulado como una ruina, rematado con piedras pardas, y piedras oscuras metidas en la cal. Lleva dos azulejos, «Un lugar de la Mancha» y el nombre del pueblo, y la silueta de don Quijote a caballo en chapa oxidada, con la lanza asomando por encima del muro.
- **El cartel del hermanamiento**: una placa sobre dos postes, más cerca de la carretera. Su dibujo está cuadrado (Luis, 24/11: «La placa de Madridejos y Nerac está un poco descentrada, cuadrala un poco»): los escudos en una columna, las palabras en otra, el conjunto centrado y el mismo aire arriba, en medio y abajo. Es blanca amarillenta, con el borde rojo. Lleva el escudo del pueblo con el nombre, «HERMANADO CON LA VILLA DE» y el escudo y el nombre de la otra villa, NÉRAC (FRANCE).

**Las palabras son las reales**: el pueblo del juego se llama Madridejos (Luis: «Matritellus es el título y su nombre original en latín»). Los escudos son nuestros:
- el del pueblo es el del juego (`assets/logo.png`), con su cinta. La cinta dice MATRITELLUS, y así se queda (Luis, 24/11: «No, deja Matritellus en el escudo, ahí puede estar, ya que es su nombre antiguo»);
- el de Nérac está dibujado aquí: azul con borde de oro, un castillo de oro de tres torres sobre un río blanco.

El nombre de Nérac se deja tal cual, porque es un pueblo y no una marca. Si Luis prefiere otro, se cambia en `tools/entrada/dibujos.py`.

## Dónde están

Seis panorámicas de Street View a lo largo de la carretera (noviembre de 2024) dan el rumbo a cada cartel, y sus cruces coinciden con medio metro de diferencia. La ortofoto del PNOA (`tools/ign/entrada_norte.jpg`) da la línea del muro.

| | En el mapa (x, z) | Su cara mira a |
|---|---|---|
| Muro (el centro de su cara) | (258.5, −1625.1) | 12°, norte-noreste |
| Cartel (entre sus postes) | (263.0, −1650.9) | 30° |

- Los dos miran a quien llega por el norte.
- El muro está a unos 10 m del borde de la carretera; el cartel, a unos 5 m.
- Sin rehorneado: los dos están sobre tierra. Cada uno es un sitio aparte, así que las matas secas no crecen en ellos, pero sí en el campo de en medio.

Cámaras de Street View usadas (en `selftest.gd`, modo `--entrada`):
- a `oOlDAJmcEdayjZ1cwVfUUw` (276.80, −1633.20);
- b `cTw9zzGaau7e70OfFji3sA` (277.40, −1663.90);
- c `KvaMZNG2Qk6c1sych7ntVQ` (277.07, −1653.68);
- d `1TzK-7EQ68gz88lzj0KDSA` (276.83, −1643.48).

## Medidas

Salen de una foto de Street View que ve el muro casi de frente, desde 43 m (cámara b, rumbo 205,9°, fov 12):
- el muro mide 5,10 m de largo y 3,18 m hasta lo más alto de su joroba izquierda, con 0,5 m de grueso;
- el zócalo mide 0,72 m;
- el azulejo «Un lugar de la Mancha» mide 1,96 × 0,26 m; el del nombre, 1,40 × 0,26 m;
- don Quijote va de 0,73 m (los cascos, sobre el zócalo) a 3,03 m (el sombrero); la punta de la lanza queda a 3,55 m, medio metro por encima del muro.

El cartel mide 1,20 × 0,87 m, con el borde de abajo a 2,25 m del suelo y los postes a 0,33 m del centro. Desde dos cámaras, su centro queda a unos 2,7 m sobre la carretera.

## Scripts

- `godot/scripts/entrada.gd` (`world.entrada`, paso «the signs at the north entrance»): el muro. Su `cartel` es el mismo script en otro nodo.
- `godot/data/quijote.json`: la silueta de don Quijote, calcada con `tools/entrada/silueta.py` de la foto de frente.
  - La foto es de Google y no se guarda en el repositorio. Se baja con `tools/molino/panos.py foto cTw9zzGaau7e70OfFji3sA SALIDA.jpg 205.9 -1 12`.
  - La lanza no se calca, porque por encima del muro se confunde con los árboles. `entrada.gd` la pone como una barra con su punta de hierro.
- `tools/entrada/dibujos.py` genera en `godot/assets/entrada/` los dos azulejos y la cara del cartel. Después hay que importar: `Godot --headless --path godot --import`.
- Prueba: `python tools/run_tests.py entrada --timeout 600`.
  - Saca las vistas desde las cámaras de Street View (con su mismo rumbo y ángulo, para compararlas), dos de noche y ocho de cerca: de frente, los azulejos, el Quijote, de lado, por detrás, el cartel por delante y por detrás, y desde arriba.
  - También saca una vista del azafrán («azafran»).
  - Pasa `_entrada_checks()`, que va también en la prueba completa. Comprueba también el azafrán: está en `game.flowers` como escondido, el muro lo tapa desde la carretera y se llega desde el campo.
