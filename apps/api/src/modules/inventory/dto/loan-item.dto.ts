import { Type } from 'class-transformer';
import {
  IsDate,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class LoanItemDto {
  @ApiProperty({ description: 'Borrower name', example: 'John Doe', maxLength: 255 })
  @IsString()
  @MaxLength(255)
  borrowerName!: string;

  @ApiProperty({ description: 'Borrower contact email/phone', example: 'john@example.com', maxLength: 255 })
  @IsString()
  @MaxLength(255)
  borrowerContact!: string;

  @ApiProperty({ description: 'Expected return date', example: '2025-03-15T00:00:00Z' })
  @Type(() => Date)
  @IsDate()
  expectedReturnDate!: Date;

  @ApiPropertyOptional({ description: 'Loan notes', example: 'Borrowed for event', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
