export enum Role {
  OWNER = 'owner',
  MANAGER = 'manager',
  STAFF = 'staff',
  AUDITOR = 'auditor',
  GUEST = 'guest',
}

export const MFA_REQUIRED_ROLES = [Role.OWNER, Role.MANAGER];
