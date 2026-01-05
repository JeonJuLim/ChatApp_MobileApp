import { IsString, MinLength } from 'class-validator';

export class FriendRequestByPhoneDto {
  @IsString()
  @MinLength(6)
  phoneE164!: string;
}
