import { WebSocket } from 'ws';
import { Injectable } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';

import { Game, Player } from '../common/entities';
import { EPlayerStatus } from '../common/enums';

@Injectable()
export class PlayerService {
  createPlayer(
    socketClient: WebSocket,
    name: string,
    game: Game = null,
  ): Player {
    return new Player({
      id: uuidv4(),
      socketClient,
      name,
      game,
      status: EPlayerStatus.NoLogin,
    });
  }
}
