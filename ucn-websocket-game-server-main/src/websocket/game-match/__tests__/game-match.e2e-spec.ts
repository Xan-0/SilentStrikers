/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */
import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { INestApplication } from '@nestjs/common';
import { RawData, WebSocket } from 'ws';

import { WebsocketModule } from 'src/websocket/websocket.module';
import { CustomWsAdapter } from 'src/websocket/config/custom-ws.adapter';

import {
  EPlayerTriggerEvent,
  EGameMatchTriggerEvent,
  EMatchmakingTriggerEvent,
  EConnectionListenEvent,
  EMatchmakingListenEvent,
  EGameMatchListenEvent,
} from 'src/websocket/common/events';
import { EPlayerStatus } from 'src/websocket/common/enums';

import { getEnvVars } from './game-match.e2e-mock';

describe('#GameMatchE2E', () => {
  const url = `ws://localhost:4044`;
  let app: INestApplication;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [WebsocketModule],
    })
      .overrideProvider(ConfigService)
      .useValue({
        get: jest.fn((key: string) => getEnvVars(key)),
      })
      .compile();

    app = module.createNestApplication();
    app.useWebSocketAdapter(new CustomWsAdapter(app, 4044));
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('should connect to the ws server and play a match', (done) => {
    let playerTwoId = '';

    let counterOne = 5;
    let counterTwo = 5;
    let rematch = true;
    const dataToSend = { target: 2, name: 1, discover: 3 };

    const clientOne = new WebSocket(`${url}?gameId=A`);
    const clientTwo = new WebSocket(`${url}?gameId=B`);

    clientOne.on('message', (message) => {
      const { event, status, msg, data } = parseMsg(message);

      checkError(event, status, msg);

      if (checkEvent(event, EConnectionListenEvent.ConnectedToServer)) {
        expect(data).toHaveProperty('status', EPlayerStatus.NoLogin);
        sendEvent(clientOne, EPlayerTriggerEvent.Login, {
          gameKey: 'SS',
        });
      }

      if (checkEvent(event, EPlayerTriggerEvent.Login)) {
        expect(data).toHaveProperty('status', EPlayerStatus.Available);
        sendEvent(clientTwo, EPlayerTriggerEvent.Login, {
          gameKey: 'TT',
        });
      }

      if (checkEvent(event, EConnectionListenEvent.PlayerConnected)) {
        playerTwoId = data.id;
        sendEvent(clientOne, EMatchmakingTriggerEvent.SendMatchRequest, {
          playerId: playerTwoId,
        });
      }

      if (checkEvent(event, EMatchmakingListenEvent.MatchRequestAccepted)) {
        sendEvent(clientOne, EGameMatchTriggerEvent.ConnectMatch, null);
      }

      if (checkEvent(event, EGameMatchListenEvent.PlayersReady)) {
        sendEvent(clientOne, EGameMatchTriggerEvent.PingMatch, null);
      }

      if (checkEvent(event, EGameMatchListenEvent.MatchStart)) {
        sendEvent(clientOne, EGameMatchTriggerEvent.SendData, {
          target: 2,
          name: 1,
          discover: 3,
        });
      }

      if (checkEvent(event, EGameMatchListenEvent.ReceiveData)) {
        expect(data).toEqual(dataToSend);
        if (counterOne > 0) {
          counterOne--;
          sendEvent(clientOne, EGameMatchTriggerEvent.SendData, dataToSend);
        } else {
          sendEvent(clientOne, EGameMatchTriggerEvent.FinishGame, null);
        }
      }

      if (checkEvent(event, EGameMatchListenEvent.RematchRequest)) {
        sendEvent(clientOne, EGameMatchTriggerEvent.SendRematchRequest, null);
      }

      if (checkEvent(event, EGameMatchListenEvent.CloseMatch)) {
        sendEvent(clientOne, EGameMatchTriggerEvent.QuitMatch, null);
        closeConnections();
      }
    });

    clientTwo.on('message', (message) => {
      const { event, status, msg, data } = parseMsg(message);

      checkError(event, status, msg);

      if (checkEvent(event, EConnectionListenEvent.ConnectedToServer)) {
        expect(data).toHaveProperty('status', EPlayerStatus.NoLogin);
      }

      if (checkEvent(event, EPlayerTriggerEvent.Login)) {
        expect(data).toHaveProperty('status', EPlayerStatus.Available);
      }

      if (checkEvent(event, EMatchmakingListenEvent.MatchRequestReceived)) {
        sendEvent(clientTwo, EMatchmakingTriggerEvent.AcceptMatch, null);
      }

      if (checkEvent(event, EMatchmakingTriggerEvent.AcceptMatch)) {
        sendEvent(clientTwo, EGameMatchTriggerEvent.ConnectMatch, null);
      }

      if (checkEvent(event, EGameMatchListenEvent.PlayersReady)) {
        sendEvent(clientTwo, EGameMatchTriggerEvent.PingMatch, null);
      }

      if (checkEvent(event, EGameMatchListenEvent.MatchStart)) {
        sendEvent(clientTwo, EGameMatchTriggerEvent.SendData, dataToSend);
      }

      if (checkEvent(event, EGameMatchListenEvent.ReceiveData)) {
        expect(data).toEqual(dataToSend);
        if (counterTwo > 0) {
          counterTwo--;
          sendEvent(clientTwo, EGameMatchTriggerEvent.SendData, dataToSend);
        }
      }

      if (checkEvent(event, EGameMatchListenEvent.GameEnded)) {
        if (rematch) {
          sendEvent(clientTwo, EGameMatchTriggerEvent.SendRematchRequest, null);
          rematch = false;
        } else {
          sendEvent(clientTwo, EGameMatchTriggerEvent.QuitMatch, null);
        }
      }
    });

    function checkError(event: string, status: string, msg: string) {
      if (status === 'ERROR') {
        closeConnections(new Error(`${event} - ${msg}`));
      }
    }

    function closeConnections(error?: any) {
      clientOne.close();
      clientTwo.close();
      done(error);
    }

    clientOne.on('error', done);
    clientTwo.on('error', done);
  });
});

function checkEvent(event: string, enumValue: string | number): boolean {
  return event === enumValue || event === enumValue.toString();
}

function sendEvent(client: WebSocket, event: string, data: any) {
  client.send(JSON.stringify({ event, data }));
}

function parseMsg(message: RawData): {
  event: string;
  status: string;
  msg: string;
  data: any;
} {
  // eslint-disable-next-line @typescript-eslint/no-base-to-string
  const { event, status, msg, data } = JSON.parse(message.toString());
  return { event, status, msg, data };
}
