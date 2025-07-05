# Instrucciones de uso de la tabla de puntajes

## Tabla de contenidos
- [Descripción de conexión con API REST](#descripción-de-conexión-con-api-rest)
- [Forma de conectarse](#forma-de-conectarse)
- [Estado de las rutas](#estado-de-las-rutas)
- [Autenticación y seguridad](#autenticación-y-seguridad)
- [Errores](#errores)
  - [Errores de solicitud](#errores-de-solicitud)
  - [Errores de servidor](#errores-de-servidor)
- [Listado y detalle de rutas](#listado-y-detalle-de-rutas)
  - [Obtención de puntajes](#obtención-de-puntajes)
  - [Agregar un nuevo puntaje](#agregar-un-nuevo-puntaje)
  - [Eliminar todos los puntajes](#eliminar-todos-los-puntajes)

## Descripción de conexión con API REST

El servicio de conexión a la tabla de puntajes se encuentra implementado por medio de una API
(Application Programming Interface). Esta es la forma más común para que una aplicación o
servicio pueda entregar funciones a otras aplicaciones que lo necesiten (usualmente llamados
clientes).

## Forma de conectarse

Para conectarse a los servicios de la API, se deben mandar solicitudes al servidor con un verbo 
HTTP, que indican las acciones que el servidor debe realizar con la información entregada, más 
la ruta con los recursos que se quieran manejar. El resultado de la acción hará que el servidor
responda de cierta manera, entregando la información solicitada, confirmando la acción o 
respondiendo con un error si algo pasó (como entrega errónea de los datos o fallos internos).

En la siguiente tabla se pueden visualizar un resumen de lo explicado:

| Verbo HTTP | Descripción | Acción resultante |
| --- | --- | --- |
| **GET** | Obtencion de Datos | Listado con la información solicitada |
| **POST** | Creación de un recurso | Datos del recurso creado |
| **PUT** | Actualización de un recurso | Datos del recurso actualizado |
| **DELETE** | Eliminación de datos | Datos del recurso eliminado |

En la siguiente imagen se aprecia un diagrama de conectividad con un servidor:

![http rest conectivity](../img/rest-example.png)

En este caso, estamos haciendo una solicitud al servidor con el verbo HTTP GET a la ruta
/scores. En palabras humanas, le estamos diciendo al servidor que queremos la información de
los puntajes que tenga almacenada. El servidor, como respuesta, enviará el listado de puntajes
que tiene almacenados en un formato estandar.

Algunos verbos (Como POST y PUT) pueden requerir datos adicionales, como los datos para crear o
actualizar un recurso. En estos casos, las solicitudes pueden llevar un cuerpo de mensaje
(llamado body) donde se adjuntan cada uno de los datos necesarios.

Para utilizar la conectividad HTTP en sus clientes de juego, pueden utilizar como ejemplo estos
recursos:
- [Solicitudes HTTP con Godot (En Inglés)](https://docs.godotengine.org/en/stable/tutorials/networking/http_request_class.html)
- [Módulo UnityWebRequest para Unity 2022.3 (En Inglés)](https://docs.unity3d.com/Manual/UnityWebRequest.html)

## Estado de las rutas
El servicio actualmente provee 3 rutas relacionadas con el manejo de la tabla de puntajes, los
cuales se resumen en la siguiente tabla:

| Verbo HTTP | RUTA | Acción resultante |
| --- | --- | --- |
| **GET** | /scores/ | Obtiene los puntajes almacenados del juego que solicita la acción |
| **POST** | /scores/ | Agrega un nuevo puntaje a la tabla del juego que solicita la acción |
| **DELETE** | /scores/ | Elimina todos los puntajes de la tabla del juego que solicita la acción |

## Autenticación y seguridad
Para acceder a las rutas provistas arriba, se requiere de un token de seguridad, con el fin de
que solo los clientes autorizados puedan efectuar cambios en cada tabla de puntajes. Este token
le será suministrado mediante otra vía.

Para usar este token, deben utilizar la sección de cabeceras (Headers) que tienen las
solicitudes HTTP. En específico, deben usar el header `Authorization: Bearer {TOKEN}`. Si el
servidor reconoce el token como válido, se ejecutará la acción solicitada. En el caso contrario,
el servidor respondera con un error de tipo 401, que es un codigo de estado HTTP que indica que 
el cliente no está autorizado para realizar la acción por la invalidez del token.

```jsonc
{
  "message": "Unauthorized",
  "statusCode": 401
}
```

## Errores
En el caso de que las cosas fallen, el servidor siempre retornará un código de estado y un mensaje
indicando las cosas que sucedieron. Estos códigos de estado HTTP son los 4XX y 5XX, que indican
errores con las solicitudes y con el servidor respectivamente.

### Errores de solicitud
Estos errores se categorizan como tipo 4XX, los cuales se relacionan con problemas en la
construcción de la solicitud y los datos entregados. En estos casos, los clientes deben revisar
bien las condiciones solicitadas por la ruta para su funcionamiento, como los datos adjuntos (body),
cabeceras (headers) y tokens de autorización.

El listado de errores más comunes se detalla en la siguiente tabla:

| Código | Nombre | Descripción |
| --- | --- | --- |
| **400** | Bad Request | La sintaxis de la petición no es correcta y posee errores. |
| **401** | Unauthorized | La petición realizada necesita de un código de autorización. |
| **403** | Forbidden | No tiene permitido el acceso a la petición, aun con un código de autorización correcto. |
| **404** | Not Found | El recurso solicitado no existe o no está disponible. |
| **429** | Too Many Request | Se han realizado muchas solicitudes al servidor en poco tiempo. |

### Errores de servidor
Este tipo de errores se categorizan como tipo 5XX. Estos errores no están relacionados con las
solicitud realizada, sino más bien con el funcionamiento del servidor. En estos casos, es necesario
revisar el servicio en busqueda de problemas. Los clientes pueden acelerar el proceso enviando los
detalles del error para reproducirlo, encontrar la falla y poder repararla lo antes posible.

El listado de errores más comunes se detalla en la siguiente tabla:

| Código | Nombre | Descripción |
| --- | --- | --- |
| **500** | Internal Server Error | Se produjo un error no listado en el servidor. |
| **501** | Not Implemented | La función a la que desea acceder aún no está implementada. |
| **502** | Bad Gateway | Existe un error de comunicación dentro del servidor. |
| **503** | Service Unavailable | El servidor se encuentra saturado o está en mantenimiento. |

## Listado y detalle de rutas
A continuación, se detallarán todos las rutas operativas en este momento, con sus detalles de
construcción, datos solicitados, respuestas posibles y ejemplos.

### Obtención de puntajes
- **Endpoint (RUTA)**: `GET` /scores
- **Descripción**: Obtiene todos los puntajes asociados a su juego que se encuentran
almacenados en el servidor.
- **Cabeceras (Headers)**:
  - `Authorization: Bearer {TOKEN}`: se debe reemplazar `{TOKEN}` por el token suministrado.

#### Respuestas posibles
`200`: Se obtiene el listado de datos correctamente.
```jsonc
{
  "message": string, // Mensaje indicando el éxito de la operación.
  "data": [ // Arreglo de puntajes. Cada elemento del array se compone de lo siguiente:
    {
      "id": number, // Identificador del puntaje. Usado para indexar
      "playerName": string, // Nombre del jugador dueño del puntaje
      "score": number // Puntaje realizado por el jugador
    }
  ]
}
```

`401`: La autenticación del token falló (ver [Authenticación y seguridad](#autenticación-y-seguridad))

`500`: Error Interno del servidor (ver [Errores](#errores)).
```jsonc
{
  "statusCode": number, // Código de estado de la solicitud (401, 500 o similar)
  "message": string // Mensaje con el nombre del error
}
```

#### Ejemplo de solicitud
```http
GET https://game.example.com/scores
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiaWF0IjoxNTE2MjM5MDIyfQ.L8i6g3PfcHlioHCCPURC9pmXT7gdJpx3kOoyAfNUwCc
```

#### Ejemplo de respuesta exitosa
```jsonc
{
  "message": "Score List Received",
  "data": [
    {
      "id": 2,
      "playerName": "JohnDoe",
      "score": 123456
    },
    {
      "id": 3,
      "playerName": "MikeTyson",
      "score": 98765
    },
    {
      "id": 4,
      "playerName": "Luigi",
      "score": 11234
    }
  ]
}
```

### Agregar un nuevo puntaje
- **Endpoint (RUTA)**: `POST` /scores
- **Descripción**: Con los datos adjuntos, genera un nuevo registro de puntaje en la base de
datos de puntajes.
- **Cabeceras (Headers)**:
  - `Authorization: Bearer {TOKEN}`: se debe reemplazar `{TOKEN}` por el token suministrado.
  - `Content-Type: application/json`: Define la estructura de envío de los datos.

#### Datos extra (body)
Para generar el nuevo registro de puntaje, se deben enviar los siguientes datos:
```jsonc
{
  "playerName": string,
  "score": number
}
```
- `playerName`: Nombre del jugador que realizó el puntaje.
  - Este parámetro debe ser de tipo string (texto).
  - El nombre no puede superar los 10 carácteres.
  - El nombre solo puede estar compuesto de carácteres alfanuméricos.
    - Números del 0 al 9 y letras de la A a la Z (ignorando tildes y espacios).
- `score`: Puntaje obtenido por el jugador.
  - Este parámetro debe ser de tipo number o integer (numérico).
  - El valor mínimo de este número es 1, el máximo es 999.999.999.

#### Respuestas posibles
`200`: El puntaje se ingresa correctamente a la base de datos.
```jsonc
{
  "message": string, // Mensaje indicando el éxito de la operación.
  "data": { // Objeto con la información del puntaje. Los datos son:
    "id": number, // Identificador del puntaje. Usado para indexar
    "playerName": string, // Nombre del jugador dueño del puntaje
    "score": number // Puntaje realizado por el jugador
  }
}
```

`400`: Alguno de los requisitos de los datos no se cumplieron, por lo que no pasaron la
validación. Revise los datos nuevamente, corrija los errores y vuelva a enviar la
solicitud.

```jsonc
{
  "message": [ // Arreglo de strings indicando los errores posibles.
    "El nombre del jugador no debe superar los 10 caracteres.",
    "El nombre del jugador solo puede tener carácteres alfanuméricos (0-9 y A-Z)",
    "El puntaje no puede superar el valor de 999.999.999.",
    "El puntaje debe ser mayor o igual a 1.",
    "El puntaje debe tener un valor numérico entero."
  ],
  "error": "Bad Request", // Nombre del error
  "statusCode": 400 // Codigo de estado de la solicitud
}
```

`401`: La autenticación del token falló (ver [Authenticación y seguridad](#autenticación-y-seguridad))

`500`: Error Interno del servidor (ver [Errores](#errores)).
```jsonc
{
  "statusCode": number, // Código de estado de la solicitud (401, 500 o similar)
  "message": string // Mensaje con el nombre del error
}
```

#### Ejemplo de solicitud
```http
POST https://game.example.com/scores
Content-Type: application/json
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiaWF0IjoxNTE2MjM5MDIyfQ.L8i6g3PfcHlioHCCPURC9pmXT7gdJpx3kOoyAfNUwCc

{ "playerName": "JohnDoe", "score": 112324 }
```

#### Ejemplo de respuesta exitosa
```jsonc
{
  "message": "Score Submitted",
  "data": {
    "playerName": "JohnDoe",
    "score": 112324,
    "id": 1
  }
}
```

### Eliminar todos los puntajes
- **Endpoint (RUTA)**: `DELETE` /scores
- **Descripción**: Elimina por completo la tabla de puntajes asociada a su cliente de juego. Se
puede utilizar para reiniciar los puntajes cada cierto tiempo.
- **Cabeceras (Headers)**:
  - `Authorization: Bearer {TOKEN}`: se debe reemplazar `{TOKEN}` por el token suministrado.

#### Respuestas posibles
`200`: Se indica que la lista de puntajes ha sido limpiada.
```jsonc
{
  "message": string, // Mensaje indicando el éxito de la operación.
}
```

`401`: La autenticación del token falló (ver [Authenticación y seguridad](#autenticación-y-seguridad))

`500`: Error Interno del servidor (ver [Errores](#errores)).
```jsonc
{
  "statusCode": number, // Código de estado de la solicitud (401, 500 o similar)
  "message": string // Mensaje con el nombre del error
}
```

#### Ejemplo de solicitud
```http
DELETE https://game.example.com/scores
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwiaWF0IjoxNTE2MjM5MDIyfQ.L8i6g3PfcHlioHCCPURC9pmXT7gdJpx3kOoyAfNUwCc
```

#### Ejemplo de respuesta exitosa
```jsonc
{
  "message": "Deleted All Scores Successfully",
}
```