# «Cruz Verde» y el parque de la plaza de Jesús Requejo

Luis, 23/11/2026, con una captura de Google Maps con la manzana marcada en rojo: «Ahora la cruz roja y el parque que tiene detrás, los dos lados de la misma manzana. Tiene varias 360 así que debería ser fácil».

El nombre es de Luis, el mismo día: «Que llamaremos la cruz verde. La plaza puede mantener el nombre». En el juego es la **«Cruz Verde»**, con la cruz verde. La plaza sigue siendo la de Jesús Requejo.

Es la manzana entera entre la avenida de Juan Carlos I (al norte, con la explanada de tierra delante), la calle de Don Jesús Requejo (al este), la calle de las Viñas (al sur, con el parque) y la calle sin nombre del oeste. Delante hay un bloque de pisos de tres plantas con la oficina en la planta baja. Detrás hay dos alas bajas blancas con un patio estrecho entre ellas. La pared sur, el mural, da al parque.

En el juego no sale el nombre ni el emblema de ninguna organización real. Lo nuestro es la «Cruz Verde», con cruz verde y «MADRIDEJOS» debajo (hasta el 24/11/2026 ponía MATRITELLUS; Luis: «el pueblo del juego se llama Madridejos. Matritellus es el título»). No hay número, ni teléfono, ni la placa del partido que hay junto a la puerta (está quitada a propósito).

## Reparto del trabajo

- **Edificios Especiales (Pretil)**: todo lo de la manzana (`requejo.gd`).
- **Texturas** cedió la casa `vin_jr3` (Catastro 3890502VJ5639S) en `casas_calles.gd` (`["obra"]`). Al horneado había salido como una caja blanca baja de 2,8 m.
  - Quitará en su próximo horneado los dos árboles del mapa que hay delante de la fachada, en (−430,7, 173,8) y (−417,7, 173,9) (`NO_TREES` en `tools/bake_godot.py`). En Street View 2024 ya no están.
  - También cedió la caseta del transformador de la esquina (`requejo_1`, `["obra"]`), el mismo día. Luis la había rodeado en la hoja de Street View: «este edificio no se parece nada». El horneado la había dejado como una caja blanca baja. Ahora va a mano en `requejo.gd` con el resto de la manzana.
- **Sistemas**: nada por ahora. Avisado de las líneas que he metido en `world.gd` y `selftest.gd`.

## Dónde está

- El bloque, en el orden del anillo: A (−439,19, 178,14), B (−418,13, 179,63), C (−418,53, 188,70), F (−439,81, 187,49).
  - A–B es la fachada a la avenida (21,1 m).
  - B–C es el costado de la calle Requejo y F–A el de la calle del oeste.
  - F–C es la trasera, que da a las alas.
- Las alas llegan hasta G (−440,68, 200,63) y S (−419,11, 201,68). G–S es la pared del mural (21,6 m).
  - El ala oeste (la oficina) va de F a x = −431,2.
  - El ala este va de x = −428,6 a C.
  - Entre las dos queda el patio, con suelo de cemento.
- `level` es el suelo de delante de la puerta. **El terreno del juego baja mucho más que el real** (el relieve va ×2,5):
  - de la avenida a la puerta cae 2 m;
  - a lo largo del costado oeste cae 0,9 m;
  - hasta el parque cae 1,5 m.

  Por eso:
  - El zócalo de piedra no es del todo horizontal. Baja con el suelo un 60 % de lo que cae (`_pl`). En la esquina de atrás de la calle del oeste mide 1,2 m, como en la foto. Horizontal habría medido 1,8 m.
  - Los muros de las alas siguen la cuesta. Su coronación es un plano que pasa 3,2 m por encima del suelo en F, en C y en G (`_wing_plane`, `_wt`). Con coronación horizontal saldrían de 2,9 m junto a la puerta de la oficina y de 4 m en el parque.
