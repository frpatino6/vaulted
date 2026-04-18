import { Role } from '../../../common/enums/role.enum';

export interface PresenceUserDto {
  userId: string;
  email: string;
  role: Role;
  connectedAt: string;
  lastSeen: string;
}

export interface PresenceOnlineAuditorDto {
  onlineCount: number;
}
