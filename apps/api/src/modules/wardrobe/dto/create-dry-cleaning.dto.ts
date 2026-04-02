import { Type } from 'class-transformer';
import {
  IsDate,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class CreateDryCleaningDto {
  @Type(() => Date)
  @IsDate()
  sentDate!: Date;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  cleanerName?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  cost?: number;

  @IsOptional()
  @IsString()
  @MaxLength(8)
  currency?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  notes?: string;
}
