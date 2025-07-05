import { Injectable } from '@nestjs/common';

import { Player } from '../common/entities';
import { GameResponse } from '../config/game-response.type';

import { LobbyService } from './lobby.service';
import { SendPrivateMessageDto, SendPublicMessageDto } from './dtos';

@Injectable()
export class LobbyEvents {
  constructor(private readonly lobbyService: LobbyService) {}

  getConnectedPlayers(): GameResponse {
    return this.lobbyService.getOnlinePlayers();
  }

  sendPrivateMessage(
    player: Player,
    body: SendPrivateMessageDto,
  ): GameResponse {
    return this.lobbyService.sendPrivateMessage(
      player,
      body.playerId,
      body.message,
    );
  }

  sendPublicMessage(player: Player, body: SendPublicMessageDto): GameResponse {
    return this.lobbyService.sendPublicMessage(player, body.message);
  }
}
