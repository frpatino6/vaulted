import { IsEnum, IsOptional, IsString, MaxLength, ValidateIf } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { SectionType } from './add-section.dto';

export class UpdateSectionDto {
  @ApiPropertyOptional({ description: 'Section code', example: 'S001', maxLength: 10 })
  @IsOptional()
  @IsString()
  @MaxLength(10)
  code?: string;

  @ApiPropertyOptional({ description: 'Section name', example: 'Safe Deposit Box', maxLength: 100 })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @ApiPropertyOptional({ description: 'Section type', enum: ['drawer', 'cabinet', 'shelf', 'rack', 'safe', 'compartment', 'other'], example: 'safe' })
  @IsOptional()
  @IsEnum(['drawer', 'cabinet', 'shelf', 'rack', 'safe', 'compartment', 'other'])
  type?: SectionType;

  @ApiPropertyOptional({ description: 'Section notes', example: 'Contains jewelry', maxLength: 255 })
  @IsOptional()
  @IsString()
  @MaxLength(255)
  notes?: string;

  @ApiPropertyOptional({ description: 'Section photo URL or storage key; pass null to clear' })
  @IsOptional()
  @ValidateIf((o: UpdateSectionDto) => o.photo !== null)
  @IsString()
  photo?: string | null;
}