- La caseta del transformador está en la esquina de la explanada con la avenida, en el orden del anillo: NO (−420,12, 161,2), NE (−415,15, 160,73), SE (−414,69, 165,57) y SO (−419,67, 166,04). Es casi cuadrada (5 × 4,9 m).
  - Su pared llega a 6,7 m sobre el pie de la fachada de la avenida, y la cumbrera sube 1,35 m más. En las fotos de Street View la pared mide de 6,4 a 7,2 m; con 6,45 quedaba achaparrada.
  - Las medidas salen de las fotos, ajustando cada una con las dos esquinas de la pared que se ve. Las cámaras de la avenida tienen el rumbo torcido hasta 10°.
- La calle del oeste no tiene nombre en el mapa. Además es más ancha que la real: la señal de prohibido de junto al árbol grande va 0,8 m más hacia la manzana que en la foto, para que quede en la acera.

## Scripts y dibujos

- `godot/scripts/requejo.gd` (`world.requejo`, paso «the Plaza de Jesús Requejo», sobre `esquina.gd`, sin rehorneado). Expone `door` (delante de la puerta, en la explanada), `office` (delante de la puerta de la oficina) y `park` (en el paseo delante del mural).
- `tools/requejo/dibujos.py` genera en `godot/assets/requejo/`:
  - el rótulo pintado de la oficina (tan ancho como las palabras: `requejo.gd` lee su anchura);
  - el cartel del balcón;
  - la placa de junto a la puerta (un emblema redondo azul nuestro);
  - el letrerito de la cruz;
  - el mural: un pueblo pintado, nuestro, con casas de colores, la torre, un molino en su cerro, un tractor y un pájaro (el real también es un pueblo de casas de colores);
  - el tablón del parque;
  - la placa de vado del garaje del ala este;
  - para la caseta del transformador: el triángulo amarillo de peligro de la puerta, la chapa vieja de encima (con las letras gastadas), la placa con el nombre de la plaza («PLAZA / D. JESÚS / REQUEJO»), el azulejo azul con la flecha amarilla del Camino y el desconchón del hastial oeste con su chorreón.

  Las dos pintadas de la caseta son dos logos de las peñas (`assets/penas/`): Costrola en el armario de la fachada y Croquetilla al pie del hastial oeste, donde están las de verdad.

  Después de cambiarlos: `Godot --headless --path godot --import`.
- Prueba: `python tools/run_tests.py requejo --timeout 600`.
  - Saca 30 vistas desde las mismas cámaras de Street View (ocho de ellas, `h_…`, de la caseta del transformador), dos desde arriba y una de noche (la farola del brazo).
  - Pasa `_requejo_checks()`, que va también en la prueba completa. Comprueba que está hecha a mano, las dos casas cedidas (la manzana y la caseta), que paran las siete fachadas (la de la avenida, los dos costados, la oficina, el ala este, el mural y la de la caseta), el tejado entero y que nada pisa el asfalto.

## Qué hay

- **El bloque de pisos.**
  - Revoco crema sobre un zócalo de mampostería parda. Pilastras de ladrillo en las esquinas, imposta de ladrillo en la primera planta y cornisa de ladrillo bajo el alero.
  - Tejado a cuatro aguas de teja vieja gris, con dos chimeneas de tubo y antenas.
  - Fachada a la avenida:
    - ocho ventanas por planta con dinteles y alféizares de ladrillo, persianas marrones a distintas alturas y rejas en las de abajo;
    - en el centro un cuerpo de ladrillo con la puerta de madera de dos hojas y su escalón;
    - el balcón con las dos puertas de cristal y visillos, y el cartel «Cruz Verde» colgado en la mitad oeste de la barandilla;
    - encima, la farola de brazo, tres aparatos de aire, la placa y el letrerito de la cruz.
  - Costados:
    - lisos, con un foco arriba;
    - en el del este, los contadores y un cable;
    - en el del oeste, dos aparatos de aire sobre la imposta, la bajante gris y el tubo blanco.
  - La trasera tiene ventanas en las dos plantas de arriba.
