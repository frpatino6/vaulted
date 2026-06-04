import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AiVisionController } from './ai-vision.controller';
import { AiVisionService } from './ai-vision.service';

@Module({
  imports: [JwtModule.register({})],
  controllers: [AiVisionController],
  providers: [AiVisionService],
})
export class AiVisionModule {}
