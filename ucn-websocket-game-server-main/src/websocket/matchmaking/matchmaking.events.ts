import { Injectable } from '@nestjs/common';

import { Player } from '../common/entities';
import { GameResponse } from '../config/game-response.type';

import { MatchmakingService } from './matchmaking.service';
import { SendMatchRequestDto } from './dtos';

@Injectable()
export class MatchmakingEvents {
  constructor(private readonly matchmakingService: MatchmakingService) {}

  sendMatchRequest(player: Player, data: SendMatchRequestDto): GameResponse {
    return this.matchmakingService.sendMatchRequest(player, data.playerId);
  }

  cancelMatchRequest(player: Player): GameResponse {
    return this.matchmakingService.cancelMatchRequest(player);
  }

  acceptMatchRequest(player: Player): GameResponse {
    return this.matchmakingService.acceptMatchRequest(player);
  }

  rejectMatchRequest(player: Player): GameResponse {
    return this.matchmakingService.rejectMatchRequest(player);
  }
}
