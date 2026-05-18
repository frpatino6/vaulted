import { IsEnum, IsNotEmpty, IsString } from 'class-validator';
import { DevicePlatform } from '../entities/user-device-token.entity';

export class RegisterDeviceTokenDto {
  @IsString()
  @IsNotEmpty()
  token!: string;

  @IsEnum(['ios', 'android', 'web'] as const)
  platform!: DevicePlatform;
}
