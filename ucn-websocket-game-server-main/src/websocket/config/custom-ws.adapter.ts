/* eslint-disable @typescript-eslint/no-unsafe-return */
import { WsAdapter } from '@nestjs/platform-ws';
import { INestApplicationContext } from '@nestjs/common';

export class CustomWsAdapter extends WsAdapter {
  constructor(
    private readonly app: INestApplicationContext,
    private readonly envWsPort: number,
  ) {
    super(app);
  }

  create(
    port: number,
    options?: Record<string, any> & {
      namespace?: string;
      server?: any;
      path?: string;
    },
  ) {
    const wsPort = this.envWsPort ?? port ?? 4010;

    return super.create(wsPort, options);
  }
}
