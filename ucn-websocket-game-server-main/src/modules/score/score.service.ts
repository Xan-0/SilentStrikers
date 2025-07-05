import { Inject, Injectable } from '@nestjs/common';

import { AddGameScoreParams } from '../../domain/repositories/params';
import { SCORE_REPOSITORY, ScoreRepository } from '../../domain/repositories';

@Injectable()
export class ScoreService {
  constructor(
    @Inject(SCORE_REPOSITORY)
    private readonly scoreRepository: ScoreRepository,
  ) {}

  getScoreByGame(gameId: string) {
    return this.scoreRepository.getScoresByGame(gameId);
  }

  addGameScore(scoreData: AddGameScoreParams) {
    return this.scoreRepository.addGameScore(scoreData);
  }

  deleteAllGameScores(gameId: string) {
    return this.scoreRepository.deleteGameScores(gameId);
  }
}
