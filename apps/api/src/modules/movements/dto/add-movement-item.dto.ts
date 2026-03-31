import { IsNotEmpty, IsString } from 'class-validator';

export class AddMovementItemDto {
  @IsString()
  @IsNotEmpty()
  itemId!: string;
}
