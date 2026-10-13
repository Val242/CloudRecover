import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { DatabaseService } from '../database/database.service';
import { Prisma } from '@prisma/client';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { AdjustStockDto } from './dto/adjust-stock.dto';

const MAX_QUANTITY = 2_147_483_647;

@Injectable()
export class ProductsService {
  constructor(
    private readonly databaseService: DatabaseService,
  ) {}

  async create(dto: CreateProductDto) {
    const quantity = dto.quantity ?? 0;

    try {
      return await this.databaseService.product.create({
        data: {
          sku: dto.sku,
          name: dto.name,
          description: dto.description,
          quantity,
          stockMovements:
            quantity > 0
              ? {
                  create: {
                    change: quantity,
                    reason: 'Opening stock',
                  },
                }
              : undefined,
        },
      });
    } catch (error: unknown) {
      this.handleDatabaseError(error);
    }
  }

  async findAll() {
    return this.databaseService.product.findMany({
      where: {
        deletedAt: null,
      },
      orderBy: [
        { createdAt: 'desc' },
        { id: 'asc' },
      ],
    });
  }

  async findOne(id: string) {
    const product = await this.databaseService.product.findFirst({
      where: {
        id,
        deletedAt: null,
      },
    });

    if (!product) {
      throw new NotFoundException(`Product ${id} was not found`);
    }

    return product;
  }

  async update(id: string, dto: UpdateProductDto) {
    try {
      return await this.databaseService.product.update({
        where: {
          id,
          deletedAt: null,
        },
        data: {
          sku: dto.sku,
          name: dto.name,
          description: dto.description,
        },
      });
    } catch (error: unknown) {
      this.handleDatabaseError(error, id);
    }
  }

  async remove(id: string): Promise<void> {
    try {
      await this.databaseService.product.update({
        where: {
          id,
          deletedAt: null,
        },
        data: {
          deletedAt: new Date(),
        },
      });
    } catch (error: unknown) {
      this.handleDatabaseError(error, id);
    }
  }

  async adjustStock(id: string, dto: AdjustStockDto) {
    const minimumQuantity = dto.change < 0 ? -dto.change : 0;

    const maximumQuantity =
      dto.change > 0
        ? MAX_QUANTITY - dto.change
        : MAX_QUANTITY;

    return this.databaseService.$transaction(
      async (transaction) => {
        const result = await transaction.product.updateMany({
          where: {
            id,
            deletedAt: null,
            quantity: {
              gte: minimumQuantity,
              lte: maximumQuantity,
            },
          },
          data: {
            quantity: {
              increment: dto.change,
            },
          },
        });

        if (result.count === 0) {
          const product = await transaction.product.findFirst({
            where: {
              id,
              deletedAt: null,
            },
          });

          if (!product) {
            throw new NotFoundException(
              `Product ${id} was not found`,
            );
          }

          throw new BadRequestException(
            'Adjustment would produce negative stock or exceed the quantity limit',
          );
        }

        const movement = await transaction.stockMovement.create({
          data: {
            productId: id,
            change: dto.change,
            reason: dto.reason,
          },
        });

        const product = await transaction.product.findUniqueOrThrow({
          where: { id },
        });

        return {
          product,
          movement,
        };
      },
      {
        isolationLevel: Prisma.TransactionIsolationLevel.ReadCommitted,
      },
    );
  }

  async findStockMovements(id: string) {
    await this.findOne(id);

    return this.databaseService.stockMovement.findMany({
      where: {
        productId: id,
      },
      orderBy: [
        { createdAt: 'desc' },
        { id: 'asc' },
      ],
    });
  }

  private handleDatabaseError(
    error: unknown,
    id?: string,
  ): never {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      if (error.code === 'P2002') {
        throw new ConflictException(
          'A product with this SKU already exists',
        );
      }

      if (error.code === 'P2025') {
        throw new NotFoundException(
          id ? `Product ${id} was not found` : 'Product was not found',
        );
      }
    }

    throw error;
  }
}