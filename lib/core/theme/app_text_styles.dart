import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'package:minichatappmobile/core/theme/theme_x.dart';


class AppTextStyles {
  AppTextStyles._();

  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const welcomeTitle = TextStyle(
    fontSize: 36,
    color: AppColors.primary,
    fontWeight: FontWeight.bold,
  );

  static const welcomeSubtitle = TextStyle(
    fontSize: 16,
    height: 1.4,
    color: Colors.black87,
  );

  // Text trên nút OutlinedButton
  static const outlineButtonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  // Điều khoản
  static const legalText = TextStyle(
    fontSize: 14,
    color: Colors.black87,
  );

}
