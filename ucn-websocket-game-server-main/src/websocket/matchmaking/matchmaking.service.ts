import { Injectable } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';

import { LobbyService } from '../lobby/lobby.service';
import { PlayerListService } from '../player-list/player-list.service';

import {
  EMatchPlayerStatus,
  EMatchStatus,
  EPlayerStatus,
} from '../common/enums';
import {
  EMatchmakingListenEvent,
  EMatchmakingTriggerEvent,
} from '../common/events';
import { Match, Player } from '../common/entities';

import { GameException } from '../config/game.exception';

@Injectable()
export class MatchmakingService {
  constructor(
    private readonly playerListService: PlayerListService,
    private readonly lobbyService: LobbyService,
  ) {}

  sendMatchRequest(senderPlayer: Player, playerId: string) {
    if (senderPlayer.id === playerId) {
      GameException.throwException(
        `You cannot send a match request to yourself.`,
        { playerId },
      );
    }

    this._checkSenderStatus(senderPlayer);
    const playerToSend = this._checkDestintatorStatus(playerId);

    const match = this._createMatch(senderPlayer, playerToSend);
    playerToSend.sendEvent(
      EMatchmakingListenEvent.MatchRequestReceived,
      `Match request received from player '${senderPlayer.name}'`,
      {
        playerId: senderPlayer.id,
        matchId: match.id,
      },
    );

    return {
      msg: `Match request sent to player '${playerToSend.name}'.`,
      data: { matchId: match.id },
    };
  }

  cancelMatchRequest(senderPlayer: Player) {
    const { match } = senderPlayer;
    this._checkMatchStatus(senderPlayer);
    this._checkCancelMatchRequestOwner(match, senderPlayer);

    const { player: destPlayer } = match.destPlayer;
    this._deleteMatchRequest(match);

    destPlayer.sendEvent(
      EMatchmakingListenEvent.MatchRequestCancelled,
      `Player '${senderPlayer.name}' has cancelled the match request.`,
      { playerId: senderPlayer.id },
    );

    return {
      msg: `The match request to player '${destPlayer.name}' has been cancelled.`,
      data: { playerId: destPlayer.id },
    };
  }

  acceptMatchRequest(destPlayer: Player) {
    const { match } = destPlayer;
    this._checkMatchStatus(destPlayer);
    this._checkAcceptMatchRequestDestinator(match, destPlayer);

    this._acceptMatch(match);

    const { player: senderPlayer } = match.senderPlayer;
    senderPlayer.sendEvent(
      EMatchmakingListenEvent.MatchRequestAccepted,
      `Player '${destPlayer.name}' has accepted your match request.`,
      {
        playerId: destPlayer.id,
        matchId: match.id,
        matchStatus: match.status,
      },
    );

    return {
      msg: `The match request from player '${senderPlayer.name}' has been accepted.`,
      data: {
        matchId: match.id,
        matchStatus: match.status,
      },
    };
  }

  rejectMatchRequest(destPlayer: Player) {
    const { match } = destPlayer;
    this._checkMatchStatus(destPlayer);
    this._checkRejectMatchRequestDestinator(match, destPlayer);

    const { player: senderPlayer } = match.senderPlayer;
    this._deleteMatchRequest(match);

    senderPlayer.sendEvent(
      EMatchmakingListenEvent.MatchRequestRejected,
      `Player '${destPlayer.name}' has rejected your match request.`,
      { playerId: destPlayer.id, playerName: destPlayer.name },
    );

    return {
      msg: `The match request from player '${senderPlayer.name}' has been rejected.`,
      data: { playerId: senderPlayer.id },
    };
  }

  private _checkSenderStatus(sender: Player) {
    if (sender.status === EPlayerStatus.Available) {
      return;
    }

    const match = sender.match;
    const result = { matchId: match.id, matchStatus: match.status };

    if (sender.status === EPlayerStatus.InMatch) {
      GameException.throwException(
        `You cannot send match requests because you are already in one.`,
        result,
      );
    }

    GameException.throwException(
      sender.id === match.senderPlayer.player.id
        ? `You have already submitted a match request. Wait for it to be approved or rejected, or wait a few seconds.`
        : `You have a pending match request. Approve or reject it before submitting a new one.`,
      result,
    );
  }

