import { IsOptional, IsString, MaxLength } from 'class-validator';

export class ChatRequestDto {
  @IsString()
  @MaxLength(2000)
  query!: string;

  @IsOptional()
  @IsString()
  sessionId?: string;

  @IsOptional()
  @IsString()
  propertyId?: string;
}
