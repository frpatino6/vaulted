import { Type } from 'class-transformer';
import { ArrayMaxSize, IsArray, ValidateNested } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

import { AddSectionDto } from './add-section.dto';

export class AddSectionsDto {
  @ApiProperty({ description: 'Sections to add', type: [AddSectionDto], maxItems: 100 })
  @IsArray()
  @ArrayMaxSize(100)
  @ValidateNested({ each: true })
  @Type(() => AddSectionDto)
  sections!: AddSectionDto[];
}
