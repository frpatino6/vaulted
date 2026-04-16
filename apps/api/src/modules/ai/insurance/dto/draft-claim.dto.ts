import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';

export class DraftClaimDto {
  @IsUUID()
  policyId!: string;

  @IsOptional()
  @IsString()
  itemId?: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  incidentDescription!: string;
}
