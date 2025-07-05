import { Game } from './game.model';

export interface Score {
  id: number;
  playerName: string;
  score: number;

  game?: Game;
}
