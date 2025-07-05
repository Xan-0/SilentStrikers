import { Module } from '@nestjs/common';

import { InfrastructureModule } from 'src/infrastructure/infrastructure.module';

import { ScoreService } from './score.service';

@Module({
  imports: [InfrastructureModule],
  providers: [ScoreService],
  exports: [ScoreService],
})
export class ScoreModule {}
