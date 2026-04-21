import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum PropertyType {
  PRIMARY = 'primary',
  VACATION = 'vacation',
  RENTAL = 'rental',
}

export class PropertyAddressDto {
  @ApiProperty({ description: 'Street address', example: '123 Main Street', maxLength: 255 })
  @IsString()
  @MaxLength(255)
  street!: string;

  @ApiProperty({ description: 'City', example: 'Beverly Hills', maxLength: 120 })
  @IsString()
  @MaxLength(120)
  city!: string;

  @ApiProperty({ description: 'State/Province', example: 'CA', maxLength: 120 })
  @IsString()
  @MaxLength(120)
  state!: string;

  @ApiProperty({ description: 'ZIP/Postal code', example: '90210', maxLength: 32 })
  @IsString()
  @MaxLength(32)
  zip!: string;

  @ApiProperty({ description: 'Country', example: 'USA', maxLength: 120 })
  @IsString()
  @MaxLength(120)
  country!: string;
}

export class CreateRoomDto {
  @ApiProperty({ description: 'Room ID', example: 'room_001' })
  @IsString()
  @MaxLength(120)
  roomId!: string;

  @ApiProperty({ description: 'Room name', example: 'Master Bedroom', maxLength: 120 })
  @IsString()
  @MaxLength(120)
  name!: string;

  @ApiProperty({ description: 'Room type', example: 'bedroom', maxLength: 120 })
  @IsString()
  @MaxLength(120)
  type!: string;
}

export class CreateFloorDto {
  @ApiProperty({ description: 'Floor ID', example: 'floor_1' })
  @IsString()
  @MaxLength(120)
  floorId!: string;

  @ApiProperty({ description: 'Floor name', example: 'First Floor', maxLength: 120 })
  @IsString()
  @MaxLength(120)
  name!: string;

  @ApiProperty({ description: 'Rooms on this floor', type: [CreateRoomDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateRoomDto)
  rooms!: CreateRoomDto[];
}

export class CreatePropertyDto {
  @ApiProperty({ description: 'Property name', example: 'Main Residence', maxLength: 255 })
  @IsString()
  @MaxLength(255)
  name!: string;

  @ApiProperty({ description: 'Property type', enum: PropertyType, example: 'primary' })
  @IsEnum(PropertyType)
  type!: PropertyType;

  @ApiProperty({ description: 'Property address', type: PropertyAddressDto })
  @ValidateNested()
  @Type(() => PropertyAddressDto)
  address!: PropertyAddressDto;

  @ApiPropertyOptional({ description: 'Floors and rooms', type: [CreateFloorDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateFloorDto)
  floors?: CreateFloorDto[];

  @ApiPropertyOptional({ description: 'Photo URLs', example: ['https://example.com/house.jpg'], maxItems: 50 })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  photos?: string[];
}
