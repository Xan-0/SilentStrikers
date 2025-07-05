import { Module } from '@nestjs/common';
import { GameService } from './game.service';
import { ConfigModule } from 'src/infrastructure/config/config.module';

@Module({
  imports: [ConfigModule],
  providers: [GameService],
  exports: [GameService],
})
export class GameModule {}
