import {
  IsAlphanumeric,
  IsInt,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class AddScoreDto {
  @IsString({ message: 'El nombre del jugador debe ser un texto.' })
  @MaxLength(10, {
    message: 'El nombre del jugador no debe superar los 10 caracteres.',
  })
  @IsAlphanumeric('es-ES', {
    message:
      'El nombre del jugador solo puede tener carácteres alfanuméricos (0-9 y A-Z)',
  })
  playerName: string;

  @IsInt({ message: 'El puntaje debe tener un valor numérico entero.' })
  @Min(1, { message: 'El puntaje debe ser mayor o igual a 1.' })
  @Max(999999999, {
    message: 'El puntaje no puede superar el valor de 999.999.999.',
  })
  score: number;
}
