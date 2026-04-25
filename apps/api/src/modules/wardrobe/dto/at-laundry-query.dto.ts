import { Type } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class AtLaundryQueryDto {
  @ApiPropertyOptional({
    description:
      'Number of days after which an item is considered overdue at the dry cleaner',
    default: 7,
    minimum: 1,
    maximum: 365,
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(365)
  thresholdDays?: number;
}
