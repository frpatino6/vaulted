import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsMongoId,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export enum WardrobeSeason {
  SPRING_SUMMER = 'spring_summer',
  FALL_WINTER = 'fall_winter',
  ALL_SEASON = 'all_season',
}

export class CreateOutfitDto {
  @IsString()
  @MaxLength(255)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @IsArray()
  @ArrayMaxSize(100)
  @IsMongoId({ each: true })
  itemIds!: string[];

  @IsOptional()
  @IsEnum(WardrobeSeason)
  season?: WardrobeSeason;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  occasion?: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(10)
  @IsString({ each: true })
  photos?: string[];
}
