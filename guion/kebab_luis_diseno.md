# Kebab Luis — diseño (palabras del usuario, 13 de noviembre de 2026)

Lo construido hasta ahora está en `godot/scripts/kebab.gd`. Esto es lo que el usuario ha pedido y **aún no está hecho**
(son sistemas de juego, no decorado), apuntado tal cual para no perderlo.

## Don Luis
- Inspirado en un amigo del usuario: informático, fanático de los kebabs, siempre dice de dejarlo todo y montar un kebab.
- Gordo (anchuras: hermoso), faltón, le gusta demasiado hacer gracias todo el rato.
- Estudió el doble grado en la universidad de Cuenca de software y durum avanzado.
- Hermano de La Chiki; descendiente sin especificar de Nazario.
- **Nazario**: personaje futuro que estará siempre en la plaza del pueblo para contar historias.

## Clientes
- Solo UNA mesa (aleatoria cada día) tiene siempre vecinos fijos comiendo y hablando. *(Hecho: los fijos; no hablan aún.)*
- Los demás vecinos que se acerquen al kebab tienen un 33 % de probabilidades de parar, hacer cola, pedirle algo a
  Don Luis y sentarse a comerlo. «Terminar de comer» dura 30–45 segundos de tiempo real; se van entre 15 y 30 segundos
  después y siguen con su ruta.

## Comida y estado físico (sistema nuevo para todo el juego)
- Se añadirá comida al juego.
- Si comes más de tres veces en un mismo día del juego, pasas a la siguiente anchura de la que tuvieses.
- Si estás en la anchura máxima y comes 4 veces en un mismo día, te «desmayas»: la pantalla coge efecto de borracho
  (como AC4 o Red Dead Redemption), andas errático y tropezándote (efecto ragdoll cada 10 segundos andando) y a los
  50 segundos, fundido a negro y apareces en el centro de salud del pueblo (pendiente de modelar).

## Reglas generales de misiones (valen para todas)
- Todas las misiones se pueden aceptar o rechazar. Rechazar hace que quien te la daba suelte un comentario desagradable
  y te diga que luego hables con él/ella.
- Las misiones de teléfono salen con un Sí/No. Si rechazas, te vuelven a llamar cuando cumplas otra misión, o si los
  llamas tú de vuelta.
- El nivel de los Pitufos estará al 50 % con misiones activas salvo que se indique lo contrario, para no presionar
  demasiado al jugador con conducir perfecto en mitad de una misión.

## Misión secundaria de Don Luis (al completarla se desbloquea en la agenda)
Le preocupa ser el cuarto kebab que ha abierto en un pueblo no tan grande, así que te pide que vayas a los otros tres a
sabotear su comida: «no es ético, pero en el amor y en kebab todo vale».

1. Al aceptar te dice que el camión de reparto de kebab acaba de irse de su restaurante (cinemática: el repartidor sale
   del kebab, se sube al camión y arranca) y va a los otros tres comercios.
2. Hay que seguir al camión: ni muy cerca, porque te ve, ni muy lejos, porque lo pierdes de vista.
3. Cuando el camión llega a un kebab, saca dos cajas y las deja enfrente. Tienes 30 segundos hasta que el camión vuelva
   a arrancar para acercarte a las cajas y «sabotearlas»: echarles un moco, mearte y cagarte, respectivamente según el
   restaurante. Hay que esperar a que el repartidor se dirija al camión y esté de espaldas.
4. En cuanto terminas de sabotear: cinemática del camión arrancando y aviso de subirte rápido a un coche.
5. El repartidor habla en «árabe» de vez en cuando (al subirse o bajar del camión, al descargar las cajas), pero todas
   las frases son del tipo: «Lo siento, no sé árabe, esto es un texto de ejemplo» // «Te has quedado sin tokens para
   esta traducción» // «Cuscus, marruecos... que sé yo... ¿Paris-Saint Germain?» — la broma es que se ha metido un
   personaje árabe sin tener ni idea de su idioma.
6. **Fracaso** (te pilla, lo pierdes de vista o te acercas demasiado): se avisa por pantalla y te llama Don Luis
   diciendo que vuelvas a su restaurante para intentarlo otra vez, «que esto no puede quedar así». La misión se
   reinicia con menos texto.
7. **Éxito** (saboteas el tercero y último): vas a hablar con Don Luis para que te recompense: dinero y un kebab. Esto
   desbloquea a Don Luis y al kebab siempre que quieras ir.
