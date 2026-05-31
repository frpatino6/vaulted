import { IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

export class CompleteStepDto {
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  note?: string;

  @IsOptional()
  @IsUrl({ require_tld: false })
  @MaxLength(2000)
  completionPhotoUrl?: string;
}
