import { IsString, Matches } from 'class-validator';

export class SendByUsernameDto {
  @IsString()
  @Matches(/^[a-zA-Z0-9_.]{3,20}$/)
  username: string;
}
