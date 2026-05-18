import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateMaintenanceDto {
  @ApiPropertyOptional({ description: 'Maintenance task title', example: 'Replace HVAC filter', maxLength: 200 })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  title?: string;

  @ApiPropertyOptional({ description: 'Task description', example: 'Replace main HVAC filter', maxLength: 1000 })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  description?: string;

  @ApiPropertyOptional({ description: 'Scheduled date', example: '2025-02-01' })
  @IsOptional()
  @IsDateString()
  scheduledDate?: string;

  @ApiPropertyOptional({ description: 'Completed date', example: '2025-01-28' })
  @IsOptional()
  @IsDateString()
  completedDate?: string;

  @ApiPropertyOptional({ description: 'Task status', enum: ['pending', 'completed', 'cancelled'], example: 'completed' })
  @IsOptional()
  @IsEnum(['pending', 'completed', 'cancelled'])
  status?: 'pending' | 'completed' | 'cancelled';

  @ApiPropertyOptional({ description: 'Recurrence interval in days', example: 90 })
  @IsOptional()
  @IsNumber()
  @IsPositive()
  @Min(1)
  recurrenceIntervalDays?: number;

  @ApiPropertyOptional({ description: 'Service provider name', example: 'ABC Services', maxLength: 200 })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  providerName?: string;

  @ApiPropertyOptional({ description: 'Provider contact info', example: 'contact@abc.com', maxLength: 200 })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  providerContact?: string;

  @ApiPropertyOptional({ description: 'Service cost', example: 150 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  cost?: number;

  @ApiPropertyOptional({ description: 'Currency code', example: 'USD', maxLength: 3 })
  @IsOptional()
  @IsString()
  @MaxLength(3)
  currency?: string;

  @ApiPropertyOptional({ description: 'Additional notes', example: 'Quarterly service', maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;

  @ApiPropertyOptional({ description: 'Document URLs', example: ['https://example.com/invoice.pdf'] })
  @IsOptional()
  @IsString({ each: true })
  documents?: string[];
}
