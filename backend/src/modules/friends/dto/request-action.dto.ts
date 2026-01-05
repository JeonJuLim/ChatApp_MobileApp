import { IsString, MinLength } from 'class-validator';

export class FriendRequestActionDto {
  @IsString()
  @MinLength(1)
  requestId!: string;
}
