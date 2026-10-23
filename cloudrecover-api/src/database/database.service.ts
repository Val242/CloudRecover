import { Injectable, OnModuleInit } from "@nestjs/common";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";
import { readFileSync } from "node:fs";
import "dotenv/config";

@Injectable()
export class DatabaseService extends PrismaClient implements OnModuleInit {
  async onModuleInit() {
    await this.$connect();
  }

constructor() {
  const adapter = new PrismaPg({
    connectionString: process.env.DATABASE_URL as string,
    ssl: {
      ca: readFileSync(
        "/etc/ssl/certs/rds/global-bundle.pem",
        "utf8",
      ),
      rejectUnauthorized: true,
    },
  });
  super({ adapter });
}
}
//ok