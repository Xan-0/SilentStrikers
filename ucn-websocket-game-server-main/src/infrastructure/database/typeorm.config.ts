import { DataSourceOptions } from 'typeorm';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { PostgresConnectionOptions } from 'typeorm/driver/postgres/PostgresConnectionOptions';
import { SqliteConnectionOptions } from 'typeorm/driver/sqlite/SqliteConnectionOptions';

import { ConfigService } from '../config/config.service';

type CompatibleDBOptions = Pick<DataSourceOptions, 'type'> &
  (PostgresConnectionOptions | SqliteConnectionOptions);

export const getTypeOrmModuleOptions = (
  config: ConfigService,
): TypeOrmModuleOptions => ({
  ...dbSelector(config),
  autoLoadEntities: true,
  synchronize: false,
});

export const dbSelector = (config: ConfigService): CompatibleDBOptions => {
  const dbLocation = config.getDatabaseUrl();
  const dbType = config.getDatabaseType();

  const selector: Record<'sqlite' | 'postgres', CompatibleDBOptions> = {
    sqlite: { type: 'sqlite', database: dbLocation },
    postgres: { type: 'postgres', url: dbLocation },
  };

  if (dbType === 'sqlite' || dbType === 'postgres') {
    return selector[dbType];
  }

  throw new Error(`Unsupported database type: ${dbType}`);
};
