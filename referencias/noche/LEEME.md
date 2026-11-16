# Referencia: el Dia de la Calle del Teniente Infante («Noche»)

Pedido por Luis el 17-11-2026: «Puedes empezar con el Dia (al que llamaremos Noche): C. Teniente Infante, 18 ... Hazle
lo mismo de siempre. Modelo abierto y cerrado según el horario. Haz que se pueda pasar y haz un interior genérico de
momento». Y luego, con una foto de la tienda como era: «Mismos colores y diseños, pero que ponga noche y el logotipo en
vez de un porcentaje, una luna». Su veredicto: «Está impecable. Ponle en un trozo de fachada blanca un póster de Roster y
finiquitamos esto»: el póster de Roster Energy (el suyo, redibujado: `assets/chinos/poster_roster.png`) va pegado algo
torcido en el blanco a la izquierda de la puerta. Terminado.

El modelo es `godot/scripts/noche.gd` (sobre `obra.gd`), en `world.noche`; el interior, `godot/scripts/noche_dentro.gd`.
Herramientas: `tools/noche/`. Dibujos (todos nuestros): `godot/assets/noche/`, hechos con `tools/noche/dibujos.py`.

## Dónde
La casa de tres alturas de la Calle del Teniente Infante (Catastro 4290005VJ5649S, de 2005): la tienda en la planta
baja (374 m², con la nave de una planta de detrás) y dos viviendas encima. Su frente, de 7,8 m, da al norte, a la calle.
En el mapa era un bloque genérico: se rehornea para que no se levante y la hace `noche.gd`.

## Fuentes
- **Street View**: noviembre de 2024 para la casa (`tools/noche/capturas.py`), y 2013 y 2019 para la tienda como era,
  con el diseño de la foto de Luis. Las fotos son de Google: no se guardan.
- **Catastro** (`tools/casas/4290005VJ5649S/`): sus dos partes (la casa y la nave de detrás) y la foto antigua.
- **Ortofoto** del PNOA (`tools/ign/noche.{jpg,json}`).

## Medidas (desde la cámara de enfrente, 2019, de frente)
De la esquina este, a lo largo del frente: el pilar de ladrillo (0–0,45 m); la puerta de las viviendas de 0,85 a 3,05 m,
de arco rebajado (arranca a 2,45 m y la clave a 3,05 m), en un cerco de ladrillo; la tienda de 3,6 m al final (7,8 m).
La puerta de la tienda de 4,55 a 6,59 m, metida 0,6 m; el rótulo de 4,55 a 7 m, de 2,93 a 3,42 m de alto, y la franja verde
justo debajo, hasta 2,74 m. El primer balcón a 3,45 m, el segundo a 6,6 m; la cornisa a 10,2 m. Los balcones de
6,6 m de cuerda salen 0,95 m en el centro.

## Lo que hay
- **La casa**: revoco crema entre dos pilares de ladrillo claro (el oeste empieza encima de la tienda). Los dos balcones
  en curva, con canto de ladrillo, suelo de baldosa roja y barandilla de hierro con su banda de bolitas; detrás, las
  puertas de madera de cuatro hojas con visillos y la persiana a medio bajar con su caja; dos aparatos de aire. Arriba,
  la cornisa en curva y el pretil. La caja de contadores en el pilar y los cables por la fachada.
- **La puerta de las viviendas**: hierro verde en cuadrícula sobre cristal y visillos blancos, el abanico de barras en el
  arco, los tiradores dorados y el escalón; cerco y arco de ladrillo con sus ladrillos a sardinel. Sin número.
- **La tienda** (el diseño de antes, el de la foto de Luis): blanca, con la banda roja ancha de esquinas redondeadas; el
  rótulo rojo con «Noche» en blanco y la luna en el cuadro de borde blanco (en vez del porcentaje); la franja verde lima
  con «MARKET» en rojo; la entrada metida, con paredes verde lima, las puertas de cristal correderas entre dos fijas con
  ofertas pegadas; la placa del horario; la banderola roja con la luna en las dos caras, en la esquina oeste.
- **Su horario** (Luis): de lunes a sábado de 9:00 a 21:30, el domingo cerrado. Abierta: la persiana arriba, la tienda
  iluminada detrás del cristal y el caballete de ofertas en la acera; al anochecer, el rótulo y la banderola en sus colores.
  Cerrada: la persiana gris bajada, a oscuras.
- **Se puede entrar**: la flecha verde delante de la puerta, en la acera, solo mientras está abierta (`entradas.gd`).
  Dentro, otra para salir con el botón de acción.
- **El interior** (`noche_dentro.gd`, genérico de momento): una sala de 10 × 16 m lejos del pueblo, en (1800, 1800). La
  caja junto a la puerta con su cinta, su pantalla, su silla y las bolsas; las cestas rojas; la fruta y la verdura en cajas;
  tres góndolas con productos y su cabecera de «OFERTA»; las cámaras de frescos a un lado y las bebidas al otro; los lácteos
  al fondo, bajo el logo con la luna; tubos en el techo.
- Detrás, la nave de una planta y la caja de la escalera en la azotea (no se ven desde la calle).

## Lo que es inventado o aproximado
- El diseño de la tienda es el de antes (hasta 2019), como pidió Luis; desde 2024 el frente es gris oscuro.
- La persiana: no se ve en las fotos. Las tiendas de la calle la tienen, y así se nota que está cerrada.
- El interior, genérico.
- Las partes de atrás, del Catastro y sin fotos.

## Pruebas
`python tools/run_tests.py noche`: fotos (abierta, cerrada, de noche, el interior) y comprobaciones: está hecha y su frente
para; da a la Calle del Teniente Infante; su horario mueve la persiana y el interior; se entra por la flecha y se sale.
