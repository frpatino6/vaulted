import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

export type SectionType = 'drawer' | 'cabinet' | 'shelf' | 'rack' | 'safe' | 'compartment' | 'other';

export class AddSectionDto {
  @IsString()
  @MaxLength(10)
  code!: string;

  @IsString()
  @MaxLength(100)
  name!: string;

  @IsEnum(['drawer', 'cabinet', 'shelf', 'rack', 'safe', 'compartment', 'other'])
  type!: SectionType;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  notes?: string;
}
