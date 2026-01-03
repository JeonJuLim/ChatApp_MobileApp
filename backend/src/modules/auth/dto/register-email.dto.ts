import {
  IsEmail,
  IsOptional,
  IsString,
  MinLength,
  Matches,
} from 'class-validator';

export class RegisterEmailDto {
  @IsEmail({}, { message: 'Email không hợp lệ' })
  email: string;

  @IsString()
  @MinLength(6, { message: 'Mật khẩu tối thiểu 6 ký tự' })
  password: string;

  @IsString()
  @MinLength(3, { message: 'Username tối thiểu 3 ký tự' })
  @Matches(/^[a-z0-9](?:[a-z0-9._]{1,18}[a-z0-9])?$/, {
    message:
      'Username chỉ gồm chữ thường, số, . _ và không bắt đầu/kết thúc bằng ký tự đặc biệt',
  })
  username: string;

  @IsOptional()
  @IsString()
  fullName?: string;
}