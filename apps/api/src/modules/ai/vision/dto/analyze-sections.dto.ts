import { IsString } from 'class-validator';

export class AnalyzeSectionsDto {
  @IsString()
  imageUrl!: string;
}

export interface DetectedSection {
  code: string;
  name: string;
  type: 'drawer' | 'cabinet' | 'shelf' | 'rack' | 'safe' | 'compartment' | 'other';
  row: number;
  column: string;
  notes?: string;
}

export interface AnalyzeSectionsResult {
  sections: DetectedSection[];
  confidence: number;
  furnitureDescription: string;
}
