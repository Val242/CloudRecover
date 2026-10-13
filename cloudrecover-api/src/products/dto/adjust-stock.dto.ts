import { Transform } from "class-transformer";
import {
  IsInt,
  IsString,
  Max,
  MaxLength,
  Min,
  MinLength,
  NotEquals,
} from "class-validator";

export class AdjustStockDto {
  @IsInt()
  @NotEquals(0)
  @Min(-2_147_483_647)
  @Max(2_147_483_647)
  change!: number;

  @Transform(({ value }: { value: unknown }) =>
    typeof value === "string" ? value.trim() : value,
  )
  @IsString()
  @MinLength(1)
  @MaxLength(300)
  reason!: string;
}
