import { Injectable } from '@nestjs/common';

import { ConfigService } from 'src/infrastructure/config/config.service';

import { Game } from '../common/entities';

@Injectable()
export class GameService {
  private readonly gameList: Game[] = [
    { id: 'A', name: 'Contaminación Mortal', team: '404 Studios', key: '' },
    { id: 'B', name: 'Silent Strikers', team: 'Phantom Bytes', key: '' },
    { id: 'C', name: 'Alpha Centauri', team: 'ZUSHI', key: '' },
    { id: 'D', name: 'Verdadera Forma', team: 'DigiDevs', key: '' },
    { id: 'E', name: 'Gatcha!', team: 'Capa8', key: '' },
    { id: 'F', name: 'Jackpot Journey', team: 'Glitch Hunters', key: '' },
    { id: 'G', name: 'Shovel Hustle', team: 'Fruna Games', key: '' },
    { id: 'H', name: 'Snack Guardian', team: 'Retro-Machine Studios', key: '' },
    { id: 'I', name: 'Example Game Test Only', team: 'Test Only', key: '' },
  ];

  constructor(private readonly configService: ConfigService) {
    const keys = this.configService.getValidationGameKeys();

    if (!keys) {
      throw Error(
        'You need to set game keys in format <GAME_ID>:<GAME_KEY>;...',
      );
    }

    keys.split(';').forEach((v) => {
      const data = v.split(':');
      if (!data[0] || !this.getGame(data[0])) {
        throw Error(
          'You need to set game keys in format <GAME_ID>:<GAME_KEY>;...',
        );
      }

      this.getGame(data[0]).key = data[1];
    });
  }

  getGame(gameId: string) {
    return this.gameList.find((g) => g.id === gameId);
  }

  checkGameKey(gameId: string, key: string) {
    const game = this.getGame(gameId);
    return game && game.key === key;
  }
}
