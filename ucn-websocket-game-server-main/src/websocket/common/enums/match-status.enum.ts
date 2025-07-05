export enum EMatchStatus {
  /** The sender player is waiting for the destinator to approve the match request */
  Requested = 'REQUESTED',
  /** Both players have accepted the match and the game room is creating */
  Created = 'CREATED',
  /** The game room is created and is waiting for the player on the other URL */
  WaitingPlayers = 'WAITING_PLAYERS',
  /** Players are synchronizing to have the same start time */
  Synchronizing = 'SYNCHRONIZING',
  /** Players are playing the match */
  Playing = 'PLAYING',
  /** Players have finished the match */
  Finished = 'FINISHED',
}
