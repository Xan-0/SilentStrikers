import { Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';

import { Score } from '../../../domain/models';
import { ScoreEntity } from '../entities/score.entity';
import { ScoreRepository } from '../../../domain/repositories';
import { AddGameScoreParams } from '../../../domain/repositories/params';

@Injectable()
export class ScoreRepositoryImp implements ScoreRepository {
  constructor(
    @InjectRepository(ScoreEntity)
    private readonly scoreRepository: Repository<ScoreEntity>,
  ) {}

  getScore(id: number): Promise<Score> {
    return this.scoreRepository.findOne({ where: { id } });
  }

  getAllScores(): Promise<Score[]> {
    return this.scoreRepository.find();
  }

  getScoresByGame(gameId: string): Promise<Score[]> {
    return this.scoreRepository.find({
      select: {
        id: true,
        playerName: true,
        score: true,
        game: {
          id: false,
          keyword: false,
          name: false,
        },
      },
      where: { game: { id: gameId } },
      order: { score: 'DESC' },
      relations: { game: true },
    });
  }

  async addGameScore(params: AddGameScoreParams): Promise<Score> {
    const score = this.scoreRepository.create({
      playerName: params.playerName,
      score: params.score,
      game: { id: params.gameId },
    });

    await this.scoreRepository.insert(score);

    const { game, ...result } = score;
    return result;
  }

  async deleteGameScores(gameId: string): Promise<void> {
    await this.scoreRepository.delete({ game: { id: gameId } });
  }

  async deleteAllScores(): Promise<void> {
    await this.scoreRepository.delete({});
  }
}
