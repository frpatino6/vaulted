import { IsBoolean, IsOptional } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateNotificationPreferenceDto {
  @ApiPropertyOptional({ description: 'Enable push notifications', example: true })
  @IsOptional()
  @IsBoolean()
  pushEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Enable email notifications', example: true })
  @IsOptional()
  @IsBoolean()
  emailEnabled?: boolean;

  @ApiPropertyOptional({ description: 'Notify on overdue dry cleaning', example: true })
  @IsOptional()
  @IsBoolean()
  dryCleaningOverdue?: boolean;

  @ApiPropertyOptional({ description: 'Notify on maintenance due', example: true })
  @IsOptional()
  @IsBoolean()
  maintenanceDue?: boolean;

  @ApiPropertyOptional({ description: 'Notify when items are added', example: false })
  @IsOptional()
  @IsBoolean()
  itemAdded?: boolean;

  @IsOptional()
  @IsBoolean()
  orchestratorAssigned?: boolean;

  @IsOptional()
  @IsBoolean()
  orchestratorCompleted?: boolean;
}
