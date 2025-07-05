import { Module } from '@nestjs/common';

import { GameMatchService } from './game-match.service';
import { GameMatchEvents } from './game-match.events';
import { GameMatchUseCasesModule } from './usecases/game-match-usecases.module';

@Module({
  imports: [GameMatchUseCasesModule],
  providers: [GameMatchService, GameMatchEvents],
  exports: [GameMatchService, GameMatchEvents],
})
export class GameMatchModule {}
