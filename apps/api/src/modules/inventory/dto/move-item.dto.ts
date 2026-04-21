import { IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class MoveItemDto {
  @ApiProperty({ description: 'Target property ID', example: '64f1b2c3d4e5f6789012abcd' })
  @IsString()
  toPropertyId!: string;

  @ApiProperty({ description: 'Target room ID', example: '64f1b2c3d4e5f6789012abce' })
  @IsString()
  toRoomId!: string;

  @ApiPropertyOptional({ description: 'Move notes', example: 'Relocated to safe room', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
