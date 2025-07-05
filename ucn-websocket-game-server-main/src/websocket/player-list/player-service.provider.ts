import { PlayerListService } from './player-list.service';

export class PlayerListServiceProvider {
  private static playerListService: PlayerListService;

  static set(service: PlayerListService) {
    this.playerListService = service;
  }

  static get() {
    if (!this.playerListService) {
      throw new Error('PlayerListService not set');
    }
    return this.playerListService;
  }
}
