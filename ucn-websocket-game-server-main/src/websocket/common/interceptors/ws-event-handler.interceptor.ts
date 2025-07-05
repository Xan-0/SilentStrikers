import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { WebSocket } from 'ws';
import { map, Observable } from 'rxjs';

import { GameResponse } from '../../config/game-response.type';
import { GameException } from '../../config/game.exception';

import { EPlayerStatus } from '../enums';
import { PlayerListServiceProvider } from '../../player-list/player-service.provider';
import { Player } from '../entities';

@Injectable()
export class WsEventHandlerInterceptor implements NestInterceptor {
  constructor(
    private readonly event: string,
    private readonly loginRequired: boolean,
  ) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const client: WebSocket = context.switchToWs().getClient<WebSocket>();
    const playerListService = PlayerListServiceProvider.get();
    const player = playerListService.getPlayerBySocket(client);

    this._checkUserLogged(player);

    return next.handle().pipe(
      map((resData: GameResponse) => {
        const { data, msg } = resData;
        return { event: this.event, status: 'OK', msg, data };
      }),
    );
  }

  private _checkUserLogged(player: Player) {
    if (this.loginRequired && player.status === EPlayerStatus.NoLogin) {
      GameException.throwException(`You are not logged to the server.`);
    }
  }
}
