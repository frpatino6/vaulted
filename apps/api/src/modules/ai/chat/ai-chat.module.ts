import { Module, OnModuleInit, Logger } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DataSource } from 'typeorm';
import { InjectDataSource } from '@nestjs/typeorm';
import { Item, ItemSchema } from '../../inventory/schemas/item.schema';
import { Property, PropertySchema } from '../../properties/schemas/property.schema';
import { AiChatService } from './ai-chat.service';
import { AiChatController } from './ai-chat.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Item.name, schema: ItemSchema },
      { name: Property.name, schema: PropertySchema },
    ]),
  ],
  controllers: [AiChatController],
  providers: [AiChatService],
  exports: [AiChatService],
})
export class AiChatModule implements OnModuleInit {
  private readonly logger = new Logger(AiChatModule.name);

  constructor(@InjectDataSource() private readonly dataSource: DataSource) {}

  async onModuleInit(): Promise<void> {
    try {
      await this.dataSource.query('CREATE EXTENSION IF NOT EXISTS vector');

      await this.dataSource.query(`
        CREATE TABLE IF NOT EXISTS item_embeddings (
          id          SERIAL PRIMARY KEY,
          item_id     VARCHAR(24)  NOT NULL UNIQUE,
          tenant_id   VARCHAR(24)  NOT NULL,
          embedding   vector(768)  NOT NULL,
          updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
        )
      `);

      await this.dataSource.query(`
        CREATE INDEX IF NOT EXISTS item_embeddings_hnsw_idx
          ON item_embeddings USING hnsw (embedding vector_cosine_ops)
      `);

      await this.dataSource.query(`
        CREATE INDEX IF NOT EXISTS item_embeddings_tenant_idx
          ON item_embeddings (tenant_id)
      `);

      this.logger.log('pgvector table and indexes ready');
    } catch (err) {
      this.logger.error('pgvector init failed', err);
    }
  }
}
