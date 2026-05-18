import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class AddManualStepDto {
  @IsString()
  @IsNotEmpty()
  itemId!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  instruction!: string;
}
