import { IsString, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AddFloorDto {
  @ApiProperty({ description: 'Floor name', example: 'First Floor', maxLength: 120 })
  @IsString()
  @MaxLength(120)
  name!: string;
}
