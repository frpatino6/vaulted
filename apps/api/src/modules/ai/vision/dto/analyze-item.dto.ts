import { IsString, IsOptional, IsArray, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class PropertyRoomDto {
  @IsString()
  roomId!: string;

  @IsString()
  name!: string;

  @IsString()
  type!: string;
}

export class AnalyzeItemDto {
  @IsString()
  productImageUrl!: string;

  @IsOptional()
  @IsString()
  invoiceImageUrl?: string;

  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => PropertyRoomDto)
  propertyRooms?: PropertyRoomDto[];
}
