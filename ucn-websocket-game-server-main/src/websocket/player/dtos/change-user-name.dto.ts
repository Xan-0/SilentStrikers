import { IsString } from 'class-validator';

export class ChangeUserNameDto {
  @IsString()
  name: string;
}
