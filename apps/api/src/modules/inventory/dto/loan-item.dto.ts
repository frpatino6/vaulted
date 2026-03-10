import { Type } from 'class-transformer';
import {
  IsDate,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class LoanItemDto {
  @IsString()
  @MaxLength(255)
  borrowerName!: string;

  @IsString()
  @MaxLength(255)
  borrowerContact!: string;

  @Type(() => Date)
  @IsDate()
  expectedReturnDate!: Date;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
