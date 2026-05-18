# Notifications API Contract

## Endpoints
| Method | Path | Auth | Roles |
|--------|------|------|-------|
| POST | /notifications/send | Yes | Owner, Manager |
| GET | /notifications | Yes | All |
| PATCH | /notifications/:id/read | Yes | All |
| DELETE | /notifications/:id | Yes | All |

## Request DTOs

### SendNotificationDto
```typescript
{
  userId?: string;           // Optional: specific user to notify, null for all tenant users
  type: NotificationType;    // 'push' | 'email' | 'both'
  title: string;           // Max 255 chars
  message: string;       // Max 1000 chars
  data?: Record<string, unknown>;  // Optional payload
}
```

### ListNotificationsQueryDto
```typescript
{
  unreadOnly?: boolean;    // Filter: only unread
  limit?: number;       // Max 100, default 20
  offset?: number;     // Pagination offset
  type?: string;     // 'push' | 'email'
}
```

## Response DTOs

### NotificationResponseDto
```typescript
{
  id: string;
  tenantId: string;
  userId: string;
  type: 'push' | 'email';
  title: string;
  message: string;
  data?: Record<string, unknown>;
  read: boolean;
  createdAt: string;  // ISO 8601
}
```

## Error Codes
| Code | Scenario |
|------|----------|
| 400 | Invalid notification type |
| 401 | Unauthorized |
| 403 | Forbidden - insufficient role for /send |
| 404 | Notification not found |

## Notes
- `/notifications/send` is restricted to Owner and Manager roles
- All other endpoints are accessible to all authenticated users for their own notifications
- Notifications are filtered by tenantId from JWT
- Push notifications use FCM, emails use SendGrid