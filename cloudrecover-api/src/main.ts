import { ValidationPipe } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import type { NextFunction, Request, Response } from "express";
import { AppModule } from "./app.module";
import { MetricsService } from "./metrics/metrics.service";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const metricsService = app.get(MetricsService);

  app.use((request: Request, response: Response, next: NextFunction) => {
    metricsService.trackRequest(request, response, next);
  });

  app.enableShutdownHooks();

  await app.listen(Number(process.env.PORT ?? 3000), "0.0.0.0");
}
//pk
void bootstrap();
