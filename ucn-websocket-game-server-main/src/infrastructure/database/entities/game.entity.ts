import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from 'typeorm';

import { ScoreEntity } from './score.entity';
import { Game, Score } from '../../../domain/models';
import { EGameTableColumns, ETableNames } from '../enums';

@Entity({ name: ETableNames.Game })
export class GameEntity implements Game {
  @PrimaryGeneratedColumn('uuid', { name: EGameTableColumns.Id })
  id: string;

  @Column({ name: EGameTableColumns.Name })
  name: string;

  @Column({ name: EGameTableColumns.Keyword })
  keyword: string;

  @OneToMany(() => ScoreEntity, (score) => score.game)
  scores?: Score[];
}
