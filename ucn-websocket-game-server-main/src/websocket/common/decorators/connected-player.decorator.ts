import { WebSocket } from 'ws';
import { createParamDecorator, ExecutionContext } from '@nestjs/common';

import { Player } from '../entities';
import { PlayerListServiceProvider } from '../../player-list/player-service.provider';

export const ConnectedPlayer = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): Player => {
    const client: WebSocket = ctx.switchToWs().getClient<WebSocket>();

    const playerListService = PlayerListServiceProvider.get();

    return playerListService.getPlayerBySocket(client);
  },
);
