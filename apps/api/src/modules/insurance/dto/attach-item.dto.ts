import { IsMongoId, IsNumber, IsOptional, IsPositive, IsString, Length } from 'class-validator';

export class AttachItemDto {
  @IsMongoId()
  itemId!: string;

  @IsNumber()
  @IsPositive()
  coveredValue!: number;

  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;
}
