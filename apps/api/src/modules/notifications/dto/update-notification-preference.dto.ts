import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateNotificationPreferenceDto {
  @ApiPropertyOptional({ description: 'Enable or disable push notifications globally' })
  @IsOptional()
  @IsBoolean()
  pushEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Enable or disable email notifications globally' })
  @IsOptional()
  @IsBoolean()
  emailEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Notify when dry cleaning items become overdue' })
  @IsOptional()
  @IsBoolean()
  dryCleaningOverdue?: boolean;

  @ApiPropertyOptional({ description: 'Notify when scheduled maintenance is due' })
  @IsOptional()
  @IsBoolean()
  maintenanceDue?: boolean;

  @ApiPropertyOptional({ description: 'Notify when a new item is added to inventory' })
  @IsOptional()
  @IsBoolean()
  itemAdded?: boolean;
}
