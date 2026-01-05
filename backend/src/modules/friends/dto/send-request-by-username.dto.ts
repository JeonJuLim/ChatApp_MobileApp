import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class SendRequestByUsernameDto {
  @IsString()
  @IsNotEmpty()
  // username: chữ/số/_ . tối thiểu 3 ký tự (tuỳ bạn chỉnh)
  @Matches(/^[a-zA-Z0-9_.]{3,30}$/, { message: 'Username không hợp lệ' })
  username!: string;
}
