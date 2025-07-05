import { IsString } from 'class-validator';

export class SendPublicMessageDto {
  @IsString()
  message: string;
}
