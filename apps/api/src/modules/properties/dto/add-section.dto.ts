import { IsEnum, IsNumber, IsOptional, IsString, Max, MaxLength, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type SectionType = 'drawer' | 'cabinet' | 'shelf' | 'rack' | 'safe' | 'compartment' | 'other';

export class BoundingBoxDto {
  @ApiProperty({ description: 'Left edge as a fraction of image width (0–1)', minimum: 0, maximum: 1 })
  @IsNumber()
  @Min(0)
  @Max(1)
  x!: number;

  @ApiProperty({ description: 'Top edge as a fraction of image height (0–1)', minimum: 0, maximum: 1 })
  @IsNumber()
  @Min(0)
  @Max(1)
  y!: number;

  @ApiProperty({ description: 'Width as a fraction of image width (0–1)', minimum: 0, maximum: 1 })
  @IsNumber()
  @Min(0)
  @Max(1)
  width!: number;

  @ApiProperty({ description: 'Height as a fraction of image height (0–1)', minimum: 0, maximum: 1 })
  @IsNumber()
  @Min(0)
  @Max(1)
  height!: number;
}

export class AddSectionDto {
  @ApiProperty({ maxLength: 10 })
  @IsString()
  @MaxLength(10)
  code!: string;

  @ApiProperty({ maxLength: 100 })
  @IsString()
  @MaxLength(100)
  name!: string;

  @ApiProperty({ enum: ['drawer', 'cabinet', 'shelf', 'rack', 'safe', 'compartment', 'other'] })
  @IsEnum(['drawer', 'cabinet', 'shelf', 'rack', 'safe', 'compartment', 'other'])
  type!: SectionType;

  @ApiPropertyOptional({ maxLength: 255 })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  notes?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  photo?: string;

  @ApiPropertyOptional({ type: BoundingBoxDto, description: 'Fractional bounding box (0–1) of the section within a room photo' })
  @IsOptional()
  @ValidateNested()
  @Type(() => BoundingBoxDto)
  boundingBox?: BoundingBoxDto;
}
