import { Test, TestingModule } from "@nestjs/testing";
import { DatabaseService } from "./database.service";

jest.mock("node:fs", () => ({
  ...jest.requireActual("node:fs"),
  readFileSync: jest.fn().mockReturnValue("test certificate"),
}));

describe("DatabaseService", () => {
  let service: DatabaseService;
  const originalDatabaseUrl = process.env.DATABASE_URL;

  beforeEach(async () => {
    process.env.DATABASE_URL = "postgresql://user:password@localhost:5432/test";

    const module: TestingModule = await Test.createTestingModule({
      providers: [DatabaseService],
    }).compile();

    service = module.get<DatabaseService>(DatabaseService);
  });

  afterEach(() => {
    jest.restoreAllMocks();

    if (originalDatabaseUrl === undefined) {
      delete process.env.DATABASE_URL;
    } else {
      process.env.DATABASE_URL = originalDatabaseUrl;
    }
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });
});
