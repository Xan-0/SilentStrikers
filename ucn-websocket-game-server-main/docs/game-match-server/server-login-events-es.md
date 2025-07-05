# Eventos de conexión y desconexión.

> Si necesitas volver al documento anterior, haz clic [aquí](./server-connect-and-use-es.md).

Los eventos de conexión y desconexión son gatillados por el servidor al momento que algun jugador se conecta
al endpoint de WebSocket establecido. Estas acciones estan definidas principalmente para gestionar de mejor
forma el listado de usuarios que se mostrará en su juego, y así no tenga la necesidad de ejecutar el evento
`get-connected-players` cada cierto tiempo.

Los tres tipos de eventos relacionados a la conexión y desconexión son de escucha (Eventos entrantes), por
lo que su cliente de juego debe realizar alguna acción al momento que los reciba.

Estos eventos son enviados por el servidor al momento que este u otro usuario realizan alguna acción. Su
cliente de juego debe escuchar los mensajes que el servidor puede enviar, interpretarlos, y realizar las
acciones que sean necesarias para su correcto funcionamiento.

- [Resumen de eventos](#resumen-de-eventos)
- [Conectado (connected-to-server)](#conectado-connected-to-server)
- [Jugador conectado (player-connected)](#jugador-conectado-player-connected)
- [Jugador desconectado (player-disconnected)](#jugador-desconectado-player-disconnected)
- [Iniciar Sesion (login)](#iniciar-sesión-login)

## Resumen de eventos

| Evento                | Tipo     | Descripción                                |
|-----------------------|----------|--------------------------------------------|
| `connected-to-server` | Entrante | Indica que te has conectado al servidor.   |
| `player-connected`    | Entrante | Indica que un jugador se ha conectado.     |
| `player-disconnected` | Entrante | Indica que un jugador se ha desconectado.  |
| `login`               | Saliente | Se usa para iniciar sesión en el servidor. |

## Conectado (connected-to-server)

| Resumen         |                                                                                         |
|-----------------|-----------------------------------------------------------------------------------------|
| __Evento__      | `connected-to-server`                                                                   |
| __Tipo__        | Evento entrante (_Listen_).                                                             |
| __Descripción__ | Mensaje recibido para indicar que el cliente se ha conectado al servidor correctamente. |
| __Respuesta__   | `id` (_string_): ID de jugador que se te ha asignado al conectarte.                     |
|                 | `name` (_string_): Nombre de jugador.                                                   |
|                 | `game` (_object_): Datos del cliente de juego.                                          |
|                 | `game.id` (_string_): ID del juego conectado.                                           |
|                 | `game.name` (_string_): Nombre del juego.                                               |
|                 | `game.team` (_string_): Nombre del equipo desarrollador.                                |
|                 | `status` (_string_): Estado actual del jugador (`NO_LOGIN`).                            |

Este es un evento gatillado al momento de conectarse al servidor con el fin de saber que la operación se
realizó correctamente. En el mensaje viene incluido el identificador y el nombre asignado al cliente con el fin 
de utilizarlo a lo largo de la conexión. Al conectarse, se asocia al jugador el estado `NO_LOGIN`, ya que se
requiere iniciar sesión para aparecer en el listado de jugadores conectados con el evento `login`.

Ejemplo de respuesta:
```jsonc
{
  "event": "connected-to-server",
  "msg": "Welcome! You are connected to the game server",
  "data": {
    "id": "0f2cc688-dcf3-4952-b8f8-c52f75f316d4",
    "name": "Player_Name",
    "game": {
      "id": "A",
      "name": "Contaminación Mortal",
      "team": "404 Studios"
    },
    "status": "NO_LOGIN"
  }
}
```

En el caso que la conexión no haya salido como se esperaba, se retornará un mensaje de error con la posterior
desconexión del cliente. El error puede deberse a que no se ha proporcionado el identificador del juego en la
ruta de conexión o es inválido (no existe).

Ejemplo de respuesta incorrecta:
```jsonc
{
  "event": "connected-to-server",
  "status": "ERROR",
  "msg": "GameId do not exists or is invalid.",
  "data": {
    "gameId": null
  }
}
```

## Jugador Conectado (player-connected)

| Resumen         |                                                                                   |
|-----------------|-----------------------------------------------------------------------------------|
| __Evento__      | `player-connected`                                                                |
| __Tipo__        | Evento entrante (_Listen_).                                                       |
| __Descripción__ | Mensaje recibido para indicar que un jugador se ha conectado al servidor.         |
| __Respuesta__   | `id` (_string_): ID de jugador.                                                   |
|                 | `name` (_string_): Nombre de jugador.                                             |
|                 | `game` (_object_): Datos del cliente de juego.                                    |
|                 | `game.id` (_string_): ID del juego conectado.                                     |
|                 | `game.name` (_string_): Nombre del juego.                                         |
|                 | `game.team` (_string_): Nombre del equipo desarrollador.                          |
|                 | `status` (_string_): Estado actual del jugador (`AVAILABLE`, `BUSY`, `IN_MATCH`). |

Este evento se gatilla cuando otro jugador se ha conectado al servidor y ha iniciado sesión correctamente.
El mensaje recibido contiene tanto el identificador y el nombre del jugador. Puede usarse para actualizar
el listado de jugadores de su cliente de juego, agregando al jugador en cuestión. De esta forma, no es
necesario llamar al evento `online-players` para actualizar el listado cuando se produce este evento.

Ejemplo de respuesta:
```jsonc
{
  "event": "player-connected",
  "msg": "Player 'Player_Two' (5db4f2a5-5982-4f85-a4ea-56f3ad6eafd0) has connected",
  "data": {
    "id": "5db4f2a5-5982-4f85-a4ea-56f3ad6eafd0",
    "name": "Player_Two",
    "game": {
      "id": "A",
      "name": "Contaminación Mortal",
      "team": "404 Studios"
    },
    "status": "AVAILABLE"
  }
}
```

## Jugador Desconectado (player-disconnected)

| Resumen         |                                                                               |
|-----------------|-------------------------------------------------------------------------------|
| __Evento__      | `player-disconnected`                                                         |
| __Tipo__        | Evento entrante (_Listen_).                                                   |
| __Descripción__ | Mensaje recibido para indicar que un jugador se ha desconectado del servidor. |
| __Respuesta__   | `id` (_string_): ID de jugador.                                               |
|                 | `name` (_string_): Nombre de jugador.                                         |
|                 | `game` (_object_): Datos del cliente de juego.                                |
|                 | `game.id` (_string_): ID del juego.                                           |
|                 | `game.name` (_string_): Nombre del juego.                                     |
|                 | `game.team` (_string_): Nombre del equipo desarrollador.                      |
|                 | `status` (_string_): Estado actual del jugador (`DISCONNECTED`).              |

De forma contraria al evento anterior, `player-disconnected` es un evento gatillado cuando un jugador se
desconecta del servidor, ya sea de forma automática, manual o forzosa. Se puede utilizar de igual forma para
actualizar el listado de jugadores conectados, eliminando al jugador en cuestión.

Ejemplo de respuesta:
```jsonc
{
  "event": "player-disconnected",
  "msg": "Player 'Player_Two' (5db4f2a5-5982-4f85-a4ea-56f3ad6eafd0) has disconnected",
  "data": {
    "id": "5db4f2a5-5982-4f85-a4ea-56f3ad6eafd0",
    "name": "Player_Two",
    "game": {
      "id": "A",
      "name": "Contaminación Mortal",
      "team": "404 Studios"
    },
    "status": "DISCONNECTED"
  }
}
```

## Iniciar Sesión (login)

| Resumen         |                                                                                   |
|-----------------|-----------------------------------------------------------------------------------|
| __Evento__      | `login`                                                                           |
| __Tipo__        | Evento saliente (_Trigger_).                                                      |
| __Descripción__ | Evento para iniciar sesión en el servidor.                                        |
| __Parámetros__  | `gameKey` (_string_): Clave asignada al cliente de juego.                         |
| __Respuesta__   | ``id` (_string_): ID de jugador.                                                   |
|                 | `name` (_string_): Nombre de jugador.                                             |
|                 | `game` (_object_): Datos del cliente de juego.                                    |
|                 | `game.id` (_string_): ID del juego conectado.                                     |
|                 | `game.name` (_string_): Nombre del juego.                                         |
|                 | `game.team` (_string_): Nombre del equipo desarrollador.                          |
|                 | `status` (_string_): Estado actual del jugador (`AVAILABLE`, `BUSY`, `IN_MATCH`). |`

Este evento le permite iniciar sesión en el servidor. Todas los eventos definidos (excepto este) requieren
que el jugador haya iniciado sesión, con el fin de reconocer el juego donde se estan conectando. Para esto,
es necesario enviar la clave asignada a su equipo en el mensaje. Si la clave es válida, se le notificará al
resto de jugadores que se ha conectado (con el evento `player-connected`), y asi podrá ejecutar todas las
acciones posibles dentro del servidor. En caso que la clave fuera incorrecta, recibirá un mensaje de error.

Ejemplo de solicitud correcta:
```jsonc
// Evento enviado por el jugador
{
  "event": "login",
  "data": {
    "gameKey": "ABCD1234"
  }
}

// Respuesta entregada por el servidor
{
  "event": "login",
  "status": "OK",
  "msg": "Login Successfully.",
  "data": {
    "id": "5db4f2a5-5982-4f85-a4ea-56f3ad6eafd0",
    "name": "Player_Two",
    "game": {
      "id": "A",
      "name": "Contaminación Mortal",
      "team": "404 Studios"
    },
    "status": "AVAILABLE"
  }
}
```

Ejemplo de solicitud errónea:
```jsonc
// Evento enviado por el jugador
{
  "event": "login",
  "data": {
    "gameKey": "wrong_key"
  }
}

// Respuesta entregada por el servidor
{
  "event": "login",
  "status": "ERROR",
  "msg": "Invalid gameKey. Please check and try again.",
  "data": null
}
```
