import { IsOptional, IsString } from "class-validator";

export class UpdatePhoneDto {
  @IsOptional()
  @IsString()
  phone?: string | null;
}
