import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDate,
  IsEnum,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  ValidateNested,
} from 'class-validator';

export enum ItemCategory {
  FURNITURE = 'furniture',
  ART = 'art',
  TECHNOLOGY = 'technology',
  WARDROBE = 'wardrobe',
  VEHICLES = 'vehicles',
  WINE = 'wine',
  SPORTS = 'sports',
  OTHER = 'other',
}

export enum ItemStatus {
  ACTIVE = 'active',
  LOANED = 'loaned',
  REPAIR = 'repair',
  STORAGE = 'storage',
  DISPOSED = 'disposed',
}

export class ItemValuationDto {
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  purchasePrice?: number;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  purchaseDate?: Date;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  currentValue?: number;

  @IsOptional()
  @IsString()
  @MaxLength(8)
  currency?: string;

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  lastAppraisalDate?: Date;
}

export class CreateItemDto {
  @IsString()
  propertyId!: string;

  @IsOptional()
  @IsString()
  roomId?: string;

  @IsString()
  @MaxLength(255)
  name!: string;

  @IsEnum(ItemCategory)
  category!: ItemCategory;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  subcategory?: string;

  @IsOptional()
  @IsObject()
  attributes?: Record<string, unknown>;

  @IsOptional()
  @ValidateNested()
  @Type(() => ItemValuationDto)
  valuation?: ItemValuationDto;

  @IsOptional()
  @IsEnum(ItemStatus)
  status?: ItemStatus;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsUrl({ require_tld: false }, { each: true })
  photos?: string[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  documents?: string[];

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  tags?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(255)
  serialNumber?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  locationDetail?: string;
}
