import { WebSocket } from 'ws';

import { EPlayerStatus } from '../../common/enums';

const socketClient = { send: jest.fn() } as unknown as WebSocket;

const common = {
  status: EPlayerStatus.Available,
  socketClient,
};

export const PLAYER_ONE_MOCK_DATA = {
  ...common,
  id: 'player_one_id',
  name: 'Player one',
};

export const PLAYER_TWO_MOCK_DATA = {
  ...common,
  id: 'player_two_id',
  name: 'Player two',
};
