import { Test } from '@nestjs/testing';

import { LobbyService } from '../../lobby/lobby.service';
import { PlayerListService } from '../../player-list/player-list.service';
import { MatchmakingService } from '../matchmaking.service';

import { GameException } from '../../config/game.exception';

import { EMatchStatus, EPlayerStatus } from '../../common/enums';
import { Player } from '../../common/entities';

import {
  PLAYER_AVAILABLE_MOCK_DATA,
  PLAYER_SENDER_MOCK_DATA,
} from './matchmaking.service.mocks';

describe('#MatchmakingService', () => {
  let playerListService: PlayerListService;
  let service: MatchmakingService;

  let playerAvailable: Player;
  let playerSender: Player;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [PlayerListService, LobbyService, MatchmakingService],
    }).compile();

    playerListService = module.get(PlayerListService);
    service = module.get(MatchmakingService);

    playerAvailable = new Player(PLAYER_AVAILABLE_MOCK_DATA);
    playerSender = new Player(PLAYER_SENDER_MOCK_DATA);

    playerListService.addPlayer(playerAvailable);
    playerListService.addPlayer(playerSender);
  });

  it('should be defined', () => {
    expect(playerListService).toBeDefined();
    expect(service).toBeDefined();
  });

  describe('#sendMatchRequest', () => {
    it('should send an invitation, changing the state for both players to busy and assign a match', () => {
      const result = service.sendMatchRequest(playerSender, playerAvailable.id);

      expect(result).toBeDefined();

      expect(playerSender).toHaveProperty('status', EPlayerStatus.Busy);
      expect(playerAvailable).toHaveProperty('status', EPlayerStatus.Busy);

      expect(playerSender.match).toBeDefined();
      expect(playerAvailable.match).toBeDefined();
      expect(playerSender.match).toStrictEqual(playerAvailable.match);

      expect(playerSender.match.getPlayers()).toContainEqual(
        playerSender.getPlayerData(),
      );
      expect(playerSender.match.getPlayers()).toContainEqual(
        playerAvailable.getPlayerData(),
      );

      expect(result.data).toHaveProperty('matchId', playerAvailable.match.id);
    });

    it('should not send an invitation if destination player is busy', () => {
      const playerMatchReceived = new Player({
        ...PLAYER_AVAILABLE_MOCK_DATA,
        id: 'new-player-one',
      });
      playerListService.addPlayer(playerMatchReceived);

      service.sendMatchRequest(playerAvailable, playerMatchReceived.id);

      expect(() =>
        service.sendMatchRequest(playerSender, playerAvailable.id),
      ).toThrow(GameException);

      expect(playerSender.status).toBe(EPlayerStatus.Available);
      expect(playerSender.match).not.toBeDefined();
    });

    it('should not send an invitation if destination player is in match', () => {
      const playerMatchReceived = new Player({
        ...PLAYER_AVAILABLE_MOCK_DATA,
        id: 'new-player-one',
      });
      playerListService.addPlayer(playerMatchReceived);

      service.sendMatchRequest(playerAvailable, playerMatchReceived.id);
      service.acceptMatchRequest(playerMatchReceived);

      expect(() =>
        service.sendMatchRequest(playerSender, playerAvailable.id),
      ).toThrow(GameException);

      expect(playerSender.status).toBe(EPlayerStatus.Available);
      expect(playerSender.match).not.toBeDefined();
    });

    it('should not send an invitation if player has a pending match request (received or sent)', () => {
      const playerMatchReceived = new Player({
        ...PLAYER_AVAILABLE_MOCK_DATA,
        id: 'new-player-one',
      });
      playerListService.addPlayer(playerMatchReceived);
      playerListService.addPlayer(
        new Player({ ...PLAYER_AVAILABLE_MOCK_DATA, id: 'new-player-two' }),
      );

      const result = service.sendMatchRequest(
        playerAvailable,
        playerMatchReceived.id,
      );

      const { matchId } = result.data;

      expect(() =>
        service.sendMatchRequest(playerAvailable, 'new-player-two'),
      ).toThrow(GameException);

      expect(() =>
        service.sendMatchRequest(playerMatchReceived, playerAvailable.id),
      ).toThrow(GameException);

      expect(playerAvailable.status).toBe(EPlayerStatus.Busy);
      expect(playerAvailable.match).toBeDefined();
      expect(playerAvailable.match.id).toBe(matchId);
    });

    it('should not send an invitation if sender player is in a match', () => {
      const playerMatchReceived = new Player({
        ...PLAYER_AVAILABLE_MOCK_DATA,
        id: 'new-player-one',
      });
      playerListService.addPlayer(playerMatchReceived);

      service.sendMatchRequest(playerSender, playerMatchReceived.id);
      const result = service.acceptMatchRequest(playerMatchReceived);

      const { matchId } = result.data;

      expect(() =>
        service.sendMatchRequest(playerSender, playerAvailable.id),
      ).toThrow(GameException);

      expect(playerSender.status).toBe(EPlayerStatus.InMatch);
      expect(playerSender.match).toBeDefined();
      expect(playerSender.match).toHaveProperty('id', matchId);
    });

    it('should not send an invitation to himself', () => {
      expect(() =>
        service.sendMatchRequest(playerAvailable, playerAvailable.id),
      ).toThrow(GameException);
    });
  });

  describe('#cancelMatchRequest', () => {
    it('should cancel the match if it has not started yet', () => {
      service.sendMatchRequest(playerSender, playerAvailable.id);

      const result = service.cancelMatchRequest(playerSender);

      expect(result).toBeDefined();

      expect(playerSender).toHaveProperty('status', EPlayerStatus.Available);
      expect(playerAvailable).toHaveProperty('status', EPlayerStatus.Available);

      expect(playerSender).toHaveProperty('match', null);
      expect(playerAvailable).toHaveProperty('match', null);
    });

    it('should not cancel the match if this not exists', () => {
      expect(() => service.cancelMatchRequest(playerSender)).toThrow(
        GameException,
      );
    });

    it('should not cancel the match if the destinator calls the event', () => {
      service.sendMatchRequest(playerSender, playerAvailable.id);
      expect(() => service.cancelMatchRequest(playerAvailable)).toThrow(
        GameException,
      );
    });

    it('should not cancel the match if both players had accepted', () => {
      service.sendMatchRequest(playerSender, playerAvailable.id);
      service.acceptMatchRequest(playerAvailable);
      expect(() => service.cancelMatchRequest(playerSender)).toThrow(
        GameException,
      );
    });
  });

  describe('#acceptMatchRequest', () => {
    it('should accept the match if it has not started yet', () => {
      service.sendMatchRequest(playerSender, playerAvailable.id);

      const result = service.acceptMatchRequest(playerAvailable);

      expect(result).toBeDefined();

      expect(playerSender).toHaveProperty('status', EPlayerStatus.InMatch);
      expect(playerAvailable).toHaveProperty('status', EPlayerStatus.InMatch);

      expect(playerSender.match).toBeDefined();
      expect(playerAvailable.match).toBeDefined();
      expect(playerSender.match).toStrictEqual(playerAvailable.match);

      expect(playerSender.match).toHaveProperty(
        'status',
        EMatchStatus.WaitingPlayers,
      );
    });

    it('should not accept the match if this not exists', () => {
      expect(() => service.acceptMatchRequest(playerAvailable)).toThrow(
        GameException,
      );
    });

    it('should not accept the match if the sender calls the event', () => {
      service.sendMatchRequest(playerSender, playerAvailable.id);
      expect(() => service.acceptMatchRequest(playerSender)).toThrow(
        GameException,
      );
    });

    it('should not accept a match that have started', () => {
      service.sendMatchRequest(playerSender, playerAvailable.id);
      service.acceptMatchRequest(playerAvailable);
      expect(() => service.acceptMatchRequest(playerAvailable)).toThrow(
        GameException,
      );
    });
  });

  describe('#rejectMatchRequest', () => {
    it('should reject the match if it has not started yet', () => {
      service.sendMatchRequest(playerSender, playerAvailable.id);

      const result = service.rejectMatchRequest(playerAvailable);

      expect(result).toBeDefined();

      expect(playerSender).toHaveProperty('status', EPlayerStatus.Available);
      expect(playerAvailable).toHaveProperty('status', EPlayerStatus.Available);

      expect(playerSender).toHaveProperty('match', null);
      expect(playerAvailable).toHaveProperty('match', null);
    });

    it('should not reject the match if this not exists', () => {
      expect(() => service.rejectMatchRequest(playerAvailable)).toThrow(
        GameException,
      );
    });

    it('should not reject the match if the sender calls the event', () => {
      service.sendMatchRequest(playerSender, playerAvailable.id);
      expect(() => service.rejectMatchRequest(playerSender)).toThrow(
        GameException,
      );
    });

    it('should not reject the match if both players had accepted', () => {
      service.sendMatchRequest(playerSender, playerAvailable.id);
      service.acceptMatchRequest(playerAvailable);
      expect(() => service.rejectMatchRequest(playerAvailable)).toThrow(
        GameException,
      );
    });
  });
});
