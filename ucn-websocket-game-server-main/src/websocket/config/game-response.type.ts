export type GameResponse<T = object> = {
  msg: string;
  data?: T;
};
