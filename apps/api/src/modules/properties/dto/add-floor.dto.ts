import { IsString, MaxLength } from 'class-validator';

export class AddFloorDto {
  @IsString()
  @MaxLength(120)
  name!: string;
}
