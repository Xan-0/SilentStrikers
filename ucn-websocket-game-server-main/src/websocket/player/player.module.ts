import { Module } from '@nestjs/common';
import { PlayerService } from './player.service';
import { PlayerEvents } from './player.events';
import { GameModule } from '../game/game.module';
import { PlayerListModule } from '../player-list/player-list.module';

@Module({
  imports: [GameModule, PlayerListModule],
  providers: [PlayerService, PlayerEvents],
  exports: [PlayerService, PlayerEvents],
})
export class PlayerModule {}
