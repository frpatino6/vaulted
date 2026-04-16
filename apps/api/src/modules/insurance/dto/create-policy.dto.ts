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
import { CoverageType } from '../entities/insurance-policy.entity';

export class CreatePolicyDto {
  @IsString()
  @IsNotEmpty()
  @Length(1, 255)
  provider!: string;

  @IsString()
  @IsNotEmpty()
  @Length(1, 100)
  policyNumber!: string;

  @IsEnum(['all-risk', 'named-peril', 'liability', 'scheduled'])
  coverageType!: CoverageType;

  @IsNumber()
  @IsPositive()
  totalCoverageAmount!: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  premium?: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @IsDateString()
  startDate!: string;

  @IsDateString()
  expiresAt!: string;

  @IsOptional()
  @IsString()
  notes?: string;
}