- **El ala oeste, la oficina**, a la calle del oeste:
  - la puerta tras una cancela de barrotes;
  - el letrerito de la cruz y «Cruz Verde / MADRIDEJOS» pintado arriba;
  - dos ventanas con reja y la persiana bajada;
  - la bajante y la puerta de garaje marrón con su rejilla, hasta el borde del tejado.
- **El ala este**, a la calle Requejo: zócalo de cemento gris, puerta de garaje de chapa gris acanalada con la placa de vado y una ventana con reja detrás del matorral grande.
- Los tejados de las alas quedan detrás del peto: planos al norte y de teja al sur (como en la foto aérea), con un borde de teja por encima de los muros.
- **Delante (norte)**:
  - la explanada de tierra donde estaban los árboles (2013);
  - las vallas rojas de plástico del ayuntamiento en tres tramos;
  - el árbol joven;
  - en el costado este, tierra, hierbajos y matorrales hasta la acera;
  - la señal de prohibido en la esquina del transformador, con la azul de girar a la derecha debajo.
- **La caseta del transformador**, en la esquina de la explanada con la avenida:
  - una torre blanca de cal, casi cuadrada, con tejado a dos aguas de teja vieja parda (la cumbrera de este a oeste) sobre una moldura blanca;
  - a la avenida:
    - la puerta de chapa gris de dos hojas, un palmo hacia dentro, con su marco de cemento, el escalón y los triángulos de peligro;
    - a su izquierda, el armario de chapa con la pintada;
    - encima, la chapa vieja y, a la derecha, la placa de la plaza;
    - arriba, la rejilla de lamas;
    - en la punta este, el soporte de los cables, con el mazo colgando y enroscado en la esquina;
    - en la punta oeste, la farola de brazo y un cable que baja por la esquina hasta una cajita;
  - el hastial este, con la flecha del Camino;
  - el costado sur, con el nicho de los respiraderos y tres ganchos de hierro bajo el alero;
  - el hastial oeste, con la barra de los aisladores, un desconchón con su chorreón y la otra pintada al pie.
  - No lleva el número que tiene encima de la puerta, ni la pegatina de la compañía de la luz.
- **Detrás (sur), el parque**:
  - el paseo de adoquín gris a lo largo del mural, con cuatro bancos de hierro y una papelera;
  - el césped con bordillo y cinco tarajes, uno con el pie encalado y un claro de tierra (con el azafrán escondido detrás del tronco);
  - el tablón al final;
  - el árbol grande en su alcorque de la acera oeste, con la señal de prohibido al lado.

## Fuentes

- Street View 2024 (y 2009, 2013, 2019 y 2021) desde 24 cámaras alrededor de la manzana. Las fotos son de otros y se quedan fuera del repositorio. En `guion/fotos/requejo/` solo hay capturas del juego.
- La foto aérea del IGN (PNOA, CC BY 4.0) en `tools/ign/cruzroja.jpg` y `.json`.
- El Catastro (3890502VJ5639S, tres partes) en `tools/casas/`.

## Pendiente

- Nada de la obra: Luis le dio el visto bueno el 23/11, con la caseta ya hecha a mano: «Me habré confundido. Cruz verde está bien. Visto bueno». Había escrito «Cruz Naranja» por error; el nombre sigue siendo «Cruz Verde».
- (Hecho) el azafrán escondido. Luis eligió el sitio el 23/11: «1. En el parque». Está al pie del taraje encalado, en la tierra, al otro lado del tronco desde el paseo, junto a una mata seca (`_saffron`, `id` "requejo"). Cuenta una vez por partida, como los demás escondidos. Captura: `guion/fotos/requejo/requejo_11_azafran.png`.
- Los dos árboles del mapa se van en el próximo horneado de Texturas.
- Sin commit: lo hace Sistemas.
