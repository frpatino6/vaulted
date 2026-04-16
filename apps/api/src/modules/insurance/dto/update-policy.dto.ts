import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  Length,
  Min,
} from 'class-validator';
import { CoverageType, PolicyStatus } from '../entities/insurance-policy.entity';

export class UpdatePolicyDto {
  @IsOptional()
  @IsString()
  @Length(1, 255)
  provider?: string;

  @IsOptional()
  @IsString()
  @Length(1, 100)
  policyNumber?: string;

  @IsOptional()
  @IsEnum(['all-risk', 'named-peril', 'liability', 'scheduled'])
  coverageType?: CoverageType;

  @IsOptional()
  @IsNumber()
  @IsPositive()
  totalCoverageAmount?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  premium?: number;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  expiresAt?: string;

  @IsOptional()
  @IsEnum(['active', 'expired', 'cancelled'])
  status?: PolicyStatus;

  @IsOptional()
  @IsString()
  notes?: string;
}
