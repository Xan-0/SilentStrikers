import { Repository } from 'typeorm';
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';

import { Game } from '../../../domain/models';
import { GameEntity } from '../entities';
import { AuthRepository } from '../../../domain/repositories';

@Injectable()
export class AuthRepositoryImp implements AuthRepository {
  constructor(
    @InjectRepository(GameEntity)
    private readonly gameRepository: Repository<GameEntity>,
  ) {}

  getGameLoginData(gameId: string): Promise<Game> {
    return this.gameRepository.findOne({ where: { id: gameId } });
  }
}
