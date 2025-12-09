import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // =========================================================
  // 1) BỘ MÀU MỚI – PASTEL (bạn chọn chính cho UI)
  // =========================================================

  /// Màu thương hiệu chính (tim pastel)
  static const primary = Color(0xFF9A8CFA);

  /// Màu xanh tím nhạt
  static const primarySoft = Color(0xFFA2B9EE);
  static const tertiary  = Color(0xFFA3DCEE);  // xanh dương nhạt
  /// Cyan pastel
  static const secondary = Color(0xFFA3DCEE);

  /// Mint pastel (#ADEEE2)
  static const mint = Color(0xFFADEEE2);


  // =========================================================
  // 2) BỘ MÀU CŨ (nếu vẫn muốn dùng ở một số chỗ)
  // =========================================================

  /// Màu xanh mạnh (bộ cũ)
  static const bluePrimary = Color(0xFF0066FF);

  static const bluePrimaryDark = Color(0xFF0044AA);

  /// Màu vàng accent cũ
  static const yellowAccent = Color(0xFFFFC107);


  // =========================================================
  // 3) NỀN – CHUNG
  // =========================================================

  static const background = Color(0xFFF5F7FB);
  static const surface = Colors.white;


  // =========================================================
  // 4) TEXT COLOR
  // =========================================================

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);


  // =========================================================
  // 5) STATUS COLOR
  // =========================================================

  static const success = Color(0xFF16A34A);
  static const error = Color(0xFFDC2626);
}
