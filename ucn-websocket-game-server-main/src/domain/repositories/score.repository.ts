import { Score } from '../models';
import { AddGameScoreParams } from './params';

export interface ScoreRepository {
  getScore(id: number): Promise<Score>;
  getAllScores(): Promise<Score[]>;
  getScoresByGame(gameId: string): Promise<Score[]>;

  addGameScore(params: AddGameScoreParams): Promise<Score>;

  deleteGameScores(gameId: string): Promise<void>;
  deleteAllScores(): Promise<void>;
}

export const SCORE_REPOSITORY = Symbol('SCORE_REPOSITORY');
