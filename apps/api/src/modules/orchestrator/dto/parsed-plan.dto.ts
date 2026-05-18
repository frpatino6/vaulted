export interface ParsedBoundingBox {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface ParsedStepDto {
  stepId: string;
  itemId: string;
  itemName: string;
  itemCategory: string;
  itemPhoto?: string;
  roomId?: string;
  roomName?: string;
  roomPhoto?: string;
  sectionId?: string;
  sectionPhoto?: string;
  sectionCode?: string;
  sectionFurnitureName?: string;
  boundingBox?: ParsedBoundingBox;
  instruction: string;
}

export interface ParsedTaskGroupDto {
  groupId: string;
  title: string;
  steps: ParsedStepDto[];
}

export interface ParsedPlanDto {
  commandType: string;
  title: string;
  aiSummary: string;
  targetDate?: string;
  targetPropertyId?: string;
  destinationPropertyId?: string;
  taskGroups: ParsedTaskGroupDto[];
}
