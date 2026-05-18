import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateNotificationPreferenceDto {
  @IsOptional()
  @IsBoolean()
  pushEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  emailEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  dryCleaningOverdue?: boolean;

  @IsOptional()
  @IsBoolean()
  maintenanceDue?: boolean;

  @IsOptional()
  @IsBoolean()
  itemAdded?: boolean;
}
