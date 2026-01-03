import { IsArray, IsOptional } from 'class-validator';

export class UpdateMembersDto {
  @IsOptional()
  @IsArray()
  add?: string[];

  @IsOptional()
  @IsArray()
  remove?: string[];
}
