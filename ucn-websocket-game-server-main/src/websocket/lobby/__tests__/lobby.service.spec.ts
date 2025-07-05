import { Test } from '@nestjs/testing';

import { Player } from '../../common/entities';
import { LobbyService } from '../lobby.service';
import { GameException } from '../../config/game.exception';
import { PlayerListService } from '../../player-list/player-list.service';

import {
  PLAYER_ONE_MOCK_DATA,
  PLAYER_TWO_MOCK_DATA,
} from './lobby.service.mocks';

describe('LobbyService', () => {
  let playerListService: PlayerListService;
  let service: LobbyService;

  let playerOne: Player;
  let playerTwo: Player;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [PlayerListService, LobbyService],
    }).compile();

    playerListService = module.get(PlayerListService);
    service = module.get(LobbyService);

    playerOne = new Player(PLAYER_ONE_MOCK_DATA);
    playerTwo = new Player(PLAYER_TWO_MOCK_DATA);

    playerListService.addPlayer(playerOne);
    playerListService.addPlayer(playerTwo);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('#getOnlinePlayers', () => {
    it('should get the player list', () => {
      const result = service.getOnlinePlayers();

      expect(result).toBeDefined();
    });
  });

  describe('#sendPublicMessage', () => {
    it('should not to throw an error if the message is correct', () => {
      expect(() => service.sendPublicMessage(playerOne, 'Hello')).not.toThrow();
    });

    it('should throw an error if the message is empty', () => {
      [null, undefined, '', ' ', ' \n\t '].forEach((m) => {
        expect(() => service.sendPublicMessage(playerOne, m)).toThrow(
          GameException,
        );
      });
    });
  });

  describe('#sendPrivateMessage', () => {
    it('should not to throw an error if the message is correct', () => {
      expect(() =>
        service.sendPrivateMessage(playerOne, playerTwo.id, 'Hello'),
      ).not.toThrow();
    });

    it('should throw an error if the message is empty', () => {
      [null, undefined, '', ' ', ' \n\t '].forEach((m) => {
        expect(() =>
          service.sendPrivateMessage(playerOne, playerTwo.id, m),
        ).toThrow(GameException);
      });
    });

    it('should throw an error if the destinator player not exists', () => {
      expect(() =>
        service.sendPrivateMessage(playerOne, 'not_id', 'Hello'),
      ).toThrow(GameException);
    });
  });
});
