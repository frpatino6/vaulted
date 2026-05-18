import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsDate,
  IsEmail,
  IsEnum,
  IsOptional,
  IsString,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Role } from '../../../common/enums/role.enum';

export class InviteUserDto {
  @ApiProperty({ description: 'Invitee email address', example: 'manager@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ description: 'Assigned role', enum: Role, example: Role.MANAGER })
  @IsEnum(Role)
  role!: Role;

  @ApiProperty({ description: 'Property IDs the user can access', example: ['64f1b2c3d4e5f6789012abcd'] })
  @IsArray()
  @ArrayMaxSize(100)
  @IsString({ each: true })
  propertyIds!: string[];

  @ApiPropertyOptional({ description: 'Guest access expiration date' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  expiresAt?: Date;
}
