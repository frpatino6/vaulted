import { IsNotEmpty, IsString, Matches, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AcceptInviteDto {
  @ApiProperty({ description: 'Invitation token from email', example: 'invite_abc123...' })
  @IsString()
  @IsNotEmpty()
  token!: string;

  @ApiProperty({ description: 'Password with uppercase, lowercase, number, special char', example: 'SecureP@ss123!', minLength: 12, maxLength: 128 })
  @IsString()
  @MinLength(12)
  @MaxLength(128)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_\-#^])/, {
    message: 'Password must contain uppercase, lowercase, number, and special character',
  })
  password!: string;
}