8. Si vuelves a hablar con él pasado al menos un día, te dice que al final el sabotaje no sirvió de nada porque nadie
   notó la diferencia de sabor; de hecho algunos lo consideraron mejor que otros días.

## Hace falta antes
- Los otros tres kebabs del pueblo (dónde están: lo dirá el usuario).
- El camión de reparto y el repartidor.
- El centro de salud.

---

# Lo construido (sesión de sistemas, 13 de noviembre de 2026)

Todo lo de arriba está hecho salvo el centro de salud y los modelos definitivos del camión y del repartidor. Cada pieza
tiene su prueba: `--selftest --kebab`, `--comida`, `--reglas`, `--sabotaje` (con `--shots` y sin `--headless`, saca fotos).

## Clientes (`godot/scripts/clientes.gd`)
- 33 % de pararse. «Acercarse al kebab» era al principio pasar por delante de la verja; el usuario lo vio vacío y pidió
  más gente: ahora cuenta cualquier vecino que ande a menos de 70 m, que viene por las aceras hasta la verja, y al que
  se le vuelve a tirar el dado cada minuto que siga por la zona (o cuando se aleje más de 85 m y vuelva). Con eso hay
  entre 2 y 7 clientes a la vez (medido: unos 19 en 10 minutos).
- Cola de hasta seis ante la barra (tres dentro, tres fuera), piden (`kebab_pide`), Don Luis contesta (`kebab_sirve`),
  llevan la comida a una silla libre que no sea de la mesa de los fijos, comen 30–45 s, se quedan 15–30 s con el plato
  vacío y vuelven a la calle a seguir su paseo. Si cambia el día y los fijos ocupan su mesa, se levantan.

## Comida y anchuras (`godot/scripts/comida.gd`)
- Se come hablando con Henry (siempre) o con Don Luis (una vez hecha su misión): 5 € — **precio provisional**.
- La cuarta comida del día sube una anchura (0,86 → 1,0 → 1,2). Una quinta ese mismo día no hace nada más. No hay forma
  de adelgazar: no se ha pedido.
- En la anchura máxima, la cuarta comida es el desmayo: pantalla de borracho, andar torcido, voltereta cada 10 s
  andando, y a los 50 s fundido a negro. **Apareces en la acera de tu casa** (respuesta del usuario) hasta que exista
  el centro de salud. Durante el desmayo no puedes subirte a un coche (decisión mía).

## Reglas de misiones (`game.gd`: `_offer`, `_recall`, `heat_scale`)
- Toda misión empieza con Aceptar / Rechazar; rechazar: comentario desagradable (`reject_<quien>`) y «luego hablas
  conmigo». Al volver a hablarle solo pregunta.
- Por teléfono: Sí / No. Si dices que no, te vuelve a llamar al acabar otra misión, o llamas tú desde la Agenda
  (Vecinos → «Llamar a…»). El jamón de los jueves también pregunta; si llamas pasado el mediodía, ya ha comido.
- Pitufos al 50 % (respuesta del usuario): con una misión en marcha, lo que sumaría 10 al medidor suma 5. Una misión
  puede decir otra cosa con `heat` (el jamón sigue sin sumar nada).

## Misión de Don Luis (`godot/scripts/sabotaje.gd`), «En el amor y en kebab»
- El título es mío, sacado de su frase. Paga 30 € (**provisional**) y un kebab, que se come en el momento.
- Orden: Kebab Deluxe (moco), Tele Durum (meada), ShawarMadridejos (cagada).
- Te ve por el retrovisor si vas a menos de 13 m detrás de él, en marcha, 2 s; lo pierdes a más de 100 m durante 6 s o
  sin verlo 12 s (estando a más de 45 m). Fuera del camión ve 16 m hacia delante. 30 s desde que deja las cajas.
- Frases de «árabe»: las tres del usuario y tres más del mismo estilo («[Inserte aquí una frase en árabe]», «Error 404:
  idioma no encontrado», «Habibi… shawarma… y hasta aquí llega mi árabe»).
- **Provisional**: el camión es un Z15 negro y el repartidor un vecino con gorra roja y chándal verde (constantes
  `LORRY`, `LORRY_PAINT` y `MAN` de `sabotaje.gd`). El primer trayecto (del Kebab Luis al Kebab Deluxe) es de más de un
  kilómetro: unos tres minutos siguiéndolo.
