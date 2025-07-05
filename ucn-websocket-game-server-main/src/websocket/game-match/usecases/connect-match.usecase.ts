import { Injectable } from '@nestjs/common';

import {
  EGameMatchListenEvent,
  EGameMatchTriggerEvent,
} from 'src/websocket/common/events';
import { Match, Player } from 'src/websocket/common/entities';
import { EMatchPlayerStatus } from 'src/websocket/common/enums';

import { GameResponse } from 'src/websocket/config/game-response.type';
import { GameException } from 'src/websocket/config/game.exception';

@Injectable()
export class ConnectMatchUseCase {
  exec(player: Player): GameResponse {
    const { match } = player;

    const matchPlayer = this._checkMatchPlayerStatus(match, player);

    matchPlayer.status = EMatchPlayerStatus.WaitingSync;

    this._checkBothPlayers(match);

    return {
      msg: `You are in the match room. Wait until the '${EGameMatchListenEvent.PlayersReady}' event triggered.`,
      data: { matchId: match.id },
    };
  }

  private _checkMatchPlayerStatus(match: Match, player: Player) {
    const { destPlayer, senderPlayer } = match;

    const playerToCheck =
      player === destPlayer.player ? destPlayer : senderPlayer;

    const { status } = playerToCheck;

    if (status === EMatchPlayerStatus.WaitingApprove) {
      GameException.throwException(
        `You need to approve this match request first.`,
        { matchId: match.id, matchStatus: match.status },
      );
    }

    if (status !== EMatchPlayerStatus.WaitingConnection) {
      GameException.throwException(
        `You are already connected to this match. Wait '${EGameMatchListenEvent.PlayersReady}' event to sync.`,
        {
          matchId: match.id,
          matchPlayerStatus: playerToCheck.status,
        },
      );
    }

    return playerToCheck;
  }

  private _checkBothPlayers(match: Match) {
    const { player: senderPlayer, status: senderStatus } = match.senderPlayer;
    const { player: destPlayer, status: destStatus } = match.destPlayer;

    if (
      senderStatus === destStatus &&
      senderStatus === EMatchPlayerStatus.WaitingSync
    ) {
      [senderPlayer, destPlayer].forEach((p) =>
        p.sendEvent(
          EGameMatchListenEvent.PlayersReady,
          `Both players are ready to start. Send '${EGameMatchTriggerEvent.PingMatch}' to sync times.`,
          { matchId: match.id },
        ),
      );
    }
  }
}
