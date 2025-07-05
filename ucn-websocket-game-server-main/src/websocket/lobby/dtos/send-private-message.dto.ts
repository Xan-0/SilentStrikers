import { IsString, IsUUID } from 'class-validator';

export class SendPrivateMessageDto {
  @IsUUID()
  playerId: string;

  @IsString()
  message: string;
}
