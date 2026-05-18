import {
  IsArray,
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export class BoundingBoxDto {
  @IsNumber()
  x!: number;

  @IsNumber()
  y!: number;

  @IsNumber()
  width!: number;

  @IsNumber()
  height!: number;
}

export class CreateStepDto {
  @IsString()
  stepId!: string;

  @IsString()
  itemId!: string;

  @IsString()
  @MaxLength(500)
  itemName!: string;

  @IsString()
  @MaxLength(200)
  itemCategory!: string;

  @IsOptional()
  @IsString()
  itemPhoto?: string;

  @IsOptional()
  @IsString()
  roomId?: string;

  @IsOptional()
  @IsString()
  roomName?: string;

  @IsOptional()
  @IsString()
  roomPhoto?: string;

  @IsOptional()
  @IsString()
  sectionId?: string;

  @IsOptional()
  @IsString()
  sectionPhoto?: string;

  @IsOptional()
  @IsString()
  sectionCode?: string;

  @IsOptional()
  @IsString()
  sectionFurnitureName?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => BoundingBoxDto)
  boundingBox?: BoundingBoxDto;

  @IsString()
  @MaxLength(1000)
  instruction!: string;
}

export class CreateTaskGroupDto {
  @IsString()
  groupId!: string;

  @IsString()
  @MaxLength(300)
  title!: string;

  @IsOptional()
  @IsString()
  assignedUserId?: string;

  @IsOptional()
  @IsString()
  assignedUserName?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateStepDto)
  steps!: CreateStepDto[];
}

export class CreatePlanDto {
  @IsString()
  @MaxLength(200)
  title!: string;

  @IsString()
  @MaxLength(2000)
  originalCommand!: string;

  @IsOptional()
  @IsEnum(['prepare', 'pack', 'move', 'inspect', 'general'])
  commandType?: 'prepare' | 'pack' | 'move' | 'inspect' | 'general';

  @IsOptional()
  @IsDateString()
  targetDate?: string;

  @IsOptional()
  @IsString()
  targetPropertyId?: string;

  @IsOptional()
  @IsString()
  targetRoomId?: string;

  @IsOptional()
  @IsString()
  destinationPropertyId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  aiSummary?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CreateTaskGroupDto)
  taskGroups!: CreateTaskGroupDto[];
}
