import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { GameEntity } from './game.entity';
import { Game, Score } from '../../../domain/models';
import { EScoreTableColumns, ETableNames } from '../enums';

@Entity({ name: ETableNames.Score })
export class ScoreEntity implements Score {
  @PrimaryGeneratedColumn({ name: EScoreTableColumns.Id })
  id: number;

  @Column({ name: EScoreTableColumns.PlayerName })
  playerName: string;

  @Column({ name: EScoreTableColumns.Score })
  score: number;

  @ManyToOne(() => GameEntity, (game) => game.scores)
  @JoinColumn({ name: EScoreTableColumns.GameId })
  game?: Game;
}
