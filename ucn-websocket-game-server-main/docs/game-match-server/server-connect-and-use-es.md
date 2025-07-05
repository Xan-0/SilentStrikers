# Conexión y uso del servidor de partidas

- [Descripción de Comunicación](#descripción-de-comunicación)
- [Conexión al servidor](#conexión-al-servidor)
- [Envío y recibo de mensajes](#envío-y-recepción-de-mensajes)
- [Descripción de Eventos](#descripción-de-eventos)

## Descripción de Comunicación
La comunicación vía WebSockets se realiza mediante el intercambio de mensajes en tiempo real. Cuando el cliente
(usted) solicite una acción, esta se envia mediante un texto por la conexión concretada y luego el servidor la
procesa. Según el caso, puede recibir una respuesta de confirmación de la acción con información o no.

Según la acción que se realice, el servidor puede enviar acciones a un cliente, a varios, o a todos los clientes
conectados. Por lo tanto, dentro de la comunicación se debe mantener la atencion a los eventos que se pueden
recibir y ejecutar las acciones que estimen pertinentes.

## Conexión al servidor
Para conectarse al servidor de juego, se le entregará una URL a la que su cliente de juego debe conectarse.
Esta URL esta formada de la siguiente manera: 

```url
ws://nombre-del-servidor.com/
```

Puede usar algun servicio como [Postman](https://www.postman.com/) o [Insomnia](https://insomnia.rest/) para
realizar pruebas a este endpoint.

Por funcionamiento del servidor, el jugador es desconectado automaticamente si luego de 1 minuto no ha enviado
ni recibido acciones. Puede enviar un evento aleatorio (como `'ping'`) cada cierto tiempo para evitar ser
desconectado por inactividad.

En la URL es posible pasar algunos parámetros de configuración inicial. Estos parámetros son:
- gameId (__Requerido__): Indica el juego que se está conectando al servidor. Revise 
[este archivo](../../src/websocket/game/game.service.ts) para obtener el ID asociado a su juego.
- playerName (_Opcional_): Permite configurar el nombre del jugador sin la necesidad de llamar al evento
`change-name`.

Una ruta de ejemplo con los parámetros indicados sería la siguiente:
```url
ws://nombre-del-servidor.com/?gameId=A&playerName=Player_One_UCN
```

Luego de conectarse, el servidor le solicitará que inicie sesión. Esto se hace con el fin de evitar accesos
cruzados incorrectos. Por ejemplo, que otro juego pueda suplantar la identidad de un jugador. Este código será
entregado a cada equipo por separado, y se deberá usar el evento `login` para iniciar sesión y utilizar los
otros eventos. Siga leyendo el documento para más información.

## Envío y recepción de mensajes
La solicitud y recepción de eventos por parte del cliente se realiza mediante mensajes de texto transmitidos
por el canal de comunicación establecido al conectarse al servidor. Estos mensajes están codificados en formato
[JSON](https://www.json.org/json-es.html), el cuál es un formato de intercambio de datos mediante serialización
utilizando clave-valor.  

La estructura del objeto JSON que se utiliza para el intercambio de eventos es similar para todos los casos.

Para enviar eventos al servidor con el fin de ejecutar alguna acción, se debe mandar la siguiente estructura
por el canal de comunicación abierto por el WebSocket:

```json
{
  "event": "change-name",
  "data": {
    "name": "New_Player_Name_UCN",
  }
}
```

| Propiedad | Tipo     | Descripción                                                   |
|-----------|----------|---------------------------------------------------------------|
| `event`   | _string_ | Nombre del evento que se enviará al servidor.                 |
| `data`    | _object_ | Datos a enviar con la solicitud (específicos de cada evento). |

Para el caso de los eventos emitidos por el servidor o por otros usuarios, el contenido recibido será el
siguiente:

```json
{
  "event": "public-message",
  "msg": "Player 'Player_Two' have sent a message.",
  "data": {
    "playerId": "c3e5aca7-f1c0-40ed-8b5c-aac3f58d137f",
    "playerName": "Player_Two",
    "playerMsg": "Hola! Cómo estan todos?"
  }
}
```

| Propiedad | Tipo     | Descripción                                                     |
|-----------|----------|-----------------------------------------------------------------|
| `event`   | _string_ | Nombre del evento gatillado por el servidor o por otro jugador. |
| `msg`     | _string_ | Mensaje notificatorio respecto a lo que realizó el evento.      |
| `data`    | _object_ | Datos recibidos por el evento gatillado por un tercero.         |

Por último, para eventos emitidos por el mismo usuario, este recibirá una respuesta con la siguiente estructura:

```json
{
  "event": "send-public-message",
  "status": "OK",
  "msg": "Message sent to all players",
  "data": {
    "message": "Hola! Como estan todos"
  }
}
```

| Propiedad | Tipo     | Descripción                                                                     |
|-----------|----------|---------------------------------------------------------------------------------|
| `event`   | _string_ | Nombre del evento que gatilló el jugador.                                       |
| `status`  | _string_ | Estado de la respuesta recibida. Puede ser correcta (OK) o con errores (ERROR). |
| `msg`     | _string_ | Mensaje notificatorio respecto a lo que realizó el evento.                      |
| `data`    | _object_ | Datos recibidos por el evento solicitado. El contenido dependerá del evento.    |

Links de interés:
- [Manejo de cadenas de texto JSON en Godot (en inglés)](https://docs.godotengine.org/en/stable/classes/class_json.html)
- [Manejo de cadenas de texto JSON en Unity](https://docs.unity3d.com/es/530/Manual/JSONSerialization.html)

## Descripción de Eventos
En primer lugar, debemos definir dos tipos de eventos:

- __Evento Entrante__: Mensajes que son enviados por el servidor y recibidos por los jugadores. Estos eventos
                      son de escucha, y según el evento recibido en el parámetro `event` se deben ejecutar
                      ciertas acciones en los clientes. También son llamados como _Listener_.
- __Evento Saliente__: Mensajes que son enviados por los jugadores hacia el servidor para ejecutar una acción.
                       Estos eventos se deben construir en los clientes y enviarse al servidor. El servidor
                       responderá al cliente con un mensaje de satisfacción o error, y ejecutará las acciones
                       pertinentes al evento en sí. También son llamados como _Trigger_.

El servidor tiene cinco tipos de eventos, los cuales se encuentran descritos en documentos separados por
legibilidad. El resumen de los eventos procesados por el servidor se puede revisar en el apartado desplegable
de cada sección.

### [Conexión/desconexión (Login/Logout)](./server-login-events-es.md).
Son todos los eventos relacionados a la conexión y desconexión de jugadores.

<details>
<summary>Listado de eventos posibles:</summary>

| Evento                | Tipo     | Descripción                                |
|-----------------------|----------|--------------------------------------------|
| `connected-to-server` | Entrante | Indica que te has conectado al servidor.   |
| `player-connected`    | Entrante | Indica que un jugador se ha conectado.     |
| `player-disconnected` | Entrante | Indica que un jugador se ha desconectado.  |
| `login`               | Saliente | Se usa para iniciar sesión en el servidor. |

</details>

### [Configuración del jugador (Player)](./server-player-events-es.md)
Son todos los eventos relacionados a la configuración del jugador, como el cambio de nombre y la obtención de
data importante.

<details>
<summary>Listado de eventos posibles:</summary>

| Evento                | Tipo     | Descripción                                 |
|-----------------------|----------|---------------------------------------------|
| `player-name-changed` | Entrante | Avisa que un jugador ha cambiado su nombre. |
| `player-data`         | Saliente | Obtiene los datos del jugador actual.       |
| `change-name`         | Saliente | Permite cambiar el nombre del jugador.      |

</details>

### [Sala de espera y comunicación (Lobby)](./server-lobby-events-es.md)
Son todos los eventos de la sala de espera, como el envío de mensaje públicos y privados.

<details>
<summary>Listado de eventos posibles:</summary>

| Evento                  | Tipo     | Descripción                                            |
|-------------------------|----------|--------------------------------------------------------|
| `public-message`        | Entrante | Avisa que un jugador ha mandando un mensaje a todos.   |
| `private-message`       | Entrante | Avisa que un jugador te ha enviado un mensaje privado. |
| `player-status-changed` | Entrante | Avisa que un jugador ha cambiado de estado.            |
| `online-players`        | Saliente | Obtiene el listado de jugadores conectados.            |
| `send-public-message`   | Saliente | Manda un mensaje a todos los jugadores conectados.     |
| `send-private-message`  | Saliente | Manda un mensaje a un solo jugador indicado.           |

</details>

### [Emparejamiento y creación de partidas (Matchmaking)](./server-match-events-es.md)
Son todos los eventos relacionados a las solicitudes de partida, como invitaciones, aceptar y rechazar.

<details>
<summary>Listado de eventos posibles:</summary>

| Evento                     | Tipo     | Descripción                                                          |
|----------------------------|----------|----------------------------------------------------------------------|
| `match-request-received`   | Entrante | Avisa que recibiste una solicitud de partida.                        |
| `match-canceled-by-sender` | Entrante | Avisa que la solicitud de partida fue cancelada por el otro jugador. |
| `match-accepted`           | Entrante | Avisa que el otro jugador aceptó la solicitud de partida.            |
| `match-rejected`           | Entrante | Avisa que el otro jugador rechazó la solicitud de partida.           |
| `send-match-request`       | Saliente | Manda una solicitud de partida a un jugador disponible.              |
| `cancel-match-request`     | Saliente | Cancela la solicitud enviada al otro jugador.                        |
| `accept-match`             | Saliente | Acepta una solicitud de partida recibida.                            |
| `reject-match`             | Saliente | Rechaza una solicitud de partida recibida.                           |

</details>

### [Partidas en ejecución (Playing)](./server-game-match-events-es.md)
Son todos los eventos de la partida en ejecución, como el envío de datos a cada juego y las acciones de iniciar
y terminar partida.

<details>
<summary>Listado de eventos posibles:</summary>

| Evento                 | Tipo     | Descripción                                                             |
|------------------------|----------|-------------------------------------------------------------------------|
| `players-ready`        | Entrante | Avisa que ambos jugadores estan listos para comenzar la partida.        |
| `match-start`          | Entrante | Avisa que la partida ha iniciado y esta lista para recibir eventos.     |
| `receive-game-data`    | Entrante | Avisa que el otro jugador envió un evento a su partida.                 |
| `game-ended`           | Entrante | Avisa que un jugador ha ganado la partida.                              |
| `rematch-request`      | Entrante | Avisa que el otro jugador envió una solicitud para volver a jugar.      |
| `close-match`          | Entrante | Avisa que el otro jugador salió de la partida.                          |
| `connect-match`        | Saliente | Se utiliza para conectarse a la partida creada por la solicitud.        |
| `ping-match`           | Saliente | Se utiliza para establecer un primer contacto y determinar la latencia. |
| `send-game-data`       | Saliente | Envía datos hacia la partida del otros jugador.                         |
| `finish-game`          | Saliente | Se utiliza para declarar como ganador al jugador que manda este evento. |
| `send-rematch-request` | Saliente | Envía una solicitud para volver a jugar la misma partida.               |
| `quit-match`           | Saliente | Se utiliza para salir de una partida que ha finalizado.                 |

</details>
