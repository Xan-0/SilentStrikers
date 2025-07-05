import { Game } from '../models';

export interface AuthRepository {
  getGameLoginData(gameId: string): Promise<Game>;
}

export const AUTH_REPOSITORY = Symbol('AUTH_REPOSITORY');
