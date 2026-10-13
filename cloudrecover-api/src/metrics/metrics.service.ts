import { Injectable } from "@nestjs/common";
import type { NextFunction, Request, Response } from "express";
import {
  collectDefaultMetrics,
  Counter,
  Histogram,
  Registry,
} from "prom-client";

@Injectable()
export class MetricsService {
  private readonly registry = new Registry();

  private readonly requestCounter: Counter<"method" | "route" | "status_code">;

  private readonly requestDuration: Histogram<
    "method" | "route" | "status_code"
  >;

  constructor() {
    this.registry.setDefaultLabels({
      service: "cloudrecover-api",
    });

    collectDefaultMetrics({
      register: this.registry,
    });

    this.requestCounter = new Counter({
      name: "http_requests_total",
      help: "Total completed HTTP requests",
      labelNames: ["method", "route", "status_code"] as const,
      registers: [this.registry],
    });

    this.requestDuration = new Histogram({
      name: "http_request_duration_seconds",
      help: "HTTP request duration in seconds",
      labelNames: ["method", "route", "status_code"] as const,
      buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
      registers: [this.registry],
    });
  }

  get contentType(): string {
    return this.registry.contentType;
  }

  async getMetrics(): Promise<string> {
    return this.registry.metrics();
  }

  trackRequest(request: Request, response: Response, next: NextFunction): void {
    if (request.path === "/metrics" || request.path === "/metrics/") {
      next();
      return;
    }

    const start = process.hrtime.bigint();

    response.once("finish", () => {
      const routeInfo: unknown = request.route;
      let route = "unmatched";

      if (
        routeInfo !== null &&
        typeof routeInfo === "object" &&
        "path" in routeInfo &&
        typeof routeInfo.path === "string"
      ) {
        route = routeInfo.path;
      }

      const duration = Number(process.hrtime.bigint() - start) / 1_000_000_000;

      const labels = {
        method: request.method,
        route,
        status_code: String(response.statusCode),
      };

      this.requestCounter.inc(labels);
      this.requestDuration.observe(labels, duration);
    });

    next();
  }
}
