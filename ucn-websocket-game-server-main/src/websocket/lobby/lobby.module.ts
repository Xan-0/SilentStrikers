import { Module } from '@nestjs/common';

import { PlayerListModule } from '../player-list/player-list.module';

import { LobbyService } from './lobby.service';
import { LobbyEvents } from './lobby.events';

@Module({
  imports: [PlayerListModule],
  providers: [LobbyService, LobbyEvents],
  exports: [LobbyService, LobbyEvents],
})
export class LobbyModule {}
