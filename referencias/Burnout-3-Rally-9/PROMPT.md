# Prompt para implementar RALLY 9 en Matritellus

Descomprime el dossier en una carpeta accesible desde el chat que vaya a trabajar sobre el repositorio. Copia el bloque siguiente.

```text
Implementa RALLY 9 como minijuego de carreras jugable en la recreativa de conducción del Galaxy Recress de Matritellus. Lee el README del dossier Burnout-3-Rally-9 y sus imágenes. Usa como referencias el cambio de cámara del vídeo de BR4GG4 entre 00:13 y 00:16 y el aftertouch de 00:25 a 00:36. Emplea coches, entorno, rótulos, sonidos y música propios de Matritellus.

Localiza la copia activa del proyecto, sus instrucciones y su versión de Godot. Revisa el mueble rotulado RALLY 9 en recress_sala.gd, la entrada por game.gd y recress.gd, y la conducción en car.gd, derrape.gd, controls.gd, touch.gd, hud.gd y loc.gd. Da al asiento rojo un punto de interacción reconocible tras la reapertura del salón. Conserva la misión, horarios, entrada y partidas vecinas de Tokken. Al salir o terminar, devuelve al jugador al asiento con la cámara y los controles del salón.

Haz una prueba completa de dos vueltas con El Tunero, tres rivales, tráfico de la simulación y clasificación por orden de meta. Diseña un circuito propio con parrilla, curva de derrape, recta para esquivas y barrera exterior. Cuenta pasos de control en orden y en sentido correcto. Los rivales deben poder completar la carrera y reincorporarse después de un accidente. Muestra puesto, vuelta, velocidad, carga y capacidad de nitro.

Reutiliza la conducción y el impulso de car.gd. Dentro de la recreativa, la economía del README debe gobernar el nitro en un único sitio. Distingue reserva, capacidad y puntos de la maniobra. Implementa nitro dosificable, esquivas, derrapes, contacto atribuible, derribo y accidente propio con aftertouch breve. Usa el apartado «Una primera carrera completa» para los valores iniciales y los ejemplos. Evita puntuar dos veces por un mismo suceso. La policía, el tráfico persistente, los vehículos y el inventario del pueblo tienen un ciclo de vida separado de esta partida de recreativa.

Haz legible el paso de la conducción tras el jugador al plano breve del rival que cae y la vuelta a la carretera. En un accidente propio, sigue los restos y permite influencia lateral limitada antes de la reincorporación. Conserva horizonte, carril y sentido de avance al volver. Añade cámara continua y efectos de velocidad reducidos. La simulación del intento y su reloj deben avanzar al mismo ritmo. Permite jugar con teclado, mando y pantalla táctil, incluyendo dirección, aceleración y nitro simultáneos. Respeta ajustes y glifos existentes y localiza las indicaciones ES/EN.

Implementa y verifica el flujo normal desde el mueble. Prueba victoria o derrota por puesto, puertas en orden, vuelta inválida, derribo atribuido y ajeno, dos contactos en un paso, agotamiento y recarga, aftertouch con y sin éxito, pausa durante un plano, meta durante un contacto, pérdida de foco y dos partidas seguidas. Comprueba las regresiones de derrape y Recress con la batería del repositorio. Añade un filtro de carrera si hace falta. Realiza una vuelta con imagen y revisa al menos el HUD durante el impulso, el plano del rival y la reincorporación. Indica dónde jugar, los controles finales, los ajustes que cambiaste al probar y qué dispositivos comprobaste físicamente.
```
