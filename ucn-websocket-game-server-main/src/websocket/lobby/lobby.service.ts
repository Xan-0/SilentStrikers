import { Injectable } from '@nestjs/common';

import { Player } from '../common/entities';
import { EPlayerStatus } from '../common/enums';
import { ELobbyListenEvent } from '../common/events';

import { GameException } from '../config/game.exception';
import { PlayerListService } from '../player-list/player-list.service';

@Injectable()
export class LobbyService {
  constructor(private readonly playerListService: PlayerListService) {}

  getOnlinePlayers() {
    const playerList = this.playerListService
      .getPlayers()
      .map((p) => p.getPlayerData());
    return {
      msg: 'Player list obtained.',
      data: playerList,
    };
  }

  sendPrivateMessage(
    senderPlayer: Player,
    playerId: string,
    playerMsg: string,
  ) {
    const playerToSendMsg = this.playerListService.getPlayerById(playerId);
    if (!playerToSendMsg) {
      GameException.throwException(`Player with ID '${playerId}' not exists.`, {
        playerId: playerId,
      });
    }

    this._checkMessage(playerMsg);

    playerToSendMsg.sendEvent(
      ELobbyListenEvent.PrivateMessageReceived,
      `Player '${senderPlayer.name}' have sent you a private message.`,
      {
        playerId: senderPlayer.id,
        playerName: senderPlayer.name,
        playerMsg: playerMsg.trim(),
      },
    );

    return {
      msg: `Message sent to '${playerToSendMsg.name}'`,
      data: {
        playerId: playerToSendMsg.id,
        message: playerMsg.trim(),
      },
    };
  }

  sendPublicMessage(senderPlayer: Player, playerMsg: string) {
    this._checkMessage(playerMsg);

    this.playerListService.broadcast(
      ELobbyListenEvent.PublicMessageReceived,
      `Player '${senderPlayer.name}' have sent a message.`,
      {
        playerId: senderPlayer.id,
        playerName: senderPlayer.name,
        playerMsg: playerMsg.trim(),
      },
      senderPlayer.id,
    );

    return {
      msg: 'Message sent to all players',
      data: { message: playerMsg },
    };
  }

  updatePlayerStatus(player: Player, status: EPlayerStatus) {
    player.status = status;
    this.playerListService.broadcast(
      ELobbyListenEvent.PlayerStatusChanged,
      `Player '${player.name}' change status to '${status}'`,
      {
        playerId: player.id,
        playerStatus: player.status,
      },
      player.id,
    );
  }

  private _checkMessage(message: string) {
    if (!message || message.trim().length === 0) {
      GameException.throwException(`You cannot send an empty message.`, {
        message: message ?? typeof message,
      });
    }
  }
}
