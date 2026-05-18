import { IsDateString, IsOptional, IsString, MaxLength } from 'class-validator';

export class ParseCommandDto {
  @IsString()
  @MaxLength(2000)
  command!: string;

  @IsOptional()
  @IsString()
  propertyId?: string;

  @IsOptional()
  @IsDateString()
  targetDate?: string;
}
