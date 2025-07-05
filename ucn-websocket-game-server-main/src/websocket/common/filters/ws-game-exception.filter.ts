import { WebSocket } from 'ws';
import { ArgumentsHost, Catch, ExceptionFilter } from '@nestjs/common';

import { GameException } from '../../config/game.exception';

@Catch(GameException)
export class WsGameExceptionFilter implements ExceptionFilter {
  constructor(private readonly event: string) {}

  catch(exception: GameException, host: ArgumentsHost) {
    const client = host.switchToWs().getClient<WebSocket>();
    client.send(
      JSON.stringify({
        event: this.event,
        status: 'ERROR',
        msg: exception.gameMessage,
        data: !exception.data
          ? null
          : {
              ...exception.data,
            },
      }),
    );
  }
}
