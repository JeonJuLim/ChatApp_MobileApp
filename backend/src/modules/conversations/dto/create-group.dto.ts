import {
  IsArray,
  IsNotEmpty,
  IsOptional,
  IsString,
  ArrayNotEmpty,
  IsUUID,
} from 'class-validator';
import { Type } from 'class-transformer';

export class CreateGroupDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @IsOptional()
  @IsArray()
  @ArrayNotEmpty()
  @IsUUID('4', { each: true })
  @Type(() => String)
  memberIds?: string[];
}
