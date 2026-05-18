import { IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateRoomDto {
  @ApiPropertyOptional({ description: 'Room name', example: 'Master Bedroom', maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  name?: string;

  @ApiPropertyOptional({ description: 'Room type', example: 'bedroom', maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  type?: string;
}
