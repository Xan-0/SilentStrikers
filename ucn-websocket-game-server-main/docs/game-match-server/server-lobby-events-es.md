# Eventos de la sala de espera y comunicación (Lobby)

> Si necesitas volver al documento anterior, haz clic [aquí](./server-connect-and-use-es.md).

Al conectarse al servidor de juego, el jugador será agregado automáticamente a la sala de espera y comunicación 
(Lobby). De esta forma, el jugador podrá recibir eventos de mensajes recibidos, como también eventos de solicitud
de partida (abordados en el documento [Eventos de emparejamiento y creación de partidas (Matchmaking)](./server-match-events-es.md)).

- [Resumen de eventos](#resumen-de-eventos)
- [Mensaje público recibido (public-message)](#mensaje-público-recibido-public-message)
- [Mensaje privado recibido (private-message)](#mensaje-privado-recibido-private-message)
- [Actualización de estado del jugador (player-status-changed)](#actualización-de-estado-del-jugador-player-status-changed)
- [Obtener todos los jugadores conectados (online-players)](#obtener-todos-los-jugadores-conectados-online-players)
- [Enviar un mensaje público (send-public-message)](#enviar-un-mensaje-público-send-public-message)
- [Enviar un mensaje privado (send-private-message)](#enviar-un-mensaje-privado-send-private-message)

## Resumen de eventos

| Evento                  | Tipo     | Descripción                                            |
|-------------------------|----------|--------------------------------------------------------|
| `public-message`        | Entrante | Avisa que un jugador ha mandando un mensaje a todos.   |
| `private-message`       | Entrante | Avisa que un jugador te ha enviado un mensaje privado. |
| `player-status-changed` | Entrante | Avisa que un jugador ha cambiado de estado.            |
| `online-players`        | Saliente | Obtiene el listado de jugadores conectados.            |
| `send-public-message`   | Saliente | Manda un mensaje a todos los jugadores conectados.     |
| `send-private-message`  | Saliente | Manda un mensaje a un solo jugador indicado.           |

## Mensaje público recibido (public-message)

| Resumen         |                                                                                     |
|-----------------|-------------------------------------------------------------------------------------|
| __Evento__      | `public-message`                                                                    |
| __Tipo__        | Evento entrante (_Listen_).                                                         |
| __Descripción__ | Evento que indica que se ha recibido un mensaje de un jugador desde el chat grupal. |
| __Respuesta__   | `playerId` (_string_): ID de jugador que ha enviado el mensaje.                     |
|                 | `playerName` (_string_): Nombre de jugador que ha enviado el mensaje.               |
|                 | `playerMsg` (_string_): Mensaje enviado por el jugador.                             |

Este evento avisa que un jugador ha enviado un mensaje por la sala pública, por lo que todos los jugadores han recibido
el mismo mensaje. De esta forma, cuando se reciba esta acción, se puede concatentar cada mensaje recibido en un listado
o interfaz gráfica y asi tener registro de todos los mensajes enviados por los jugadores.

Ejemplo de respuesta:
```jsonc
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

## Mensaje privado recibido (private-message)

| Resumen         |                                                                                 |
|-----------------|---------------------------------------------------------------------------------|
| __Evento__      | `private-message`                                                               |
| __Tipo__        | Evento entrante (_Listen_).                                                     |
| __Descripción__ | Evento que indica que se ha recibido un mensaje de un jugador de forma privada. |
| __Respuesta__   | `playerId` (_string_): ID de jugador que ha enviado el mensaje.                 |
|                 | `playerName` (_string_): Nombre de jugador que ha enviado el mensaje.           |
|                 | `playerMsg` (_string_): Mensaje enviado por el jugador.                         |

Este evento le avisa que un jugador le ha enviado un mensaje por privado. La estructura recibida es igual que la de
los mensajes públicos. Puede agregar este mensaje en su interfaz gráfica (como una pestaña nueva o dentro del chat
grupal con un indicador diferente) para mantener el historial de la conversación.

Ejemplo de respuesta:
```jsonc
{
  "event": "private-message",
  "msg": "Player 'Player_Two' have sent you a private message.",
  "data": {
    "playerId": "c3e5aca7-f1c0-40ed-8b5c-aac3f58d137f",
    "playerName": "Player_Two",
    "playerMsg": "Como te encuentras? Quieres jugar una partida?"
  }
}
```

## Actualización de estado del jugador (player-status-changed)

| Resumen         |                                                                                        |
|-----------------|----------------------------------------------------------------------------------------|
| __Evento__      | `player-status-changed`                                                                |
| __Tipo__        | Evento entrante (_Listen_).                                                            |
| __Descripción__ | Evento que indica que se ha actualizado el estado de un jugador.                       |
| __Respuesta__   | `playerId` (_string_): ID de jugador actualizado.                                      |
|                 | `playerStatus` (_string_): Estado nuevo del jugador (`IN_MATCH`, `AVAILABLE`, `BUSY`). |

Este evento es recibido cuando se actualiza el estado de un jugador. Un jugador puede cambiar entre los estados
disponible (`AVAILABLE`), ocupado (`BUSY`) o en partida (`IN_MATCH`) cuando ocurren ciertas acciones, como
entrar a una partida o enviar/recibir solicitudes de partida. Este evento contiene el identificador y el nuevo
estado del jugador para un mejor manejo del cambio y evitar llamadas innecesarias al evento `online-players`.
Este evento no lo recibe el jugador que cambia de estado.

Ejemplo de respuesta recibida:
```jsonc
{
  "event": "player-status-changed",
  "msg": "Player 'Player_Two' change status to 'BUSY'",
  "data": {
    "playerId": "c3e5aca7-f1c0-40ed-8b5c-aac3f58d137f",
    "playerStatus": "BUSY"
  }
}
```

## Obtener todos los jugadores conectados (online-players)

| Resumen         |                                                                                     |
|-----------------|-------------------------------------------------------------------------------------|
| __Evento__      | `online-players`                                                                    |
| __Tipo__        | Evento saliente (_Trigger_).                                                        |
| __Descripción__ | Evento para solicitar el listado de jugadores conectados al servidor.               |
| __Parámetros__  | _Ninguno_.                                                                          |
| __Respuesta__   | ___Array___ con la información de los jugadores conectados.                         |
|                 | - `id` (_string_): ID de jugador.                                                   |
|                 | - `name` (_string_): Nombre de jugador.                                             |
|                 | - `game` (_object_): Datos del cliente de juego.                                    |
|                 | - `game.id` (_string_): ID del juego conectado.                                     |
|                 | - `game.name` (_string_): Nombre del juego.                                         |
|                 | - `game.team` (_string_): Nombre del equipo desarrollador.                          |
|                 | - `status` (_string_): Estado actual del jugador (`AVAILABLE`, `BUSY`, `IN_MATCH`). |

Este evento se envia al servidor para obtener los jugadores que se encuentran conectados. Esta función no requiere
parámetros, por lo que se puede enviar sin un cuerpo establecido (parámetro "data"). Esta función es util para
recuperar la información de los jugadores al momento de conectarse al servidor, cuando se pierde la conexión por
cualquier motivo, o cuando se vuelve a la sala de espera después de jugar una partida multijugador. 

De la respuesta se obtienen cuatro elementos:
- El ID del jugador, el cual se utiliza para el funcionamiento interno del servicio.
- El nombre del jugador, que ayuda a reconocer a cada uno y evitar que el jugador deba manejarse en la interfaz
  con el identificador.
- Datos del cliente de juego, que permite reconocer el cliente de juego al que esta conectado el jugador.
- El estado del jugador, que permite saber si se encuentra disponible para jugar (AVAILABLE), esta ocupado con una
  solicitud de partida (BUSY) o se encuentra actualmente en una partida (IN_MATCH).

Ejemplo de solicitud:
```jsonc
// Evento enviado por el jugador
{
  "event": "online-players"
}

// Respuesta entregada por el servidor
{
  "event": "online-players",
  "status": "OK",
  "msg": "Player list obtained.",
  "data": [
    {
      "id": "0f2cc688-dcf3-4952-b8f8-c52f75f316d4",
      "name": "Player_One",
      "game": {
        "id": "A",
        "name": "Contaminación Mortal",
        "team": "404 Studios"
      },
      "status": "AVAILABLE"
    },
    {
      "id": "c3e5aca7-f1c0-40ed-8b5c-aac3f58d137f",
      "name": "Player_Two",
      "game": {
        "id": "B",
        "name": "Silent Strikers",
        "team": "Phantom Bytes"
      },
      "status": "IN_MATCH"
    }
  ]
}
```

## Enviar un mensaje público (send-public-message)

| Resumen         |                                                                                     |
|-----------------|-------------------------------------------------------------------------------------|
| __Evento__      | `send-public-message`                                                               |
| __Tipo__        | Evento saliente (_Trigger_).                                                        |
| __Descripción__ | Evento para enviar un mensaje a todos los jugadores conectados en el chat grupal.   |
| __Parámetros__  | `message` (_string_): Mensaje a enviar a los jugadores.                             |
| __Respuesta__   | `message` (_string_): Mensaje enviado por el jugador.                               |

Esta evento permite enviar un mensaje a la sala publica, con el fin de que el resto de jugadores reciban el
mensaje y puedan comunicarse con usted. Si el mensaje se envió correctamente, usted recibirá una respuesta de
confirmación, y el resto de jugadores recibirán el evento `public-message` con su mensaje enviado (véase 
[Mensaje público recibido](#mensaje-público-recibido-public-message)).

Ejemplo de solicitud:
```jsonc
// Evento enviado por el jugador
{
  "event": "send-public-message",
  "data": {
    "message": "Hola! Cómo estan todos?"
  }
}

// Respuesta entregada por el servidor
{
  "event": "send-public-message",
  "status": "OK",
  "msg": "Message sent to all players.",
  "data": {
    "message": "Hola! Cómo estan todos?"
  }
}
```

El evento también retornará una respuesta incorrecta en caso que se envíe un mensaje en blanco o no se envíe el
parámetro `message`.

Ejemplo de solicitud incorrecta:
```jsonc
// Evento enviado por el jugador
{
  "event": "send-public-message",
  "data": { }
}

// Respuesta entregada por el servidor
{
  "event": "send-public-message",
  "status": "ERROR",
  "msg": "You cannot send an empty message.",
  "data": {
    "message": "undefined"
  }
}
```

## Enviar un mensaje privado (send-private-message)

| Resumen         |                                                                          |
|-----------------|--------------------------------------------------------------------------|
| __Evento__      | `send-private-message`                                                   |
| __Tipo__        | Evento saliente (_Trigger_).                                             |
| __Descripción__ | Evento para enviar un mensaje a un solo jugador conectado en específico. |
| __Parámetros__  | `playerId` (_string_): Identificador del jugador a enviar el mensaje.    |
|                 | `message` (_string_): Mensaje que se enviará al jugador.                 |
| __Respuesta__   | `playerId` (_string_): ID del jugador que recibió el mensaje.            |
|                 | `message` (_string_): Mensaje enviado por el jugador.                    |

Este evento sirve para mandar un mensaje a un jugador específico que se encuentre conectado. Si el mensaje
se envió correctamente, recibirá una respuesta de confirmación. Acto seguido, el jugador destinatario del
mensaje recibirá el evento `private-message`, indicando que recibió un mensaje nuevo (véase [Mensaje privado recibido](#mensaje-privado-recibido-private-message)).

Ejemplo de solicitud:
```jsonc
// Evento enviado por el jugador
{
  "event": "send-private-message",
  "data": {
    "playerId": "c3e5aca7-f1c0-40ed-8b5c-aac3f58d137f",
    "message": "Como te encuentras? Quieres jugar una partida?"
  }
}

// Respuesta entregada por el servidor
{
  "event": "send-private-message",
  "status": "OK",
  "msg": "Message sent to Player_Two.",
  "data": {
    "playerId": "c3e5aca7-f1c0-40ed-8b5c-aac3f58d137f",
    "message": "Como te encuentras? Quieres jugar una partida?"
  }
}
```

El evento puede retornar una respuesta incorrecta si es que el ID del jugador no existe, si se envía un mensaje en
blanco, o no se envia alguno de los parámetros (`message` o `playerId`).

Ejemplo de solicitudes incorrectas:
```jsonc
// Evento enviado por el jugador
{
  "event": "send-public-message",
  "data": { 
    "playerId": ""
  }
}

// Respuesta entregada por el servidor
{
  "event": "send-private-message",
  "status": "ERROR",
  "msg": "Player with ID undefined not exists.",
  "data": {
    "playerId": ""
  }
}
```
```jsonc
// Evento enviado por el jugador
{
  "event": "send-private-message",
  "data": {
    "playerId": "c3e5aca7-f1c0-40ed-8b5c-aac3f58d137f"
  }
}

// Respuesta entregada por el servidor
{
  "event": "send-private-message",
  "status": "ERROR",
  "msg": "You cannot send an empty message.",
  "data": {
    "message": "undefined"
  }
}
```