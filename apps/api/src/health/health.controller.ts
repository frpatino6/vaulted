import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Public } from '../common/decorators/public.decorator';
import { HealthService, HealthStatus } from './health.service';

@Controller('health')
export class HealthController {
  constructor(
    private readonly healthService: HealthService,
    private readonly config: ConfigService,
  ) {}

  @Public()
  @Get()
  check(): Promise<HealthStatus> {
    if (this.config.get<string>('NODE_ENV') === 'production') {
      return this.healthService.checkMinimal();
    }
    return this.healthService.check();
  }
}
