import { Injectable } from '@nestjs/common';

import { Player } from '../common/entities';

import { GameMatchService } from './game-match.service';

@Injectable()
export class GameMatchEvents {
  constructor(private readonly gameMatchService: GameMatchService) {}

  connectMatch(player: Player) {
    return this.gameMatchService.connectMatch(player);
  }

  pingMatch(player: Player) {
    return this.gameMatchService.pingMatch(player);
  }

  sendData(player: Player, data: object) {
    return this.gameMatchService.sendData(player, data);
  }

  finishGame(player: Player) {
    return this.gameMatchService.finishGame(player);
  }

  sendRematchRequest(player: Player) {
    return this.gameMatchService.sendRematchRequest(player);
  }

  quitMatch(player: Player) {
    return this.gameMatchService.quitMatch(player);
  }
}
