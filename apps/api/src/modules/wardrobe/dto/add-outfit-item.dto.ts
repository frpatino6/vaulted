import { IsMongoId } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class AddOutfitItemDto {
  @ApiProperty({ description: 'Inventory item ID', example: '64f1b2c3d4e5f6789012abcd' })
  @IsMongoId()
  itemId!: string;
}
