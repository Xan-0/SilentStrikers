import { DataSource } from 'typeorm';
import { NestFactory } from '@nestjs/core';

import { ConfigService } from '../config/config.service';
import { ConfigModule } from '../config/config.module';
import { dbSelector } from './typeorm.config';

export default (async () => {
  const app = await NestFactory.create(ConfigModule, {
    logger: false,
  });

  const config = app.get(ConfigService);

  return new DataSource({
    ...dbSelector(config),
    entities: ['src/infrastructure/database/entities/*.entity{.js,.ts}'],
    migrations: ['src/infrastructure/database/migrations/*{.js,.ts}'],
    synchronize: false,
  });
})();
