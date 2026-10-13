import {
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';

@Injectable()
export class HealthService {
  constructor(
    private readonly databaseService: DatabaseService,
  ) {}

  live() {
    return {
      status: 'ok',
      service: 'cloudrecover-api',
    };
  }

  async ready() {
    let timer: ReturnType<typeof setTimeout> | undefined;

    try {
      await Promise.race([
        this.databaseService.$queryRaw`SELECT 1`,
        new Promise<never>((_resolve, reject) => {
          timer = setTimeout(() => {
            reject(new Error('Database health check timed out'));
          }, 3000);
        }),
      ]);

      return {
        status: 'ok',
        database: 'up',
      };
    } catch {
      throw new ServiceUnavailableException({
        status: 'unavailable',
        database: 'down',
      });
    } finally {
      if (timer !== undefined) {
        clearTimeout(timer);
      }
    }
  }
}