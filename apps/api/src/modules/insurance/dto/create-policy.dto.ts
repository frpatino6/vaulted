import {
  IsDateString,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  Length,
  Min,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CoverageType } from '../entities/insurance-policy.entity';

export class CreatePolicyDto {
  @ApiProperty({ description: 'Insurance provider name', example: 'Chubb', maxLength: 255 })
  @IsString()
  @IsNotEmpty()
  @Length(1, 255)
  provider!: string;

  @ApiProperty({ description: 'Policy number', example: 'POL-2025-001', maxLength: 100 })
  @IsString()
  @IsNotEmpty()
  @Length(1, 100)
  policyNumber!: string;

  @ApiProperty({ description: 'Coverage type', enum: ['all-risk', 'named-peril', 'liability', 'scheduled'], example: 'all-risk' })
  @IsEnum(['all-risk', 'named-peril', 'liability', 'scheduled'])
  coverageType!: CoverageType;

  @ApiProperty({ description: 'Total coverage amount', example: 500000 })
  @IsNumber()
  @IsPositive()
  totalCoverageAmount!: number;

  @ApiPropertyOptional({ description: 'Premium amount', example: 2500 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  premium?: number;

  @ApiPropertyOptional({ description: 'Currency code', example: 'USD', maxLength: 3 })
  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @ApiProperty({ description: 'Policy start date', example: '2025-01-01' })
  @IsDateString()
  startDate!: string;

  @ApiProperty({ description: 'Policy expiration date', example: '2026-01-01' })
  @IsDateString()
  expiresAt!: string;

  @ApiPropertyOptional({ description: 'Policy notes', example: 'Premium jewelry policy' })
  @IsOptional()
  @IsString()
  notes?: string;
}
