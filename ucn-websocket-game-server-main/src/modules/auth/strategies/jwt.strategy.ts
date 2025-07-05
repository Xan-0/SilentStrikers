import { compareSync } from 'bcrypt';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';

import { Game } from '../../../domain/models';
import { JwtPayload, UserRequest } from '../interfaces';
import { ConfigService } from '../../../infrastructure/config/config.service';
import { AUTH_REPOSITORY, AuthRepository } from '../../../domain/repositories';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @Inject(AUTH_REPOSITORY) private readonly authRepository: AuthRepository,
    configService: ConfigService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: configService.getJwtSecret(),
    });
  }

  async validate(payload: JwtPayload): Promise<UserRequest> {
    const game = await this._getGame(payload.userId);

    if (!this._checkGameData(payload.key, game)) {
      throw new UnauthorizedException('Wrong Token');
    }

    return { gameId: payload.userId };
  }

  private async _getGame(gameId: string) {
    if (!gameId) {
      return null;
    }
    return this.authRepository.getGameLoginData(gameId);
  }

  private _checkGameData(requestKey: string, game: Game) {
    if (!game || !compareSync(requestKey, game.keyword)) {
      return false;
    }
    return true;
  }
}
