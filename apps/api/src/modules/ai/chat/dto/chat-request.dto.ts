import { IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ChatRequestDto {
  @ApiProperty({ description: 'User query', example: 'What items do I have in the living room?', maxLength: 2000 })
  @IsString()
  @MaxLength(2000)
  query!: string;

  @ApiPropertyOptional({ description: 'Session ID for conversation continuity' })
  @IsOptional()
  @IsString()
  sessionId?: string;

  @ApiPropertyOptional({ description: 'Filter by property ID' })
  @IsOptional()
  @IsString()
  propertyId?: string;
}
