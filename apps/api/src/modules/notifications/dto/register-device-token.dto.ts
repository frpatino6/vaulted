import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsString } from 'class-validator';
import { DevicePlatform } from '../entities/user-device-token.entity';

export class RegisterDeviceTokenDto {
  @ApiProperty({ description: 'FCM device registration token' })
  @IsString()
  @IsNotEmpty()
  token!: string;

  @ApiProperty({
    description: 'Device platform',
    enum: ['ios', 'android', 'web'],
  })
  @IsEnum(['ios', 'android', 'web'] as const)
  platform!: DevicePlatform;
}
