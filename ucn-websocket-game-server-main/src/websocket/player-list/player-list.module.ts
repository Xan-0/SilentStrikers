import { Module } from '@nestjs/common';
import { PlayerListService } from './player-list.service';

@Module({
  providers: [PlayerListService],
  exports: [PlayerListService],
})
export class PlayerListModule {}
