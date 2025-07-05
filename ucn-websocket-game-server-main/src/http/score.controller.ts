import { Body, Controller, Delete, Get, Post, UseGuards } from '@nestjs/common';

import { GetUser } from '../modules/auth/decorators';
import { UserRequest } from '../modules/auth/interfaces';
import { JwtAuthGuard } from '../modules/auth/guards/jwt-auth.guard';
import { ScoreService } from '../modules/score/score.service';

import { AddScoreDto } from './dtos';

@Controller('scores')
export class ScoreController {
  constructor(private readonly scoreService: ScoreService) {}

  @UseGuards(JwtAuthGuard)
  @Get('/')
  async getScoreByGameId(@GetUser() game: UserRequest) {
    const scores = await this.scoreService.getScoreByGame(game.gameId);
    return { message: 'Score List Received', data: scores };
  }

  @UseGuards(JwtAuthGuard)
  @Post('/')
  async addScore(@GetUser() game: UserRequest, @Body() body: AddScoreDto) {
    const score = await this.scoreService.addGameScore({
      gameId: game.gameId,
      score: body.score,
      playerName: body.playerName,
    });

    return { message: 'Score Submitted', data: score };
  }

  @UseGuards(JwtAuthGuard)
  @Delete('/')
  async removeAllScores(@GetUser() game: UserRequest) {
    await this.scoreService.deleteAllGameScores(game.gameId);
    return { message: 'Deleted All Scores Successfully' };
  }
}
