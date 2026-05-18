import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CompleteStepDto {
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  note?: string;

  @IsOptional()
  @IsString()
  completionPhotoUrl?: string;
}
