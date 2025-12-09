import 'package:flutter/material.dart';
import 'package:minichatappmobile/core/theme/app_colors.dart';
import 'package:minichatappmobile/core/theme/app_text_styles.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  bool _darkMode = false; // mock, chưa apply ra toàn app
  String _selectedPalette = 'pastel';
  String _fontSize = 'medium'; // small / medium / large
  String _bubbleStyle = 'round'; // round / flat

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        centerTitle: true,
        title: Text(
          'Giao diện',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // ======= PREVIEW NHỎ Ở TRÊN =======
            Text(
              'Xem trước',
              style: AppTextStyles.welcomeSubtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildPreviewCard(),
            const SizedBox(height: 24),

            // ======= CHẾ ĐỘ SÁNG / TỐI =======
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SwitchListTile(
                title: Text(
                  'Chế độ tối',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Giảm sáng, dịu mắt khi dùng ban đêm.',
                  style: AppTextStyles.legalText,
                ),
                activeColor: AppColors.primary,
                value: _darkMode,
                onChanged: (v) {
                  setState(() => _darkMode = v);
                  // TODO: Áp dụng theme dark cho toàn app (sau khi có ThemeMode)
                },
              ),
            ),

            const SizedBox(height: 16),

            // ======= BỘ MÀU =======
            _sectionTitle('Bộ màu ứng dụng'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  _paletteChip(
                    id: 'pastel',
                    label: 'Mặc định',
                    colors: const [
                      AppColors.primary,
                      AppColors.secondary,
                      AppColors.tertiary,
                      AppColors.mint,
                    ],
                  ),
                  const SizedBox(width: 8),
                  _paletteChip(
                    id: 'purple',
                    label: 'Tím đậm',
                    colors: const [
                      Color(0xFF7C3AED),
                      Color(0xFF4C1D95),
                      Color(0xFFECFEFF),
                      Color(0xFFEDE9FE),
                    ],
                  ),
                  const SizedBox(width: 8),
                  _paletteChip(
                    id: 'blue',
                    label: 'Xanh biển',
                    colors: const [
                      Color(0xFF0EA5E9),
                      Color(0xFF0369A1),
                      Color(0xFFE0F2FE),
                      Color(0xFFECFEFF),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ======= KÍCH THƯỚC CHỮ =======
            _sectionTitle('Kích thước chữ'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'small',
                    groupValue: _fontSize,
                    activeColor: AppColors.primary,
                    title: const Text('Nhỏ'),
                    subtitle: Text(
                      'Hiển thị nhiều nội dung hơn trong 1 màn hình.',
                      style: AppTextStyles.legalText,
                    ),
                    onChanged: (v) => setState(() => _fontSize = v!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'medium',
                    groupValue: _fontSize,
                    activeColor: AppColors.primary,
                    title: const Text('Vừa (khuyến nghị)'),
                    onChanged: (v) => setState(() => _fontSize = v!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'large',
                    groupValue: _fontSize,
                    activeColor: AppColors.primary,
                    title: const Text('Lớn'),
                    subtitle: Text(
                      'Dễ đọc hơn, phù hợp màn hình nhỏ.',
                      style: AppTextStyles.legalText,
                    ),
                    onChanged: (v) => setState(() => _fontSize = v!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ======= KIỂU BONG BÓNG TIN NHẮN =======
            _sectionTitle('Kiểu bong bóng tin nhắn'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'round',
                    groupValue: _bubbleStyle,
                    activeColor: AppColors.primary,
                    title: const Text('Bo tròn mềm mại'),
                    subtitle: Text(
                      'Phong cách trẻ trung, hiện đại.',
                      style: AppTextStyles.legalText,
                    ),
                    onChanged: (v) => setState(() => _bubbleStyle = v!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'flat',
                    groupValue: _bubbleStyle,
                    activeColor: AppColors.primary,
                    title: const Text('Góc vuông, tối giản'),
                    subtitle: Text(
                      'Phong cách gọn gàng giống app công việc.',
                      style: AppTextStyles.legalText,
                    ),
                    onChanged: (v) => setState(() => _bubbleStyle = v!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Gợi ý: nút lưu (mock)
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Lưu config giao diện vào local (SharedPreferences, v.v.)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã lưu tuỳ chọn giao diện (mock).'),
                    ),
                  );
                },
                child: const Text(
                  'LƯU TUỲ CHỌN',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== WIDGET PHỤ ======

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _paletteChip({
    required String id,
    required String label,
    required List<Color> colors,
  }) {
    final bool selected = _selectedPalette == id;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _selectedPalette = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: selected ? 1.4 : 1,
          ),
          color: selected ? AppColors.primary.withOpacity(0.04) : Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: colors
                  .map(
                    (c) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  .toList(),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final bool dark = _darkMode;
    final Color bg = dark ? const Color(0xFF020617) : Colors.white;
    final Color otherBubble =
    dark ? const Color(0xFF1E293B) : const Color(0xFFF3F4FF);
    final Color meBubble = dark ? const Color(0xFF4C1D95) : AppColors.primary;

    final double radius = _bubbleStyle == 'round' ? 18 : 8;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // thanh tiêu đề nhỏ
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.secondary,
                child: const Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Người bạn A',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.more_vert,
                size: 18,
                color: dark ? Colors.white70 : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // bubble người kia
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(right: 40),
              decoration: BoxDecoration(
                color: otherBubble,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Text(
                'Chiều nay đi cà phê chứ?',
                style: TextStyle(
                  fontSize: _fontSize == 'small'
                      ? 11
                      : _fontSize == 'large'
                      ? 14
                      : 12,
                  color: dark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // bubble của mình
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(left: 40),
              decoration: BoxDecoration(
                color: meBubble,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Text(
                'Okeee, 4h nha!',
                style: TextStyle(
                  fontSize: _fontSize == 'small'
                      ? 11
                      : _fontSize == 'large'
                      ? 14
                      : 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
