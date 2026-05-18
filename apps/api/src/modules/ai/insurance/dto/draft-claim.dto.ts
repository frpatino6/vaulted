import {
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class DraftClaimDto {
  @ApiProperty({ description: 'Insurance policy ID', example: '64f1b2c3d4e5f6789012abcd' })
  @IsUUID()
  policyId!: string;

  @ApiPropertyOptional({ description: 'Related item ID (optional)', example: '64f1b2c3d4e5f6789012abce' })
  @IsOptional()
  @IsString()
  itemId?: string;

  @ApiProperty({ description: 'Incident description', example: 'Water damage to basement furniture', maxLength: 2000 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(2000)
  incidentDescription!: string;
}
