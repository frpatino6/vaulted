import { PartialType, ApiPropertyOptional } from '@nestjs/swagger';
import { CreateHouseholdMemberDto } from './create-household-member.dto';
import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateHouseholdMemberDto extends PartialType(
  CreateHouseholdMemberDto,
) {
  @ApiPropertyOptional({ description: 'Whether the member is active', example: true })
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
