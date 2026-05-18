import {
  IsEmail,
  IsEnum,
  IsArray,
  IsString,
  IsOptional,
  MinLength,
  MaxLength,
  ArrayMaxSize,
} from 'class-validator';
import { Role } from '../../../common/enums/role.enum';

export class CreateUserDirectDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(64)
  password!: string;

  @IsEnum(Role)
  role!: Role;

  @IsArray()
  @ArrayMaxSize(100)
  @IsString({ each: true })
  @IsOptional()
  propertyIds?: string[];
}
