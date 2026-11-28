# «Burger Pizzería Miguel Ángel» (Calle de Tembleque)

La pizzería y hamburguesería de la Calle de Tembleque (la Pizzería Michelangelo de verdad). El nombre es de Luis, del
27/11/2026: «Pizzería Michelangelo (que llamaremos Pizzeria Miguel Ángel)». Y para el letrero: «En el cartel que ponga
Burger Pizzería Miguel Ángel». En el juego se llama «Burger Pizzería Miguel Ángel» y el letrero dice BURGER /
PIZZERÍA / Miguel Ángel.

**Estado**: APROBADO por Luis el 27/11/2026 («Visto bueno. Sin azafrán»). No lleva azafrán. No hay commit.

## Dónde y quién

- Sobre la casa del mapa `tembleque_8` (Catastro 3993742). Texturas la entregó con `"tembleque_8": ["obra"]` en
  `casas_calles.gd`. `tembleque_6` y `tembleque_10`, las de los lados, siguen siendo suyas.
- Sin rehorneado: el mapa tenía la casa y nada más en la parcela.
- Código: `godot/scripts/miguelangel.gd` (sobre el kit `obra.gd`). Se construye solo si la casa está entregada
  (`READY`), o con `--miguelangel` en las pruebas.
- Dibujos: `tools/miguelangel/dibujos.py` → `godot/assets/miguelangel/` (`letrero.png`, `baldosa.png`,
  `cortina.png`). Después de cambiarlos: `Godot --headless --path godot --import`.

## Fuentes

- Catastro: la foto de la fachada.
- Street View de 2024: con la persiana bajada (abre por la noche).
- Una foto de junio de 2025 (Google Maps): abierta, con el porche y la cristalera.
- La foto del letrero que mandó Luis: caja azul casi negro con marco de aluminio, letras altas y estrechas de color
  carmesí y el nombre en cursiva azul claro debajo.
- Las capturas de Street View y de Google se quedan fuera del proyecto. En `guion/fotos/pizzeria_miguelangel/` solo
  hay capturas del juego.

## Medidas (marco del sitio)

- Origen A = (−413,75, −99,73): el extremo norte de la fachada, en la medianera con `tembleque_10`. `u` va a lo largo
  de la fachada hacia el sur (EU = (−0,3459, 0,9383)) y `v` sale hacia la calle. `y = 0` es el suelo de la pizzería:
  la base de la casa o la calle delante del portón más 8 cm, lo que sea más alto.
- Fachada de 7,83 m (`L`).
- El portón del garaje viejo, donde está la pizzería: de `u` 0,68 a 3,43, con 2,65 m de alto (`GAR`). Detrás, el
  porche de 1,2 m de fondo (`PORCH`) y la cristalera.
- La puerta de los pisos: en `u` 5,35, de 1,0 × 2,3 m.
- Los contadores: en `u` 3,95 y a 0,9 m, de 0,75 × 0,8. El zócalo de baldosa mide 0,8 m y la faja de ladrillo está a
  3,3 m (`G1`).
- Las ventanas de arriba: en `u` 1,33 y 4,56, a 4,2 m, de 1,2 × 1,05, con las persianas bajadas un 62 % y un 40 %.
- El friso está a 5,75 m y el alero a 6,2. El tejado de teja cae a la calle en los 4,4 m de delante (`BAY`) y detrás
  hay azotea a 6,0 m (`FLAT`). Lo de detrás es una suposición, porque la foto aérea no daba para más.
- El letrero: en `u` 3,75, de 3,62 a 4,32 m de alto y 1,0 m de largo, saliendo de la pared a 0,14 m, con 0,14 m de
  grueso.
- Los faroles: en `u` 0,34 y 3,72, a 2,78 m. El segundo cuenta como farol del pueblo (`W.lamp_spots`).

## Cómo es

- La planta baja es de ladrillo tostado sobre un zócalo de baldosa terracota con rombos crema.
- **Abierta**:
  - la persiana está subida;
  - el porche tiene los costados de ladrillo y el techo de madera;
  - la cristalera es de madera barnizada, con dos puertas en medio;
  - detrás se ve el comedor encendido: mesas con manteles de cuadros rojos y blancos, el mostrador y la boca del horno
    con su brillo.
- **Cerrada**: la persiana beige bajada.
- El letrero es una caja con las dos caras dibujadas. Tiene un poco de luz propia de día y más cuando está abierta.
- La puerta de los pisos va hundida en el ladrillo, con un arco plano y una cortina de rayas.
- La planta de arriba:
  - revoco crema;
  - las ventanas enmarcadas en ladrillo dentado, con persianas blancas;
  - el ladrillo dentado de las esquinas;
  - el friso y la cornisa de ladrillo;
  - los cables cruzando la fachada.
- La rampa de hormigón del garaje viejo baja hasta la acera en tres tiras. Las tiras y el suelo del porche están en
  `MapData.decks`.
- **El porche se ve, pero no se pisa.** El muro invisible que el mapa pone alrededor de cada manzana (`world.gd`,
  `MapData.outlines`) pasa por la línea de la fachada. Para poder entrar andando habría que rehornear el contorno de
  la manzana.

## Horario (Google Maps)

- Lunes de 18:00 a 23:30.
- De jueves a domingo de 19:00 a 23:30.
- Martes y miércoles cerrado.

La persiana, las luces y el letrero siguen el reloj (`_process` y `open_at`).

## Archivos compartidos (solo líneas añadidas)

- `world.gd`:
  - el `const MiguelAngelS`;
  - la `var miguelangel`;
  - la entrada «the Burger Pizzería Miguel Ángel», detrás de la de Lápiz;
  - `_build_miguelangel`.
- `selftest.gd`:
  - el modo `--miguelangel`: 10 vistas, abierta un lunes a las 18:30, cerrada un martes a las 12:00 y de noche un
    viernes a las 22:30;
  - `_miguelangel_checks`, metido en la pasada completa después de Lápiz.

## Pruebas

- `python tools/run_tests.py miguelangel --timeout 600`: OK (5).
- `zfight solo=miguelangel.gd`: 0,35 m² exactos, casi todo caras de espaldas metidas en la pared.
- `aceras-suelos`: reescrito con `escribe` (la rampa baja sobre la acera) y luego comprobado: OK (12).

## Lecciones

- **Emisión**: la cara del letrero salía blanca en vez de azul casi negro. Godot 4 suma el color de emisión al
  dibujo antes de multiplicar por la energía, `(emission + textura) × energía`. Con `emission = Color.WHITE` toda la
  cara se aclara. Se arregla con `emission = Color.BLACK`, y así solo brilla el dibujo. Otros sitios usan
  `Color.WHITE` con poca energía (0,1–0,14), y eso aclara un poco sus partes oscuras.
- **Muro de la manzana**: aquí el contorno de la manzana (`MapData.outlines`) va entre 5 y 8 cm por delante de la
  fachada, así que una prueba de rayos que entre en el porche choca con él. Antes de prometer un hueco que se pise,
  mira por dónde va el contorno. En Lápiz, por ejemplo, corta en diagonal y deja libre casi todo el patio de delante
  de la nave.

Fotos: `guion/fotos/pizzeria_miguelangel/miguelangel_vistas.jpg`.
