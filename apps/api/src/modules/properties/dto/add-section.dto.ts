import { IsEnum, IsNumber, IsOptional, IsString, Max, MaxLength, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export type SectionType = 'drawer' | 'cabinet' | 'shelf' | 'rack' | 'safe' | 'compartment' | 'other';

export class BoundingBoxDto {
  @ApiProperty({ description: 'Normalized X (0–1)', example: 0.1, minimum: 0, maximum: 1 })
  @IsNumber() @Min(0) @Max(1) x!: number;

  @ApiProperty({ description: 'Normalized Y (0–1)', example: 0.2, minimum: 0, maximum: 1 })
  @IsNumber() @Min(0) @Max(1) y!: number;

  @ApiProperty({ description: 'Normalized width (0–1)', example: 0.3, minimum: 0, maximum: 1 })
  @IsNumber() @Min(0) @Max(1) width!: number;

  @ApiProperty({ description: 'Normalized height (0–1)', example: 0.4, minimum: 0, maximum: 1 })
  @IsNumber() @Min(0) @Max(1) height!: number;
}

export class AddSectionDto {
  @ApiProperty({ description: 'Section code', example: 'S001', maxLength: 10 })
  @IsString()
  @MaxLength(10)
  code!: string;

  @ApiProperty({ description: 'Section name', example: 'Safe Deposit Box', maxLength: 100 })
  @IsString()
  @MaxLength(100)
  name!: string;

  @ApiProperty({ description: 'Section type', enum: ['drawer', 'cabinet', 'shelf', 'rack', 'safe', 'compartment', 'other'], example: 'safe' })
  @IsEnum(['drawer', 'cabinet', 'shelf', 'rack', 'safe', 'compartment', 'other'])
  type!: SectionType;

  @ApiPropertyOptional({ description: 'Section notes', example: 'Contains jewelry', maxLength: 255 })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  notes?: string;

  @ApiPropertyOptional({ description: 'Section photo URL or storage key' })
  @IsOptional()
  @IsString()
  photo?: string;

  @ApiPropertyOptional({ description: 'Furniture name', example: 'Master closet', maxLength: 100 })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  furnitureName?: string;

  @ApiPropertyOptional({ description: 'Bounding box from AI section scan' })
  @IsOptional()
  @ValidateNested()
  @Type(() => BoundingBoxDto)
  boundingBox?: BoundingBoxDto;
}
