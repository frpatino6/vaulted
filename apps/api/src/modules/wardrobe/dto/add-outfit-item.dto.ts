import { IsMongoId } from 'class-validator';

export class AddOutfitItemDto {
  @IsMongoId()
  itemId!: string;
}
