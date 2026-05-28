import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsNotEmpty, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export const VALID_HELP_SCREENS = [
  'dashboard',
  'inventory',
  'item_detail',
  'add_item',
  'movements',
  'wardrobe',
  'maintenance',
  'insurance',
  'properties',
  'users',
  'ai_scan',
  'ai_section_scan',
  'ai_chat',
  'reports',
  'settings',
  'orchestrator',
  'notifications',
  'household_members',
] as const;

export type HelpScreen = (typeof VALID_HELP_SCREENS)[number];

export class HelpRequestDto {
  @ApiProperty({
    description: 'User question about how to use the app',
    minLength: 1,
    maxLength: 1000,
  })
  @IsString()
  @IsNotEmpty()
  @MinLength(1)
  @MaxLength(1000)
  query!: string;

  @ApiPropertyOptional({ description: 'Session ID for multi-turn conversation' })
  @IsOptional()
  @IsString()
  sessionId?: string;

  @ApiPropertyOptional({
    description: 'Current screen name for contextual help',
    example: 'inventory',
    enum: VALID_HELP_SCREENS,
  })
  @IsOptional()
  @IsIn([...VALID_HELP_SCREENS])
  currentScreen?: HelpScreen;
}
