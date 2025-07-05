# UCN WebSocket Game Server
This is a WebSocket Server to use in the implementation of the Cross-Game Multiplayer Gameplay for "Advanced Programming Integrator Project" Course.

## Description
This server is written in [Typescript](https://www.typescriptlang.org/) using 
[NestJS Framework](https://nestjs.com/). Support Websocket native connection (using 
[ws library](https://github.com/websockets/ws)).

## How to Connect?
To use the game match server services, you can find the instructions in 
[This Guide (En español)](./docs/game-match-server/server-connect-and-use-es.md).

To use the table score functions, you can follow the instructions in 
[This Guide (En español)](./docs/game-data-server/score-table-connect-instructions-es.md).

## Requirements

In order to execute this service (__NOT FOR CONNECT IT__), you need to install:

- Node.js 20 or greater.
- (_optional_) PostgreSQL 17 or greater.

## Steps for running the app locally
First, clone this repository to your computer or server and install the dependencies for the node app.
```bash
$ git clone https://github.com/BastianRuiz95/ucn-websocket-game-server.git
$ npm install
```

Next, configure the environment vars. Copy the example file [example.env](example.env), rename it 
to ".env" and set the vars. The required vars to execute the services are:

- __DATABASE_TYPE__: Set the database engine to use for store auth data. You can use a local or remote database. 
                     The service is developed to use one of two engines: "postgres" or "sqlite".[^1]
- __DATABASE_URL__: The string connection to the database. This can vary depending of the db engine:
  - `sqlite`: path to the file (i.e.: `/database/db.sqlite`).
  - `postgres`: this string format: `postgres://<DB_USER_NAME>:<DB_USER_PASS>@<DB_HOST>:<DB_PORT>/<DB_NAME>`
- __JWT_SECRET__: String to encrypt and validate JWT tokens for authentication. Can be a random string.

You can set the other vars if you want. Otherwise, the service will use default inner values:
- __PORT__: Number used for the game data server (HTTP). By default is `80`.
- __WS_PORT__: Number used for the game match server (WebSocket). By default is `8080`.
- __ENVIRONMENT__: Number used for the service for deployment purposes. By default is `development`.

[^1]: Sqlite is a library that implements a small database engine in a file to store data, avoiding install 
greater database engines. For more information, you can go to the  [official site (sqlite.org)](https://sqlite.org/).

Finally, you can execute the service using npm run start:dev command.
```bash
$ npm run start:dev
```

## Using Docker
If you have Docker installed, you can execute this app without installing anything. With Docker Compose, 
you need to execute a single command, and Docker sets both service and postgreSQL database. You only need 
to set the environment vars described in the last point, with 3 more vars related to the postgreSQL container:
- __DATABASE_USER__: Name of the database user. It's the same as <DB_USER_NAME> in the connection string.
- __DATABASE_PASS__: Password of the database user. It's the same as <DB_USER_PASS> in the connection string.
- __DATABASE_NAME__: Database name to use in the app. It's the same as <DB_NAME> in the connection string.

Next, you need to execute this command, and the service will up in a fewer seconds:
```bash
$ docker compose up -d
```

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by 
the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## License

Nest is [MIT licensed](LICENSE).
