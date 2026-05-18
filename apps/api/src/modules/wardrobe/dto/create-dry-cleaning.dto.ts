import { Type } from 'class-transformer';
import {
  IsDate,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateDryCleaningDto {
  @ApiProperty({ description: 'Date sent for cleaning', example: '2025-01-15T00:00:00Z' })
  @Type(() => Date)
  @IsDate()
  sentDate!: Date;

  @ApiPropertyOptional({ description: 'Cleaner name', example: 'Prestige Cleaners', maxLength: 255 })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  cleanerName?: string;

  @ApiPropertyOptional({ description: 'Cleaning cost', example: 25.00 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  cost?: number;

  @ApiPropertyOptional({ description: 'Currency code', example: 'USD', maxLength: 8 })
  @IsOptional()
  @IsString()
  @MaxLength(8)
  currency?: string;

  @ApiPropertyOptional({ description: 'Notes', example: 'Handle with care', maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
