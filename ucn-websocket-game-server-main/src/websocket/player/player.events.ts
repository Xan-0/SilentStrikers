import { Injectable } from '@nestjs/common';

import {
  EConnectionListenEvent,
  EPlayerListenEvent,
  EPlayerTriggerEvent,
} from '../common/events';
import { Player } from '../common/entities';
import { EPlayerStatus } from '../common/enums';

import { GameResponse } from '../config/game-response.type';
import { GameException } from '../config/game.exception';

import { GameService } from '../game/game.service';
import { PlayerListService } from '../player-list/player-list.service';

import { ChangeUserNameDto, LoginDto } from './dtos';

@Injectable()
export class PlayerEvents {
  constructor(
    private readonly gameService: GameService,
    private readonly playerListService: PlayerListService,
  ) {}

  connected(player: Player, gameId: string) {
    if (!player.game) {
      player.sendEvent(
        EConnectionListenEvent.ConnectedToServer,
        'GameId do not exists or is invalid.',
        { gameId: gameId ?? null },
        'ERROR',
      );
      player.socketClient.close(4000);
      return;
    }

    this.playerListService.addPlayer(player);

    player.sendEvent(
      EConnectionListenEvent.ConnectedToServer,
      `Welcome! You are connected to the game server. Login first with '${EPlayerTriggerEvent.Login}' event`,
      player.getPlayerData(),
      'OK',
    );
  }

  disconnected(player: Player) {
    if (!player) return;

    this.playerListService.removePlayer(player);
    player.status = EPlayerStatus.Disconnected;
    this.playerListService.broadcast(
      EConnectionListenEvent.PlayerDisconnected,
      `Player '${player.name}' (${player.id}) has disconnected`,
      player.getPlayerData(),
    );
  }

  login(player: Player, data: LoginDto): GameResponse {
    if (!player || !player.status) {
      GameException.throwException(
        `You need to wait to the '${EConnectionListenEvent.ConnectedToServer}' event first.`,
      );
    }

    if (player.status !== EPlayerStatus.NoLogin) {
      GameException.throwException('You are already login in the server.');
    }

    const gameKey = data?.gameKey || null;
    if (this.gameService.checkGameKey(player.game.id, gameKey)) {
      player.status = EPlayerStatus.Available;

      this.playerListService.broadcast(
        EConnectionListenEvent.PlayerConnected,
        `Player '${player.name}' (${player.id}) has connected.`,
        player.getPlayerData(),
        player.id,
      );

      return {
        msg: 'Login Successfully.',
        data: player.getPlayerData(),
      };
    }
    GameException.throwException(
      'Invalid gameKey. Please check and try again.',
      null,
    );
  }

  changeUserName(player: Player, data: ChangeUserNameDto): GameResponse {
    this._checkNewName(data.name);

    player.name = data.name.trim();

    this.playerListService.broadcast(
      EPlayerListenEvent.PlayerNameChanged,
      `Player '${player.name}' has a new name!`,
      { playerId: player.id, playerName: player.name },
      player.id,
    );

    return {
      msg: 'Name changed',
      data: { name: player.name.trim() },
    };
  }

  getPlayerData(player: Player): GameResponse {
    return {
      msg: 'Player list obtained',
      data: player.getPlayerData(),
    };
  }

  private _checkNewName(name: string) {
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      GameException.throwException(`New name is not setted or is undefined.`, {
        name: name ?? typeof name,
      });
    }
  }
}
