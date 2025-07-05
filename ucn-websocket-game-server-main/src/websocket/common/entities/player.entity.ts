import { WebSocket } from 'ws';
import { Exclude } from 'class-transformer';

import { Match } from './match.entity';
import { EPlayerStatus } from '../enums';
import { Game } from './game.entity';

type PlayerPresenter = Omit<
  Player,
  'socketClient' | 'getPlayerData' | 'sendEvent' | 'match' | 'game'
> & { game: Omit<Game, 'key'> };

export class Player {
  readonly id: string;
  name: string;
  game: Game;
  status: EPlayerStatus;
  match: Match;

  @Exclude()
  readonly socketClient: WebSocket;

  constructor(partial: Partial<Player>) {
    Object.assign(this, partial);
  }

  getPlayerData(): PlayerPresenter {
    let gameData: Omit<Game, 'key'> = null;
    if (this.game) {
      const { key, ...gameWithoutKey } = this.game;
      gameData = gameWithoutKey;
    }
    return {
      id: this.id,
      name: this.name,
      game: gameData,
      status: this.status,
    };
  }

  sendEvent<T = object>(event: string, msg: string, data: T, status?: string) {
    this.socketClient.send(JSON.stringify({ event, status, msg, data }));
  }
}
