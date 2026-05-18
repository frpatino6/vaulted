import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  IsDateString,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { MovementType } from '../schemas/movement.schema';

export class CreateMovementDto {
  @ApiProperty({ description: 'Movement operation type', enum: MovementType, example: 'move' })
  @IsEnum(MovementType)
  operationType!: MovementType;

  @ApiProperty({ description: 'Movement title', example: 'Move to new residence', maxLength: 120 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  title!: string;

  @ApiPropertyOptional({ description: 'Movement description', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({ description: 'Destination address', maxLength: 200 })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  destination?: string;

  @ApiPropertyOptional({ description: 'Destination property ID' })
  @IsOptional()
  @IsString()
  destinationPropertyId?: string;

  @ApiPropertyOptional({ description: 'Destination room ID' })
  @IsOptional()
  @IsString()
  destinationRoomId?: string;

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

  @ApiPropertyOptional({ description: 'Due date', example: '2025-03-01' })
  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @ApiPropertyOptional({ description: 'Notes', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;

  @ApiPropertyOptional({ description: 'Property ID' })
  @IsOptional()
  @IsString()
  propertyId?: string;
}
