import { Global, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../modules/users/entities/user.entity';
import { AccessControlService } from './services/access-control.service';
import { CryptoService } from './services/crypto.service';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [CryptoService, AccessControlService],
  exports: [CryptoService, AccessControlService],
})
export class CommonModule {}
