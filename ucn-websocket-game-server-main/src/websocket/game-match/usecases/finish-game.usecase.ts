import { Injectable } from '@nestjs/common';

import { EMatchStatus } from 'src/websocket/common/enums';
import { Match, Player } from 'src/websocket/common/entities';
import { EGameMatchListenEvent } from 'src/websocket/common/events';

import { GameResponse } from 'src/websocket/config/game-response.type';
import { GameException } from 'src/websocket/config/game.exception';

@Injectable()
export class FinishGameUseCase {
  exec(player: Player, opponent: Player): GameResponse {
    const { match } = player;
    this._validateMatch(match);

    this._finishGame(match);

    opponent.sendEvent(
      EGameMatchListenEvent.GameEnded,
      `Game over! '${player.name}' wins!`,
      { matchStatus: match.status },
    );

    return {
      msg: `Game over! '${player.name}' wins!`,
      data: { matchId: match.id, matchStatus: match.status },
    };
  }

  private _validateMatch(match: Match) {
    const { id, status } = match;

    if (status === EMatchStatus.Finished) {
      GameException.throwException(`The match has already finished.`, {
        matchId: id,
        matchStatus: status,
      });
    }

    if (status !== EMatchStatus.Playing) {
      GameException.throwException(`The match has not been started yet.`, {
        matchId: id,
        matchStatus: status,
      });
    }
  }

  private _finishGame(match: Match) {
    match.status = EMatchStatus.Finished;
  }
}
