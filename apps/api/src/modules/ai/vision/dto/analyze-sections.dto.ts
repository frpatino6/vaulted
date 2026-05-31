import { IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

const ALLOWED_IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'] as const;

export class AnalyzeSectionsDto {
  @ApiPropertyOptional({ description: 'Image URL or storage key', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  imageUrl?: string;

  @ApiPropertyOptional({ description: 'Base64-encoded image data (max ~7.5 MB decoded)', maxLength: 10_485_760 })
  @IsOptional()
  @IsString()
  @MaxLength(10_485_760)
  imageData?: string;

  @ApiPropertyOptional({ description: 'MIME type when using imageData', example: 'image/jpeg', enum: ALLOWED_IMAGE_MIME_TYPES })
  @IsOptional()
  @IsIn([...ALLOWED_IMAGE_MIME_TYPES])
  mimeType?: string;
}

export interface BoundingBox {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface DetectedSection {
  code: string;
  name: string;
  type: 'drawer' | 'cabinet' | 'shelf' | 'rack' | 'safe' | 'compartment' | 'other';
  row: number;
  column: string;
  notes?: string;
  boundingBox?: BoundingBox;
}

export interface AnalyzeSectionsResult {
  sections: DetectedSection[];
  confidence: number;
  furnitureDescription: string;
}
