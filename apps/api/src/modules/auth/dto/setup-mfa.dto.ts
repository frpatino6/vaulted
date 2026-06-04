import { IsString, MinLength, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class SetupMfaDto {
  @ApiProperty({ description: 'Current account password for step-up verification' })
  @IsString()
  @MinLength(1)
  @MaxLength(128)
  password!: string;
}
