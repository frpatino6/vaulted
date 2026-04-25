import { PartialType } from '@nestjs/mapped-types';
import { CreateHouseholdMemberDto } from './create-household-member.dto';
import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateHouseholdMemberDto extends PartialType(
  CreateHouseholdMemberDto,
) {
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
