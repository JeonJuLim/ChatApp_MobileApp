import { IsString, MinLength } from 'class-validator';

export class FriendRequestByUsernameDto {
  @IsString()
  @MinLength(1)
  username!: string;
}
