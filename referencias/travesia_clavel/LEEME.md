# Travesía del Clavel: peatonal y elevada

Encargo del usuario (21/11/2026), para Edificios Especiales (Pretil):

> «De acuerdo, que sea peatonal y con las cosas que has dicho. Que se ponga Petril con eso cuando termine con el Rice»

Antes había preguntado, al ver las hojas: «La travesía del clavel la has hecho elevada sobre el resto de las calles y que para acceder haya que usar una escalera de acera? Tiene dos accesos, es de la escalera de la calle clavel y el de la rampa de la calle san Rafael».

## Cómo es (fotos de esta carpeta)

- Un callejón peatonal entre la Calle del Clavel (norte) y la Calle de San Rafael (sur), más alto que las dos calles.
- **Por el Clavel:** una escalera de baldosas a cuadros rojos y crema, con barandilla de acero (`usuario_escalera_clavel.jpg`, `sv2024_desde_clavel.jpg`).
- **Por San Rafael:** rampas en zigzag, con barandillas de acero de tubo y muretes blancos (`usuario_rampa_san_rafael.jpg`, `sv2024_desde_san_rafael.jpg`).
- A lo largo del callejón, el paseo de baldosas a cuadros y, a los lados, muretes ocres con rejillas de ventilación: las plantas medio enterradas de las casas.
- En el lado este, la hilera ocre de 2004 sube a cada puerta por un rellano con barandilla de forja.

## Lo que hay ahora en el juego

- En el mapa la Travesía es una calle `residential` de asfalto, 7,5 m de ancho y con coches. Va de (136.7, -158.0) a (149.3, -227.1), y el suelo sube hacia el norte: las casas van de 8,2 a 9,4 m.
- **La hilera del lado este** (`tcl_4` a `tcl_20` en `godot/scripts/casas_calles.gd` y `tools/casas/calles.json`, de Texturas):
  - llevan pintadas en la fachada una planta medio enterrada de piedra de 1,4 m y una escalera (`esc`) hasta la puerta;
  - si el paseo elevado choca con eso, avisa a Texturas y cambio esas líneas.
- **El lado oeste** está sin describir: el Catastro da una tira de una planta sin dirección (4494604) y las fotos enseñan ahí los costados de casas más altas.

## Cómo quedó hecho (Edificios Especiales, 21/11/2026)

`godot/scripts/travesia.gd` (`world.travesia`, paso «the Travesía del Clavel»), sobre `obra.gd`. Aprobado por el usuario (21/11): «Visto bueno sobre todo».

### Medidas

- Marco: origen en la esquina de la casa de San Rafael (`rafael_tc2`), (140.56, −160.80); `s` hacia el norte por la fachada de la hilera este, `t` hacia el oeste. `python tools/travesia/alturas.py` da el terreno y las puertas en ese marco.
- **El Catastro de la hilera oeste está mal**: su tira (parte 2 de 4494604) queda de 1,4 a 5 m corta del callejón. En la ortofoto (`tools/ign/travesia.jpg`) hay 7 m entre fachadas en todo el largo. La hilera oeste se hace a mano en su sitio, y también la casa blanca de la esquina del Clavel, que el Catastro no tiene ahí. La parte 1 de la parcela, en el Clavel, sigue siendo genérica.
- El terreno del juego sube 1,8 m de San Rafael al Clavel. El paseo es un solo plano inclinado (2,39 %), 0,30 m bajo el umbral de la primera puerta (`tcl_4`; umbral = base + 1,4). Queda 1,5 m sobre San Rafael, 0,95 m sobre el terreno en el centro y 1,1 m sobre el Clavel.

### Qué hay

- **El paseo**: baldosa a cuadros crema y rojo (`godot/assets/travesia/baldosa.png`, dibujo propio), bancos, macetas y farolas en la pared oeste.
- **Por San Rafael**: tres rampas en zigzag (12,8 %), con rellano llano en cada extremo, muretes blancos con rejillas y barandilla de tubo de acero. Se entra por el extremo este y se sale al paseo por el oeste.
- **Por el Clavel**: la escalera a cuadros junto a la casa blanca (7 contrahuellas), el carril de hormigón rayado del garaje y la escalera estrecha de la terraza de la hilera este.
- **Ante cada puerta de la hilera este**: un rellano de 1,25 m con dos a cuatro peldaños y barandilla de forja. Texturas quitó de sus nueve líneas la escalera `esc` y el ventanuco de la planta de piedra; de su piedra asoman unos 40 cm.
- **La hilera oeste**: siete casas ocres con zócalo rojizo, reja abajo y persianas marrones arriba, escalonadas con el paseo. En su testero de San Rafael, el zócalo de lajas y la placa de la calle.
- **La casa blanca**: zócalo de lajas, portón de garaje con su señal y dos ventanas al Clavel.
- Un azafrán escondido junto al primer banco (`"id": "travesia"`, `"hidden": true`).

### Lo que es aproximado

- **El carril del garaje no baja.** En la realidad desciende bajo el paseo; el relieve del juego tiene una malla de 12 m y no admite un foso de 3 m de ancho. Es un fondo de saco llano que acaba en una boca oscura de un metro bajo el paseo.
- La hilera oeste es una reconstrucción a partir de dos fotos tomadas desde los extremos: sus huecos son regulares, no copiados casa a casa.
- El ancho de la casa blanca (5,4 m en el Clavel) sale de la ortofoto.
- Las alturas son las del juego (relieve ×2,5), no las reales: la escalera real tiene nueve peldaños.

### Horneado

En `tools/bake_godot.py` (lo aplica `tools/travesia/enganche.py`): la calle pasa a `k` 2, `pedestrian`, `paved` 5 (marca nueva: la suela `travesia.gd`; `empedrado.gd` la salta); la parte 2 de 4494604 no se levanta; clave `travesia`. Ninguna casa se mueve. Diferencias: 1 tejado plano y 10 muros fuera, 4 muros nuevos y unos 226 contornos lejanos por el redondeo de siempre.

### Para Sistemas

- `G.world.travesia`: `ramp_foot`, `ramp_top`, `stairs_foot`, `stairs_top`, `mid_spot` (Vector2 del mapa), `saffron_spot`, `top_s`.
- El paseo es un suelo elevado (`MapData.decks`). Lo que se ponga ante las puertas de `tcl_4` a `tcl_20` tiene que usar `MapData.foot(p)`: con `MapData.height` queda debajo.
- No pasan coches: la calle ya no está en el grafo de tráfico.

### Herramientas y hojas

- `tools/travesia/`: `alturas.py`, `manzana.py` (Catastro sobre la ortofoto), `dibujos.py` (baldosa, hormigón rayado y lajas), `enganche.py`, `hojas.py`.
- Prueba: `python tools/run_tests.py travesia` (18 capturas y 4 comprobaciones); `_travesia_checks()` va también en la completa.
- Hojas del juego: `guion/fotos/travesia_clavel/01–03`. `python tools/travesia/hojas.py CARPETA` monta la comparación con las fotos reales, fuera del repositorio.

### Trampas

- Los peldaños como rampa para los pies: el plano pasa por los cantos de los peldaños, nunca por debajo de una huella.
- Cada tramo de suelo (`_plane`) es convexo y lleva su `grad`; los rellanos y los peldaños van en la lista ANTES que el paseo, porque `MapData.foot` se queda con el primero que contiene el punto.
- Sin muros sólidos entre tramos, quien pisa el polígono de al lado salta a su altura.
- Una baldosa con dibujo necesita coordenadas propias: el triplanar del mundo sale girado 11° respecto al callejón.
