import { WebSocket } from 'ws';
import { Injectable } from '@nestjs/common';

import { Player } from '../common/entities';
import { EPlayerStatus } from '../common/enums';

@Injectable()
export class PlayerListService {
  private readonly _playerList: Player[] = [];

  addPlayer(player: Player) {
    this._playerList.push(player);
  }

  removePlayer(player: Player) {
    this._playerList.splice(this._playerList.indexOf(player), 1);
  }

  getPlayers(): Player[] {
    return this._playerList.filter((p) => p.status !== EPlayerStatus.NoLogin);
  }

  getPlayerBySocket(socketClient: WebSocket): Player {
    return (
      this._playerList.find((p) => p.socketClient === socketClient) || null
    );
  }

  getPlayerById(playerId: string): Player {
    return this.getPlayers().find((p) => p.id === playerId) || null;
  }

  broadcast<T = object>(
    event: string,
    msg: string,
    data: T,
    omitPlayerId: string = null,
  ) {
    this.getPlayers().forEach((p) => {
      if (!omitPlayerId || omitPlayerId != p.id) p.sendEvent(event, msg, data);
    });
  }
}
