import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class AddGroupDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  title!: string;
}
