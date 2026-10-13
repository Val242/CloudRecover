import { Module } from "@nestjs/common";
import { DatabaseModule } from "./database/database.module";
import { ProductsController } from "./products/products.controller";
import { ProductsService } from "./products/products.service";
import { HealthController } from "./health/health.controller";
import { HealthService } from "./health/health.service";
import { MetricsController } from "./metrics/metrics.controller";
import { MetricsService } from "./metrics/metrics.service";

@Module({
  imports: [DatabaseModule],
  controllers: [ProductsController, HealthController, MetricsController],
  providers: [ProductsService, HealthService, MetricsService],
})
export class AppModule {}
