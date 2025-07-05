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
export class SendRematchRequestUseCase {
  exec(player: Player, opponent: Player): GameResponse {
    const { match } = player;

    this._checkMatch(match);
    this._checkOpponent(opponent);

    this._setWaitingRematchStatus(player, match);

    if (!this._checkBothPlayersReady(match)) {
      opponent?.sendEvent(
        EGameMatchListenEvent.RematchRequest,
        `Player '${player.name}' wants to play again. Send '${EGameMatchTriggerEvent.SendRematchRequest}' to accept.`,
        null,
      );
    }

    return { msg: 'Rematch request sent.' };
  }

  private _checkMatch(match: Match) {
    if (match.status !== EMatchStatus.Finished) {
      GameException.throwException(
        'You can only send a rematch request when the current match is over.',
        { matchId: match.id, matchStatus: match.status },
      );
    }
  }

  private _checkOpponent(opponent: Player) {
    if (!opponent.match) {
      GameException.throwException(
        `Player '${opponent.name}' has quit the game.`,
        { playerId: opponent.id, playerStatus: opponent.status },
      );
    }
  }

  private _setWaitingRematchStatus(player: Player, match: Match) {
    const { senderPlayer, destPlayer } = match;
    if (senderPlayer.player.id === player.id) {
      senderPlayer.status = EMatchPlayerStatus.WaitingRematch;
    }
    if (destPlayer.player.id === player.id) {
      destPlayer.status = EMatchPlayerStatus.WaitingRematch;
    }
  }

  private _checkBothPlayersReady(match: Match) {
    const { senderPlayer, destPlayer } = match;
    if (
      senderPlayer.status === EMatchPlayerStatus.WaitingRematch &&
      senderPlayer.status === destPlayer.status
    ) {
      senderPlayer.status = destPlayer.status = EMatchPlayerStatus.WaitingSync;
      [senderPlayer.player, destPlayer.player].forEach((p) =>
        p.sendEvent(
          EGameMatchListenEvent.PlayersReady,
          `Both players are ready to start. Send '${EGameMatchTriggerEvent.PingMatch}' to sync times.`,
          { matchId: match.id },
        ),
      );
      return true;
    }
    return false;
  }
}
