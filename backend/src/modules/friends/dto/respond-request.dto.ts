import { IsIn, IsNotEmpty, IsString } from 'class-validator';

export class RespondRequestDto {
  @IsString()
  @IsNotEmpty()
  requestId!: string;

  // accept | reject
  @IsIn(['accept', 'reject'])
  action!: 'accept' | 'reject';
}
