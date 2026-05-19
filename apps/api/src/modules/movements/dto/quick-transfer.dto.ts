import {
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class QuickTransferDto {
  @ApiProperty({ description: 'Item ID to transfer' })
  @IsString()
  @IsNotEmpty()
  itemId!: string;

  @ApiProperty({ description: 'Transfer title', maxLength: 120 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  title!: string;

  @ApiProperty({ description: 'Destination property ID' })
  @IsString()
  @IsNotEmpty()
  destinationPropertyId!: string;

  @ApiProperty({ description: 'Destination room ID' })
  @IsString()
  @IsNotEmpty()
  destinationRoomId!: string;

  @ApiPropertyOptional({ description: 'Destination property name', maxLength: 200 })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  destinationPropertyName?: string;

  @ApiPropertyOptional({ description: 'Destination room name', maxLength: 200 })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  destinationRoomName?: string;

  @ApiPropertyOptional({ description: 'Optional notes', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
