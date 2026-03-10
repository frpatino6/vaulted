import { IsOptional, IsString, MaxLength } from 'class-validator';

export class MoveItemDto {
  @IsString()
  toPropertyId!: string;

  @IsString()
  toRoomId!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
