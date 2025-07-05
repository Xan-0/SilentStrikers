import { Injectable } from '@nestjs/common';

import {
  EGameMatchListenEvent,
  EGameMatchTriggerEvent,
} from 'src/websocket/common/events';
import { Match, Player } from 'src/websocket/common/entities';
import { EMatchPlayerStatus, EMatchStatus } from 'src/websocket/common/enums';

import { GameResponse } from 'src/websocket/config/game-response.type';
import { GameException } from 'src/websocket/config/game.exception';

@Injectable()
export class PingMatchUseCase {
  exec(player: Player): GameResponse {
    const { match } = player;

    const matchPlayer = this._checkMatchPlayerStatus(match, player);

    matchPlayer.status = EMatchPlayerStatus.Connected;

    this._checkBothPlayers(match);

    return {
      msg: `You send your ping successfully.`,
      data: { matchId: match.id },
    };
  }

  private _checkMatchPlayerStatus(match: Match, player: Player) {
    const { destPlayer, senderPlayer } = match;

    const playerToCheck =
      player === destPlayer.player ? destPlayer : senderPlayer;

    if (playerToCheck.status === EMatchPlayerStatus.WaitingConnection) {
      GameException.throwException(
        `You need to establish connection first with '${EGameMatchTriggerEvent.ConnectMatch}'.`,
        {
          matchId: match.id,
          matchPlayerStatus: playerToCheck.status,
        },
      );
    }

    if (playerToCheck.status === EMatchPlayerStatus.WaitingApprove) {
      GameException.throwException(
        `You need to approve this match request first.`,
        { matchId: match.id, matchStatus: match.status },
      );
    }

    if (playerToCheck.status !== EMatchPlayerStatus.WaitingSync) {
      GameException.throwException(
        `The match has started. You cannot sent this event.`,
        { matchId: match.id, matchStatus: match.status },
      );
    }

    return playerToCheck;
  }

  private _checkBothPlayers(match: Match) {
    const { player: senderPlayer, status: senderStatus } = match.senderPlayer;
    const { player: destPlayer, status: destStatus } = match.destPlayer;

    if (
      senderStatus === destStatus &&
      senderStatus === EMatchPlayerStatus.Connected
    ) {
      match.status = EMatchStatus.Playing;

      [senderPlayer, destPlayer].forEach((p) =>
        p.sendEvent(
          EGameMatchListenEvent.MatchStart,
          `Match is ready to receive events. Send it with '${EGameMatchTriggerEvent.SendData}'.`,
          { matchId: match.id },
        ),
      );
    }
  }
}
