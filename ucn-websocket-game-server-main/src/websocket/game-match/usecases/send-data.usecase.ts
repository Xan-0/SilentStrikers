import { Injectable } from '@nestjs/common';

import { EMatchStatus } from 'src/websocket/common/enums';
import { Match, Player } from 'src/websocket/common/entities';
import { EGameMatchListenEvent } from 'src/websocket/common/events';

import { GameResponse } from 'src/websocket/config/game-response.type';
import { GameException } from 'src/websocket/config/game.exception';

@Injectable()
export class SendDataUseCase {
  exec(player: Player, data: object, opponent: Player): GameResponse {
    const { match } = player;
    this._validateMatch(match);

    opponent.sendEvent(
      EGameMatchListenEvent.ReceiveData,
      `Event received from match.`,
      data,
    );

    return {
      msg: 'Data sended successfully.',
    };
  }

  private _validateMatch(match: Match) {
    const { status } = match;

    if (status !== EMatchStatus.Playing) {
      GameException.throwException(`The match is not started or is finished.`, {
        matchStatus: status,
      });
    }
  }
}
