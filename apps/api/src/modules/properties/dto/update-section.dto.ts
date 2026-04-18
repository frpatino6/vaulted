import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { SectionType } from './add-section.dto';

export class UpdateSectionDto {
  @IsOptional()
  @IsString()
  @MaxLength(10)
  code?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsEnum(['drawer', 'cabinet', 'shelf', 'rack', 'safe', 'compartment', 'other'])
  type?: SectionType;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  notes?: string;
}
