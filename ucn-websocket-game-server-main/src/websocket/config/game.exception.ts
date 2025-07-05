export class GameException extends Error {
  static throwException(message: string, data: object = null) {
    throw new GameException(message, data);
  }

  constructor(
    public gameMessage: string,
    public data: object,
  ) {
    super(gameMessage);
  }
}
