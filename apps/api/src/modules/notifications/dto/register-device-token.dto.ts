import { IsEnum, IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { DevicePlatform } from '../entities/user-device-token.entity';

export class RegisterDeviceTokenDto {
  @ApiProperty({ description: 'FCM device token' })
  @IsString()
  @IsNotEmpty()
  token!: string;

  @ApiProperty({ description: 'Device platform', enum: ['ios', 'android', 'web'], example: 'android' })
  @IsEnum(['ios', 'android', 'web'] as const)
  platform!: DevicePlatform;
}
