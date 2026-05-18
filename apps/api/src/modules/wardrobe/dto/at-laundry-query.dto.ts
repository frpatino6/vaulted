import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class AtLaundryQueryDto {
  @ApiPropertyOptional({ description: 'Days threshold for overdue laundry', example: 7, minimum: 1, maximum: 365 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  thresholdDays?: number;
}
