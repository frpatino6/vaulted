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

export enum PropertyType {
  PRIMARY = 'primary',
  VACATION = 'vacation',
  RENTAL = 'rental',
}

export class PropertyAddressDto {
  @IsString()
  @MaxLength(255)
  street!: string;

  @IsString()
  @MaxLength(120)
  city!: string;

  @IsString()
  @MaxLength(120)
  state!: string;

  @IsString()
  @MaxLength(32)
  zip!: string;

  @IsString()
  @MaxLength(120)
  country!: string;
}

export class CreateRoomDto {
  @IsString()
  @MaxLength(120)
  roomId!: string;

  @IsString()
  @MaxLength(120)
  name!: string;

  @IsString()
  @MaxLength(120)
  type!: string;
}

export class CreateFloorDto {
  @IsString()
  @MaxLength(120)
  floorId!: string;

  @IsString()
  @MaxLength(120)
  name!: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateRoomDto)
  rooms!: CreateRoomDto[];
}

export class CreatePropertyDto {
  @IsString()
  @MaxLength(255)
  name!: string;

  @IsEnum(PropertyType)
  type!: PropertyType;

  @ValidateNested()
  @Type(() => PropertyAddressDto)
  address!: PropertyAddressDto;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateFloorDto)
  floors?: CreateFloorDto[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(50)
  @IsString({ each: true })
  photos?: string[];
}
