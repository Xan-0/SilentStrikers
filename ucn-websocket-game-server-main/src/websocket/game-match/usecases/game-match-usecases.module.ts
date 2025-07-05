import { Module } from '@nestjs/common';

import { LobbyModule } from 'src/websocket/lobby/lobby.module';

import { SendDataUseCase } from './send-data.usecase';
import { QuitMatchUseCase } from './quit-match.usecase';
import { PingMatchUseCase } from './ping-match.usecase';
import { FinishGameUseCase } from './finish-game.usecase';
import { ConnectMatchUseCase } from './connect-match.usecase';
import { SendRematchRequestUseCase } from './send-rematch-request.usecase';

@Module({
  imports: [LobbyModule],
  providers: [
    ConnectMatchUseCase,
    PingMatchUseCase,
    SendDataUseCase,
    FinishGameUseCase,
    SendRematchRequestUseCase,
    QuitMatchUseCase,
  ],
  exports: [
    ConnectMatchUseCase,
    PingMatchUseCase,
    SendDataUseCase,
    FinishGameUseCase,
    SendRematchRequestUseCase,
    QuitMatchUseCase,
  ],
})
export class GameMatchUseCasesModule {}
