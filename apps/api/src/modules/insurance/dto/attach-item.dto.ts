import { IsMongoId, IsNumber, IsOptional, IsPositive, IsString, Length } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AttachItemDto {
  @ApiProperty({ description: 'Inventory item ID', example: '64f1b2c3d4e5f6789012abcd' })
  @IsMongoId()
  itemId!: string;

  @ApiProperty({ description: 'Covered value for this item', example: 50000 })
  @IsNumber()
  @IsPositive()
  coveredValue!: number;

  @ApiPropertyOptional({ description: 'Currency code', example: 'USD', maxLength: 3 })
  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;
}
