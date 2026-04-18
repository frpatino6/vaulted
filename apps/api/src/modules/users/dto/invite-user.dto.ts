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
import { Role } from '../../../common/enums/role.enum';

export class InviteUserDto {
  @IsEmail()
  email!: string;

  @IsEnum(Role)
  role!: Role;

  @IsArray()
  @ArrayMaxSize(100)
  @IsString({ each: true })
  propertyIds!: string[];

  @IsOptional()
  @Type(() => Date)
  @IsDate()
  expiresAt?: Date;
}
