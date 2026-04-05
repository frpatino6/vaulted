import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  IsDateString,
} from 'class-validator';
import { MovementType } from '../schemas/movement.schema';

export class CreateMovementDto {
  @IsEnum(MovementType)
  operationType!: MovementType;

  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  title!: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  destination?: string;

  @IsOptional()
  @IsString()
  destinationPropertyId?: string;

  @IsOptional()
  @IsString()
  destinationRoomId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  destinationPropertyName?: string;

  @IsOptional()
  @IsString()
  @MaxLength(200)
  destinationRoomName?: string;

  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;

  @IsOptional()
  @IsString()
  propertyId?: string;
}
