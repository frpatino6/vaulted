import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsMongoId,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum WardrobeSeason {
  SPRING_SUMMER = 'spring_summer',
  FALL_WINTER = 'fall_winter',
  ALL_SEASON = 'all_season',
}

export class CreateOutfitDto {
  @ApiProperty({ description: 'Outfit name', example: 'Summer Business', maxLength: 255 })
  @IsString()
  @MaxLength(255)
  name!: string;

  @ApiPropertyOptional({ description: 'Outfit description', example: 'Formal summer business attire', maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @ApiProperty({ description: 'Array of inventory item IDs', example: ['64f1b2c3d4e5f6789012abcd'], maxItems: 100 })
  @IsArray()
  @ArrayMaxSize(100)
  @IsMongoId({ each: true })
  itemIds!: string[];

  @ApiPropertyOptional({ description: 'Season', enum: WardrobeSeason, example: 'spring_summer' })
  @IsOptional()
  @IsEnum(WardrobeSeason)
  season?: WardrobeSeason;

  @ApiPropertyOptional({ description: 'Occasion', example: 'business_meeting', maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  occasion?: string;

  @ApiPropertyOptional({ description: 'Household member owner ID', maxLength: 64 })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  ownerMemberId?: string;

  @ApiPropertyOptional({ description: 'Photo URLs', example: ['https://example.com/outfit.jpg'], maxItems: 10 })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  photos?: string[];
}
