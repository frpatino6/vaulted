import { IsString, IsOptional, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class PropertyRoomDto {
  @ApiProperty({ description: 'Room ID' })
  @IsString()
  roomId!: string;

  @ApiProperty({ description: 'Room name', example: 'Master Bedroom' })
  @IsString()
  name!: string;

  @ApiProperty({ description: 'Room type', example: 'bedroom' })
  @IsString()
  type!: string;
}

export class AnalyzeItemDto {
  @ApiProperty({ description: 'Product image URL or storage key' })
  @IsString()
  productImageUrl!: string;

  @ApiPropertyOptional({ description: 'Invoice image URL or storage key' })
  @IsOptional()
  @IsString()
  invoiceImageUrl?: string;

  @ApiPropertyOptional({ description: 'Property rooms for location suggestions', type: [PropertyRoomDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PropertyRoomDto)
  propertyRooms?: PropertyRoomDto[];
}
