import {
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  WebSocketGateway,
} from '@nestjs/websockets';
import { parse } from 'url';
import { WebSocket } from 'ws';

import { generateRandomString } from 'src/modules/common/helpers/random';

import {
  EGameMatchTriggerEvent,
  ELobbyTriggerEvent,
  EMatchmakingTriggerEvent,
  EPlayerTriggerEvent,
} from './common/events';
import { Player } from './common/entities';
import { ConnectedPlayer, WsEventListener } from './common/decorators';

import { GameService } from './game/game.service';
import { PlayerService } from './player/player.service';
import { PlayerListService } from './player-list/player-list.service';
import { PlayerListServiceProvider } from './player-list/player-service.provider';

import { LobbyEvents } from './lobby/lobby.events';
import { PlayerEvents } from './player/player.events';
import { GameMatchEvents } from './game-match/game-match.events';
import { MatchmakingEvents } from './matchmaking/matchmaking.events';

import { ChangeUserNameDto, LoginDto } from './player/dtos';

@WebSocketGateway()
export class MainLobbyGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  constructor(
    private readonly gameService: GameService,
    private readonly playerService: PlayerService,
    private readonly playerListService: PlayerListService,

    private readonly playerEvents: PlayerEvents,
    private readonly lobbyEvents: LobbyEvents,
    private readonly matchmakingEvents: MatchmakingEvents,
    private readonly gameMatchEvents: GameMatchEvents,
  ) {}

  afterInit() {
    PlayerListServiceProvider.set(this.playerListService);
  }

  handleConnection(client: WebSocket, req: Request) {
    const { playerName, gameId, game } = this._getGameIdAndName(req);
    const player = this.playerService.createPlayer(client, playerName, game);
    this.playerEvents.connected(player, gameId);
  }

  handleDisconnect(client: WebSocket) {
    const player = this.playerListService.getPlayerBySocket(client);
    this.playerEvents.disconnected(player);
  }

  private _getGameIdAndName(req: Request) {
    const url = parse(req.url, true);
    const { gameId: id, playerName: name } = url.query;

    const gameId = Array.isArray(id) ? id[0] : id;
    const playerName = Array.isArray(name)
      ? name[0]
      : (name ?? `Player_${generateRandomString(8)}`);

    const game = this.gameService.getGame(gameId);

    return { playerName, gameId, game };
  }

  // ------------------------------------
  //           Player Events
  // ------------------------------------

  @WsEventListener(EPlayerTriggerEvent.Login, false)
  login(@ConnectedPlayer() player: Player, @MessageBody() data: LoginDto) {
    return this.playerEvents.login(player, data);
  }

  @WsEventListener(EPlayerTriggerEvent.ChangeName)
  changeUserName(
    @ConnectedPlayer() player: Player,
    @MessageBody() data: ChangeUserNameDto,
  ) {
    return this.playerEvents.changeUserName(player, data);
  }

  @WsEventListener(EPlayerTriggerEvent.PlayerData)
  getPlayerData(@ConnectedPlayer() player: Player) {
    return this.playerEvents.getPlayerData(player);
  }

  // ------------------------------------
  //           Lobby Events
  // ------------------------------------

  @WsEventListener(ELobbyTriggerEvent.OnlinePlayers)
  getConnectedPlayers() {
    return this.lobbyEvents.getConnectedPlayers();
  }

  @WsEventListener(ELobbyTriggerEvent.SendPrivateMessage)
  sendPrivateMessage(@ConnectedPlayer() player: Player, @MessageBody() data) {
    return this.lobbyEvents.sendPrivateMessage(player, data);
  }

  @WsEventListener(ELobbyTriggerEvent.SendPublicMessage)
  sendPublicMessage(@ConnectedPlayer() player: Player, @MessageBody() data) {
    return this.lobbyEvents.sendPublicMessage(player, data);
  }

  // ------------------------------------
  //        Matchmaking Events
  // ------------------------------------

  @WsEventListener(EMatchmakingTriggerEvent.SendMatchRequest)
  sendMatchRequest(@ConnectedPlayer() player: Player, @MessageBody() data) {
    return this.matchmakingEvents.sendMatchRequest(player, data);
  }

  @WsEventListener(EMatchmakingTriggerEvent.CancelMatchRequest)
  cancelMatchRequest(@ConnectedPlayer() player: Player) {
    return this.matchmakingEvents.cancelMatchRequest(player);
  }

  @WsEventListener(EMatchmakingTriggerEvent.AcceptMatch)
  acceptMatchRequest(@ConnectedPlayer() player: Player) {
    return this.matchmakingEvents.acceptMatchRequest(player);
  }

  @WsEventListener(EMatchmakingTriggerEvent.RejectMatch)
  rejectMatchRequest(@ConnectedPlayer() player: Player) {
    return this.matchmakingEvents.rejectMatchRequest(player);
  }

  // ------------------------------------
  //         Game Match Events
  // ------------------------------------

  @WsEventListener(EGameMatchTriggerEvent.ConnectMatch)
  connectMatch(@ConnectedPlayer() player: Player) {
    return this.gameMatchEvents.connectMatch(player);
  }

  @WsEventListener(EGameMatchTriggerEvent.PingMatch)
  pingMatch(@ConnectedPlayer() player: Player) {
    return this.gameMatchEvents.pingMatch(player);
  }

  @WsEventListener(EGameMatchTriggerEvent.SendData)
  sendData(@ConnectedPlayer() player: Player, @MessageBody() data) {
    return this.gameMatchEvents.sendData(player, data);
  }

  @WsEventListener(EGameMatchTriggerEvent.FinishGame)
  finishGame(@ConnectedPlayer() player: Player) {
    return this.gameMatchEvents.finishGame(player);
  }

  @WsEventListener(EGameMatchTriggerEvent.SendRematchRequest)
  sendRematchRequest(@ConnectedPlayer() player: Player) {
    return this.gameMatchEvents.sendRematchRequest(player);
  }

  @WsEventListener(EGameMatchTriggerEvent.QuitMatch)
  quitMatch(@ConnectedPlayer() player: Player) {
    return this.gameMatchEvents.quitMatch(player);
  }
}