  private _checkDestintatorStatus(destPlayerId: string) {
    const dest = this.playerListService.getPlayerById(destPlayerId);
    if (!dest) {
      GameException.throwException(
        `Player with id '${destPlayerId}' not exists.`,
        { playerId: destPlayerId },
      );
    }

    const playerStatus = dest.status;
    const result = { playerId: dest.id, playerStatus };

    if (playerStatus === EPlayerStatus.Busy) {
      GameException.throwException(
        `Player '${dest.name}' is busy. Try again later.`,
        result,
      );
    }

    if (playerStatus === EPlayerStatus.InMatch) {
      GameException.throwException(
        `Player '${dest.name}' is in another match. Wait until this match ends.`,
        result,
      );
    }

    return dest;
  }

  private _createMatch(senderPlayer: Player, destPlayer: Player): Match {
    const match = new Match({
      id: uuidv4(),
      senderPlayer: {
        player: senderPlayer,
        status: EMatchPlayerStatus.WaitingApprove,
      },
      destPlayer: {
        player: destPlayer,
        status: EMatchPlayerStatus.WaitingApprove,
      },
      status: EMatchStatus.Requested,
    });

    [senderPlayer, destPlayer].forEach((p) =>
      this.lobbyService.updatePlayerStatus(p, EPlayerStatus.Busy),
    );
    senderPlayer.match = destPlayer.match = match;

    return match;
  }

  private _checkMatchStatus(senderPlayer: Player) {
    const { match } = senderPlayer;
    if (!match) {
      GameException.throwException(`You do not have an active match request.`, {
        playerStatus: senderPlayer.status,
      });
    }

    if (match.status !== EMatchStatus.Requested) {
      GameException.throwException(
        `Match is in progress and cannot be cancelled or rejected.`,
        { matchId: match.id, matchStatus: match.status },
      );
    }
  }

  private _checkCancelMatchRequestOwner(match: Match, senderPlayer: Player) {
    if (match.senderPlayer.player.id !== senderPlayer.id) {
      GameException.throwException(
        `You cannot cancel an incoming match request. You need to reject it with the event '${EMatchmakingTriggerEvent.RejectMatch}'.`,
        { matchId: match.id, matchStatus: match.status },
      );
    }
  }

  private _checkRejectMatchRequestDestinator(match: Match, destPlayer: Player) {
    if (match.destPlayer.player.id !== destPlayer.id) {
      GameException.throwException(
        `You cannot reject a match request you have sent. You need to cancel it with the event '${EMatchmakingTriggerEvent.CancelMatchRequest}'.`,
        { matchStatus: match.status },
      );
    }
  }

  private _checkAcceptMatchRequestDestinator(match: Match, destPlayer: Player) {
    if (match.destPlayer.player.id !== destPlayer.id) {
      GameException.throwException(
        `You cannot accept a match request you have sent.`,
        { matchId: match.id, matchStatus: match.status },
      );
    }
  }

  private _acceptMatch(match: Match) {
    const { player: senderPlayer } = match.senderPlayer;
    const { player: destPlayer } = match.destPlayer;

    match.status = EMatchStatus.WaitingPlayers;
    [senderPlayer, destPlayer].forEach((p) =>
      this.lobbyService.updatePlayerStatus(p, EPlayerStatus.InMatch),
    );

    match.senderPlayer.status = match.destPlayer.status =
      EMatchPlayerStatus.WaitingConnection;
  }

  private _deleteMatchRequest(match: Match) {
    const { player: senderPlayer } = match.senderPlayer;
    const { player: destPlayer } = match.destPlayer;

    senderPlayer.match = destPlayer.match = null;
    [senderPlayer, destPlayer].forEach((p) =>
      this.lobbyService.updatePlayerStatus(p, EPlayerStatus.Available),
    );
  }
}
