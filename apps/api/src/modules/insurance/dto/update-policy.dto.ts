import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  Length,
  MaxLength,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CoverageType } from '../entities/insurance-policy.entity';

export class UpdatePolicyDto {
  @ApiPropertyOptional({ description: 'Insurance provider name', example: 'Chubb', maxLength: 255 })
  @IsOptional()
  @IsString()
  @Length(1, 255)
  provider?: string;

  @ApiPropertyOptional({ description: 'Policy number', example: 'POL-2025-001', maxLength: 100 })
  @IsOptional()
  @IsString()
  @Length(1, 100)
  policyNumber?: string;

  @ApiPropertyOptional({ description: 'Coverage type', enum: ['all-risk', 'named-peril', 'liability', 'scheduled'], example: 'all-risk' })
  @IsOptional()
  @IsEnum(['all-risk', 'named-peril', 'liability', 'scheduled'])
  coverageType?: CoverageType;

  @ApiPropertyOptional({ description: 'Total coverage amount', example: 500000 })
  @IsOptional()
  @IsNumber()
  @IsPositive()
  totalCoverageAmount?: number;

  @ApiPropertyOptional({ description: 'Premium amount', example: 2500 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  premium?: number;

  @ApiPropertyOptional({ description: 'Policy start date', example: '2025-01-01' })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({ description: 'Policy expiration date', example: '2026-01-01' })
  @IsOptional()
  @IsDateString()
  expiresAt?: string;

  @ApiPropertyOptional({ description: 'Policy status', enum: ['active', 'expired', 'cancelled'], example: 'active' })
  @IsOptional()
  @IsEnum(['active', 'expired', 'cancelled'])
  status?: 'active' | 'expired' | 'cancelled';

  @ApiPropertyOptional({ description: 'Policy notes', example: 'Premium jewelry policy', maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
