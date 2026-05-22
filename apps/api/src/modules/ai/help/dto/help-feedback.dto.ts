import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class HelpFeedbackDto {
  @ApiProperty({ description: 'Session ID of the conversation' })
  @IsString()
  @IsNotEmpty()
  sessionId!: string;

  @ApiProperty({ description: 'Zero-based index of the assistant message being rated' })
  @IsNumber()
  @Min(0)
  @Max(100)
  messageIndex!: number;

  @ApiProperty({ description: 'Whether the answer was helpful' })
  @IsBoolean()
  helpful!: boolean;

  @ApiPropertyOptional({ description: 'Optional comment explaining the rating', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string;
}
