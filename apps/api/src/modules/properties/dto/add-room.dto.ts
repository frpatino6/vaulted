import { IsString, MaxLength } from 'class-validator';

export class AddRoomDto {
  @IsString()
  @MaxLength(120)
  name!: string;

  @IsString()
  @MaxLength(120)
  type!: string;
}
