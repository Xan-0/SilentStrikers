import { Provider } from '@nestjs/common';

import { AuthRepositoryImp } from './auth.repository';
import { ScoreRepositoryImp } from './score.repository';

import {
  AUTH_REPOSITORY,
  SCORE_REPOSITORY,
} from '../../../domain/repositories';

export * from './score.repository';
export * from './auth.repository';

export const REPOSITORIES: Provider[] = [
  { provide: SCORE_REPOSITORY, useClass: ScoreRepositoryImp },
  { provide: AUTH_REPOSITORY, useClass: AuthRepositoryImp },
];
