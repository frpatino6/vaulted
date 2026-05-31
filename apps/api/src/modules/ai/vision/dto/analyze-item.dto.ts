import { ArrayMaxSize, IsArray, IsOptional, IsString, MaxLength, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PropertyRoomDto {
  @ApiProperty({ description: 'Room ID', maxLength: 100 })
  @IsString()
  @MaxLength(100)
  roomId!: string;

  @ApiProperty({ description: 'Room name', example: 'Master Bedroom', maxLength: 200 })
  @IsString()
  @MaxLength(200)
  name!: string;

  @ApiProperty({ description: 'Room type', example: 'bedroom', maxLength: 100 })
  @IsString()
  @MaxLength(100)
  type!: string;
}

export class AnalyzeItemDto {
  @ApiProperty({ description: 'Product image URL or storage key', maxLength: 500 })
  @IsString()
  @MaxLength(500)
  productImageUrl!: string;

  @ApiPropertyOptional({ description: 'Invoice image URL or storage key', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  invoiceImageUrl?: string;

  @ApiPropertyOptional({ description: 'Property rooms for location suggestions', type: [PropertyRoomDto], maxItems: 100 })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => PropertyRoomDto)
  propertyRooms?: PropertyRoomDto[];
}
