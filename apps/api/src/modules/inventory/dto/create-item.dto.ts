import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDate,
  IsEnum,
  IsInt,
  IsNumber,
  IsObject,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

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
  @ApiPropertyOptional({ description: 'Original purchase price', example: 1500.00 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  purchasePrice?: number;

  @ApiPropertyOptional({ description: 'Date of purchase', example: '2024-01-15T00:00:00Z' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  purchaseDate?: Date;

  @ApiPropertyOptional({ description: 'Current appraised value', example: 2000.00 })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  currentValue?: number;

  @ApiPropertyOptional({ description: 'Currency code', example: 'USD', maxLength: 8 })
  @IsOptional()
  @IsString()
  @MaxLength(8)
  currency?: string;

  @ApiPropertyOptional({ description: 'Last appraisal date', example: '2025-01-15T00:00:00Z' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  lastAppraisalDate?: Date;
}

export class CreateItemDto {
  @ApiProperty({ description: 'Property ID', example: '64f1b2c3d4e5f6789012abcd' })
  @IsString()
  propertyId!: string;

  @ApiPropertyOptional({ description: 'Room ID', example: '64f1b2c3d4e5f6789012abce' })
  @IsOptional()
  @IsString()
  roomId?: string;

  @ApiProperty({ description: 'Item name', example: 'Vintage Rolex Submariner', maxLength: 255 })
  @IsString()
  @MaxLength(255)
  name!: string;

  @ApiProperty({ description: 'Item category', enum: ItemCategory, example: 'other' })
  @IsEnum(ItemCategory)
  category!: ItemCategory;

  @ApiPropertyOptional({ description: 'Item subcategory', example: 'watches', maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  subcategory?: string;

  @ApiPropertyOptional({ description: 'Custom attributes as JSON', example: { material: 'gold' } })
  @IsOptional()
  @IsObject()
  attributes?: Record<string, unknown>;

  @ApiPropertyOptional({ description: 'Valuation information' })
  @IsOptional()
  @ValidateNested()
  @Type(() => ItemValuationDto)
  valuation?: ItemValuationDto;

  @ApiPropertyOptional({ description: 'Item status', enum: ItemStatus, example: 'active' })
  @IsOptional()
  @IsEnum(ItemStatus)
  status?: ItemStatus;

  @ApiPropertyOptional({ description: 'Photo URLs', example: ['https://example.com/photo1.jpg'], maxItems: 20 })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsUrl({ require_tld: false }, { each: true })
  photos?: string[];

  @ApiPropertyOptional({ description: 'Document URLs', example: ['https://example.com/doc1.pdf'], maxItems: 20 })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  documents?: string[];

  @ApiPropertyOptional({ description: 'Tags for search', example: ['insurance', 'valuable'], maxItems: 20 })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsString({ each: true })
  tags?: string[];

  @ApiPropertyOptional({ description: 'Serial number', example: 'SN123456789', maxLength: 255 })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  serialNumber?: string;

  @ApiPropertyOptional({ description: 'Detailed location description', example: 'Safe deposit box', maxLength: 255 })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  locationDetail?: string;

  @ApiPropertyOptional({ description: 'Section ID', example: '64f1b2c3d4e5f6789012abcf' })
  @IsOptional()
  @IsString()
  sectionId?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Type(() => Number)
  quantity?: number;
}
