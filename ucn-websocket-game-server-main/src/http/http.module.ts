import { Module } from '@nestjs/common';

import { AuthModule } from '../modules/auth/auth.module';
import { ScoreModule } from '../modules/score/score.module';

import { ScoreController } from './score.controller';

@Module({
  imports: [AuthModule, ScoreModule],
  controllers: [ScoreController],
})
export class HttpModule {}
