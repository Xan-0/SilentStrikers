# Eventos de configuración del jugador (Player)

> Si necesitas volver al documento anterior, haz clic [aquí](./server-connect-and-use-es.md).

Los eventos descritos acá son de gestión del jugador, con el fin que se deba cambiar algun comportamiento
de este, como su nombre u otros parámetros a definir.

- [Resumen de eventos](#resumen-de-eventos)
- [Nombre de jugador cambiado (player-name-changed)](#nombre-de-jugador-cambiado-player-name-changed)
- [Obtener datos del jugador (player-data)](#obtener-datos-del-jugador-player-data)
- [Cambiar nombre del jugador (change-name)](#cambiar-nombre-del-jugador-change-name)

## Resumen de eventos

| Evento                | Tipo     | Descripción                                 |
|-----------------------|----------|---------------------------------------------|
| `player-name-changed` | Entrante | Avisa que un jugador ha cambiado su nombre. |
| `player-data`         | Saliente | Obtiene los datos del jugador actual.       |
| `change-name`         | Saliente | Permite cambiar el nombre del jugador.      |

## Nombre de jugador cambiado (player-name-changed)

| Resumen         |                                                               |
|-----------------|---------------------------------------------------------------|
| __Evento__      | `player-name-changed`                                         |
| __Tipo__        | Evento entrante (_Listen_).                                   |
| __Descripción__ | Evento que indica que un jugador ha cambiado su nombre.       |
| __Respuesta__   | `playerId` (_string_): ID de jugador cuyo nombre ha cambiado. |
|                 | `playerName` (_string_): Nuevo nombre del jugador.            |

Este evento alerta cuando un jugador ha cambiado su nombre con el evento [`change-name`](#cambiar-nombre-del-jugador-change-name),
con el fin de que todos los clientes de juego puedan manejar este cambio en tiempo real. En el contenido
de la respuesta se adjunta el identificador y el nuevo nombre para evitar llamadas innecesarias al evento
`online-players`. Este evento no lo recibe el jugador que se cambia el nombre.

Ejemplo de respuesta:
```jsonc
{
  "event": "player-name-changed",
  "msg": "Player 'Player_Two' has a new name!",
  "data": {
    "playerId": "c3e5aca7-f1c0-40ed-8b5c-aac3f58d137f",
    "playerName": "Player_Two"
  }
}
```

## Obtener datos del jugador (player-data)

| Resumen         |                                                                                   |
|-----------------|-----------------------------------------------------------------------------------|
| __Evento__      | `player-data`                                                                     |
| __Tipo__        | Evento saliente (_Trigger_).                                                      |
| __Descripción__ | Evento para solicitar los datos del jugador actual.                               |
| __Parámetros__  | _Ninguno_.                                                                        |
| __Respuesta__   | `id` (_string_): ID de jugador.                                                   |
|                 | `name` (_string_): Nombre de jugador.                                             |
|                 | `game` (_object_): Datos del cliente de juego.                                    |
|                 | `game.id` (_string_): ID del juego conectado.                                     |
|                 | `game.name` (_string_): Nombre del juego.                                         |
|                 | `game.team` (_string_): Nombre del equipo desarrollador.                          |
|                 | `status` (_string_): Estado actual del jugador (`AVAILABLE`, `BUSY`, `IN_MATCH`). |

Con este evento es posible recuperar la información actual del jugador, en caso que se haya perdido y deba
recuperarse. El evento como respuesta retornará el ID del jugador, su nombre y el estado actual.

Los estados posibles para el jugador son los siguientes:
- `AVAILABLE`: El jugador se encuentra disponible para recibir solicitudes de partida.
- `BUSY`: El jugador esta ocupado con una solicitud de partida, por lo que no puede recibir otras.
- `IN_MATCH`: El jugador se encuentra actualmente en una partida, por lo que no puede recibir solicitudes.

Ejemplo de solicitud:
```jsonc
// Evento enviado por el jugador
{
  "event": "player-data"
}

// Respuesta entregada por el servidor
{
  "event": "player-data",
  "status": "OK",
  "msg": "Player data obtained.",
  "data": {
    "id": "c3e5aca7-f1c0-40ed-8b5c-aac3f58d137f",
    "name": "Player_Two",
    "game": {
      "id": "B",
      "name": "Silent Strikers",
      "team": "Phantom Bytes"
    },
    "status": "AVAILABLE"
  }
}
```

## Cambiar nombre del jugador (change-name)

| Resumen         |                                                              |
|-----------------|--------------------------------------------------------------|
| __Evento__      | `change-name`                                                |
| __Tipo__        | Evento saliente (_Trigger_).                                 |
| __Descripción__ | Evento para cambiar el nombre representativo del jugador.    |
| __Parámetros__  | `name` (_string_): Nombre nuevo del jugador.                 |
| __Respuesta__   | `name` (_string_): Nuevo nombre establecido para el jugador. |

Al conectarse, el servidor establece un nombre por defecto (a menos que lo haya configurado con la
propiedad `playerName` al momento de conectarse). Con este evento, es posible cambiar el nombre del jugador
por el que estime conveniente, el cual se envía por parámetro a la solicitud. Si la solicitud esta correcta,
se retornará el nuevo nombre establecido para el jugador. Este evento gatilla el evento `player-name-changed`
con el fin que el resto de jugadores se entere del cambio.

Ejemplo de solicitud:
```jsonc
// Evento enviado por el jugador
{
  "event": "change-name",
  "data": {
    "name": "Player_Two"
  }
}

// Respuesta entregada por el servidor
{
  "event": "change-name",
  "status": "OK",
  "msg": "Name changed.",
  "data": {
    "name": "Player_Two"
  }
}
```

En el caso que el nombre no se envíe o no tenga el formato correcto, el servidor responderá con un error:

Ejemplo de solicitud errónea:
```jsonc
// Evento enviado por el jugador
{
  "event": "change-name",
  "data": {
    "name": "        "
  }
}

// Respuesta entregada por el servidor
{
  "event": "change-name",
  "status": "ERROR",
  "msg": "New name is not setted or is undefined.",
  "data": {
    "name": "        "
  }
}
```