import { IsBoolean, IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateHouseholdMemberDto {
  @ApiProperty({ description: 'Member display name', example: 'Alex', maxLength: 120 })
  @IsString()
  @MaxLength(120)
  name!: string;

  @ApiPropertyOptional({ description: 'Relationship to household', example: 'child', maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  relationship?: string;

  @ApiPropertyOptional({ description: 'Whether the member is a minor', example: false })
  @IsOptional()
  @IsBoolean()
  isMinor?: boolean;

  @ApiPropertyOptional({ description: 'Linked Vaulted user ID', maxLength: 64 })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  linkedUserId?: string;

  @ApiPropertyOptional({ description: 'Additional notes', maxLength: 1000 })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  notes?: string;
}
