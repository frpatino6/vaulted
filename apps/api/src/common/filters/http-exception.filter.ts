import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    let message =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';

    // Malformed resource identifiers (Mongo ObjectId cast failure or Postgres
    // invalid_text_representation for uuid columns) must not surface as 500.
    if (!(exception instanceof HttpException) && exception instanceof Error) {
      const code = (exception as { code?: string }).code;
      if (exception.name === 'CastError' || code === '22P02') {
        status = HttpStatus.BAD_REQUEST;
        message = 'Invalid identifier format';
      }
    }

    // Stream already started — can't send JSON, headers are already sent
    if (response.headersSent) return;

    if (status >= 500) {
      this.logger.error(
        `${request.method} ${request.url} - ${status}`,
        exception instanceof Error ? exception.stack : String(exception),
      );
    }

    response.status(status).json({
      success: false,
      error: {
        statusCode: status,
        message:
          typeof message === 'object' && message !== null
            ? (message as Record<string, unknown>)['message'] ?? message
            : message,
        timestamp: new Date().toISOString(),
        path: request.path.replace(/\/[a-f0-9]{24}/gi, '/:id'),
      },
    });
  }
}
