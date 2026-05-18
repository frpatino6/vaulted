import { IsString, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AddRoomDto {
  @ApiProperty({ description: 'Room name', example: 'Master Bedroom', maxLength: 120 })
  @IsString()
  @MaxLength(120)
  name!: string;

  @ApiProperty({ description: 'Room type', example: 'bedroom', maxLength: 120 })
  @IsString()
  @MaxLength(120)
  type!: string;
}
