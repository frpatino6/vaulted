import { IsMongoId } from 'class-validator';

export class DetachItemParamDto {
  @IsMongoId()
  itemId!: string;
}
