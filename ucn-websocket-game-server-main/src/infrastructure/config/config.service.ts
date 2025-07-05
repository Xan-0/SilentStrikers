import { Injectable } from '@nestjs/common';
import { ConfigService as NestConfig } from '@nestjs/config';

@Injectable()
export class ConfigService {
  constructor(private readonly configService: NestConfig) {}

  getAppPort(): number {
    return this._checkVarExists<number>('PORT');
  }

  getWsPort(): number {
    return this._checkVarExists<number>('WS_PORT');
  }

  getDatabaseType(): string {
    return this._checkVarExists<string>('DATABASE_TYPE');
  }

  getDatabaseUrl(): string {
    return this._checkVarExists<string>('DATABASE_URL');
  }

  getJwtSecret(): string {
    return this._checkVarExists<string>('JWT_SECRET');
  }

  getValidationGameKeys(): string {
    return this._checkVarExists<string>('VALIDATION_GAME_KEYS');
  }

  private _checkVarExists<T>(name: string): T {
    const envVar = this.configService.get<T>(name);
    return envVar ?? null;
  }
}
