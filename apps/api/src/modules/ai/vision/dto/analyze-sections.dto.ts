import { IsOptional, IsString } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class AnalyzeSectionsDto {
  @ApiPropertyOptional({ description: 'Image URL or storage key' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ description: 'Base64-encoded image data' })
  @IsOptional()
  @IsString()
  imageData?: string;

  @ApiPropertyOptional({ description: 'MIME type when using imageData', example: 'image/jpeg' })
  @IsOptional()
  @IsString()
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
