import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import type { Response } from 'express';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

export interface StandardResponse<T> {
  success: boolean;
  data: T;
  meta?: Record<string, unknown>;
}

@Injectable()
export class ResponseInterceptor<T>
  implements NestInterceptor<T, StandardResponse<T>>
{
  intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Observable<StandardResponse<T>> {
    const res = context.switchToHttp().getResponse<Response>();
    return next.handle().pipe(
      map((data: T) => {
        if (res.headersSent) {
          return data as unknown as StandardResponse<T>;
        }
        return {
          success: true,
          data,
        };
      }),
    );
  }
}
