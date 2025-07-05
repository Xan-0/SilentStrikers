import { Injectable } from '@nestjs/common';

import { Player } from '../common/entities';

import {
  ConnectMatchUseCase,
  FinishGameUseCase,
  PingMatchUseCase,
  QuitMatchUseCase,
  SendDataUseCase,
  SendRematchRequestUseCase,
} from './usecases';
import { GameException } from '../config/game.exception';

@Injectable()
export class GameMatchService {
  constructor(
    private readonly quitMatchUseCase: QuitMatchUseCase,
    private readonly sendRematchRequestUseCase: SendRematchRequestUseCase,
    private readonly finishGameUseCase: FinishGameUseCase,
    private readonly sendDataUseCase: SendDataUseCase,
    private readonly pingMatchUseCase: PingMatchUseCase,
    private readonly connectMatchUseCase: ConnectMatchUseCase,
  ) {}

  connectMatch(player: Player) {
    this._checkPlayerStatus(player);
    return this.connectMatchUseCase.exec(player);
  }

  pingMatch(player: Player) {
    this._checkPlayerStatus(player);
    return this.pingMatchUseCase.exec(player);
  }

  sendData(player: Player, data: object) {
    this._checkPlayerStatus(player);
    const opponent = this._getOpponent(player);
    return this.sendDataUseCase.exec(player, data, opponent);
  }

  finishGame(player: Player) {
    this._checkPlayerStatus(player);
    const opponent = this._getOpponent(player);
    return this.finishGameUseCase.exec(player, opponent);
  }

  sendRematchRequest(player: Player) {
    this._checkPlayerStatus(player);
    const opponent = this._getOpponent(player);
    return this.sendRematchRequestUseCase.exec(player, opponent);
  }

  quitMatch(player: Player) {
    this._checkPlayerStatus(player);
    const opponent = this._getOpponent(player);
    return this.quitMatchUseCase.exec(player, opponent);
  }

  private _checkPlayerStatus(player: Player) {
    if (!player.match) {
      GameException.throwException(`You do not have an associated match.`, {
        playerStatus: player.status,
      });
    }
  }

  private _getOpponent(player: Player) {
    const { senderPlayer, destPlayer } = player.match;
    return player.id === senderPlayer.player.id
      ? destPlayer.player
      : senderPlayer.player;
  }
}
