import { SubscribeMessage } from '@nestjs/websockets';
import { applyDecorators, UseFilters, UseInterceptors } from '@nestjs/common';

import { WsGameExceptionFilter } from '../filters';
import { WsEventHandlerInterceptor } from '../interceptors';

export function WsEventListener(event: string, login = true) {
  return applyDecorators(
    UseFilters(new WsGameExceptionFilter(event)),
    UseInterceptors(new WsEventHandlerInterceptor(event, login)),
    SubscribeMessage(event),
  );
}
