import { Player } from './player.entity';
import { EMatchPlayerStatus, EMatchStatus } from '../enums';

interface MatchPlayer {
  player: Player;
  status: EMatchPlayerStatus;
}

export class Match {
  readonly id: string;
  readonly senderPlayer: MatchPlayer;
  readonly destPlayer: MatchPlayer;
  status: EMatchStatus;

  constructor(partial: Partial<Match>) {
    Object.assign(this, partial);
  }

  getPlayers() {
    return [
      this.senderPlayer.player.getPlayerData(),
      this.destPlayer.player.getPlayerData(),
    ];
  }
}
