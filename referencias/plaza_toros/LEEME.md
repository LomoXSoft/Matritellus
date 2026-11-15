# Referencia: la Antigua Plaza de Toros

Pedido por Luis el 15-11-2026 (`usuario_01_zona.webp`: la manzana entre las calles de la Prensa, Bienvenida, San
Agustín y Vista Alegre): «Este es un caso especial. Entre 2009 y 2013 fue restaurada. Así que necesitaría dos modelos,
el antes de la restauración y el de después. Ya que restaurarlo será una actividad cívica del juego en el futuro (que
incluirá competición de recortes a toros, pero eso para el futuro, centrémonos en el modelo)».

El modelo es `godot/scripts/toros.gd` (sobre `obra.gd`), con **dos estados**: la ruina (como empieza el juego) y la
plaza restaurada. Herramientas: `tools/toros/` y las generales de `tools/molino/` y `tools/plaza/`.

## Marco
Origen en el centro del ruedo, mapa (476,3, 548,5). Ejes del mapa (x al este, z al sur): la plaza es redonda. Los
ángulos se cuentan desde el este hacia el sur (90° = sur, hacia Vista Alegre). Alturas sobre el suelo del solar.

## Fuentes
- **Catastro**: `4786002VJ5648N`, servicios públicos, 1950, un círculo de 2.359 m² (radio 27,4, centro (475,9, 549,1)).
- **Ortofotos del IGN**: 2006 y 2009 (antes), 2012 y 2015 (después) y la vigente (`tools/ign/toros_*.jpg`).
- **Street View**: mayo de 2009 desde Vista Alegre (antes); marzo de 2013 (recién acabada); 2019 y noviembre de 2024
  desde las tres calles. Lista en `tools/toros/capturas.py` (las fotos no se guardan: son de Google).

## Medidas
- Muro exterior: radio **27,2 m** por fuera; alto **5,3–5,4 m** (medido desde San Agustín: base a 8,4° bajo la
  cámara, coronación a 9,7° sobre ella, a 16,9 m).
- **Contrafuertes**: unos **70** en la vuelta entera (uno cada 2,44 m); cada uno un machón de 0,55 m de frente que
  sale 1,25 m en el pie y 0,35 m arriba (cara inclinada), tan alto como el muro.
  - Restaurados (blancos, lisos): del este-noreste al oeste-suroeste pasando por el sur (de -15° a 165°).
  - **Sin restaurar hoy todavía**: el arco del oeste (165° a 225°), detrás de la tapia de la calle de la Prensa:
    tapial pardo comido.
  - Por el norte (225° a 345°) da a los corrales de las casas de Bienvenida: no se ve.
- **Graderío**: corona de 20,6 a 26,6 m; **ruedo** de unos 19 m de radio, con barrera y callejón.
- **Puerta** de madera en el sureste (hacia 52°). Bloque techado en el suroeste (150°: toriles) y otro al este (-8°).
- **Solar** delante (sur y este): tierra, con valla de simple torsión a lo largo de Vista Alegre y San Agustín (en
  2009 y también en 2024); desde ~2015 con arbolitos en hileras.
- **Tapia de la calle de la Prensa** (oeste): vieja, encalada, de unos 3 m, con la coronación comida.

## Antes (hasta 2009)
Contrafuertes y muro de tapial y mampostería a la vista, color tierra, con restos de cal a parches, coronación comida
y desigual, matas arriba. Un cobertizo bajo y blanco, desconchado, pegado al anillo por el suroeste. Solar de hierbajos
con valla metálica. Torre eléctrica de celosía en la esquina.

## Después (2013 →)
Tambor blanco liso con sus contrafuertes iguales, puerta de madera en el sureste, graderío nuevo de hormigón.

## En el juego
- `world.toros.set_restored(true/false)` cambia entre la ruina y la restaurada: lo que se ve y lo que para. Empieza
  en ruina. Con `--toros-restaurada` en la línea de órdenes arranca restaurada (para verla o fotografiarla).
- En la ruina la puerta está tapiada con tablas y no se entra al ruedo; el solar tiene la valla, con la cancela de
  Vista Alegre abierta. Restaurada, la puerta del sureste está abierta y un paso entre las gradas lleva al callejón
  y al ruedo (barrera roja con cuatro burladeros); el solar no tiene valla y tiene arbolitos en dos hileras.
- Prueba: `python tools/run_tests.py toros --window` (18 fotos, 9 de cada estado, y 5 comprobaciones).

## Hojas (`guion/fotos/toros/`)
`01`: la ruina frente a Street View de mayo de 2009 · `02`: la restaurada frente a 2013 y 2024 · `03`: los dos
estados en el juego (de cerca, desde el aire y por dentro).

## Lo que es aproximado
- El **interior** no se ve desde la calle en ninguna época: el graderío (cinco gradas de hormigón), la barrera, los
  burladeros y el bloque de toriles están hechos por la ortofoto y por cómo son estas plazas. En la ruina, el
  graderío es un talud de tierra.
- Restaurada se ha hecho **lista para usarse** (albero, barrera roja, puerta abierta, sin valla), que es para lo
  que servirá en el juego; la real sigue hoy con el ruedo en hierba, la puerta cerrada y el solar vallado.
- La forma exacta de cada contrafuerte en ruinas (cuánto le falta a cada uno) es inventada: se repite igual siempre,
  pero no copia los reales uno a uno. El cobertizo viejo está donde lo ponen las fotos de 2006 y 2009, a ojo de tamaño.
- El arco norte del anillo da a los corrales de las casas de la calle Bienvenida y no se ha podido ver: va liso, sin
  contrafuertes. Esas casas son las genéricas del juego.
- El número de contrafuertes (70) sale de contar los del medio anillo que se ve en la ortofoto.
- Los arbolitos son de la ortofoto actual, en dos hileras regulares; los reales están algo más revueltos.
