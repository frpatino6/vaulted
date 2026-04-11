import { IsEmail, IsString, Matches, MinLength, MaxLength } from 'class-validator';

export class RegisterDto {
  @IsString()
  @MinLength(2)
  @MaxLength(255)
  tenantName!: string;

  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(12)
  @MaxLength(128)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&_\-#^])[A-Za-z\d@$!%*?&_\-#^]{12,128}$/, {
    message: 'Password must contain uppercase, lowercase, number, and special character (@$!%*?&_-#^)',
  })
  password!: string;
}
