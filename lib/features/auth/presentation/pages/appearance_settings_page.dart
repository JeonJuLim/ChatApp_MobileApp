import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:minichatappmobile/core/theme/app_appearance.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AppAppearance>();
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao diện'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Xem trước',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _PreviewCard(appearance: a),
            const SizedBox(height: 24),

            // ===== Dark mode =====
            _Card(
              child: SwitchListTile(
                title: const Text(
                  'Chế độ tối',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Giảm sáng, dịu mắt khi dùng ban đêm.'),
                activeColor: primary,
                value: a.isDark,
                onChanged: (v) async {
                  final ap = context.read<AppAppearance>();
                  ap.setDarkMode(v);
                  await ap.save();
                },
              ),
            ),

            const SizedBox(height: 16),

            // ===== Palette =====
            const _SectionTitle('Bộ màu ứng dụng'),
            const SizedBox(height: 8),
            _Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // FIX overflow
                child: Row(
                  children: [
                    _PaletteChip(
                      selected: a.palette == AppPalette.pastel,
                      label: 'Mặc định',
                      colors: const [
                        Color(0xFF7C3AED),
                        Color(0xFF22C55E),
                        Color(0xFFECFEFF),
                        Color(0xFFEDE9FE),
                      ],
                      onTap: () async {
                        final ap = context.read<AppAppearance>();
                        ap.setPalette(AppPalette.pastel);
                        await ap.save();
                      },
                    ),
                    const SizedBox(width: 8),
                    _PaletteChip(
                      selected: a.palette == AppPalette.purple,
                      label: 'Tím đậm',
                      colors: const [
                        Color(0xFF7C3AED),
                        Color(0xFF4C1D95),
                        Color(0xFFECFEFF),
                        Color(0xFFEDE9FE),
                      ],
                      onTap: () async {
                        final ap = context.read<AppAppearance>();
                        ap.setPalette(AppPalette.purple);
                        await ap.save();
                      },
                    ),
                    const SizedBox(width: 8),
                    _PaletteChip(
                      selected: a.palette == AppPalette.blue,
                      label: 'Xanh biển',
                      colors: const [
                        Color(0xFF0EA5E9),
                        Color(0xFF0369A1),
                        Color(0xFFE0F2FE),
                        Color(0xFFECFEFF),
                      ],
                      onTap: () async {
                        final ap = context.read<AppAppearance>();
                        ap.setPalette(AppPalette.blue);
                        await ap.save();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== Font size =====
            const _SectionTitle('Kích thước chữ'),
            const SizedBox(height: 8),
            _Card(
              child: Column(
                children: [
                  RadioListTile<FontScale>(
                    value: FontScale.small,
                    groupValue: a.fontScale,
                    activeColor: primary,
                    title: const Text('Nhỏ'),
                    subtitle: const Text('Hiển thị nhiều nội dung hơn trong 1 màn hình.'),
                    onChanged: (v) async {
                      if (v == null) return;
                      final ap = context.read<AppAppearance>();
                      ap.setFontScale(v);
                      await ap.save();
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<FontScale>(
                    value: FontScale.medium,
                    groupValue: a.fontScale,
                    activeColor: primary,
                    title: const Text('Vừa (khuyến nghị)'),
                    onChanged: (v) async {
                      if (v == null) return;
                      final ap = context.read<AppAppearance>();
                      ap.setFontScale(v);
                      await ap.save();
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<FontScale>(
                    value: FontScale.large,
                    groupValue: a.fontScale,
                    activeColor: primary,
                    title: const Text('Lớn'),
                    subtitle: const Text('Dễ đọc hơn, phù hợp màn hình nhỏ.'),
                    onChanged: (v) async {
                      if (v == null) return;
                      final ap = context.read<AppAppearance>();
                      ap.setFontScale(v);
                      await ap.save();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== Bubble style =====
            const _SectionTitle('Kiểu bong bóng tin nhắn'),
            const SizedBox(height: 8),
            _Card(
              child: Column(
                children: [
                  RadioListTile<BubbleStyle>(
                    value: BubbleStyle.round,
                    groupValue: a.bubbleStyle,
                    activeColor: primary,
                    title: const Text('Bo tròn mềm mại'),
                    subtitle: const Text('Phong cách trẻ trung, hiện đại.'),
                    onChanged: (v) async {
                      if (v == null) return;
                      final ap = context.read<AppAppearance>();
                      ap.setBubbleStyle(v);
                      await ap.save();
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<BubbleStyle>(
                    value: BubbleStyle.flat,
                    groupValue: a.bubbleStyle,
                    activeColor: primary,
                    title: const Text('Góc vuông, tối giản'),
                    subtitle: const Text('Phong cách gọn gàng giống app công việc.'),
                    onChanged: (v) async {
                      if (v == null) return;
                      final ap = context.read<AppAppearance>();
                      ap.setBubbleStyle(v);
                      await ap.save();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  // đã auto-save rồi; bấm nút chỉ để confirm cho user
                  await context.read<AppAppearance>().save();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã lưu tuỳ chọn giao diện.')),
                  );
                },
                child: const Text(
                  'LƯU TUỲ CHỌN',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.35)),
      ),
      child: child,
    );
  }
}

class _PaletteChip extends StatelessWidget {
  final bool selected;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  const _PaletteChip({
    required this.selected,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? primary : const Color(0xFFE5E7EB),
            width: selected ? 1.4 : 1,
          ),
          color: selected ? primary.withOpacity(0.06) : Colors.transparent,
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
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
              )
                  .toList(),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? primary : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final AppAppearance appearance;
  const _PreviewCard({required this.appearance});

  @override
  Widget build(BuildContext context) {
    final dark = appearance.isDark;

    final bg = dark ? const Color(0xFF0B1220) : Colors.white;
    final otherBubble = dark ? const Color(0xFF1E293B) : const Color(0xFFF3F4FF);
    final meBubble = Theme.of(context).colorScheme.primary;
    final radius = appearance.bubbleStyle == BubbleStyle.round ? 18.0 : 8.0;

    double fs() {
      switch (appearance.fontScale) {
        case FontScale.small:
          return 11;
        case FontScale.large:
          return 14;
        case FontScale.medium:
        default:
          return 12;
      }
    }

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
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.person, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                'Người bạn A',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Icon(Icons.more_vert, size: 18, color: dark ? Colors.white70 : Colors.black45),
            ],
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(right: 40),
              decoration: BoxDecoration(
                color: otherBubble,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Text(
                'Chiều nay đi cà phê chứ?',
                style: TextStyle(
                  fontSize: fs(),
                  color: dark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(left: 40),
              decoration: BoxDecoration(
                color: meBubble,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Text(
                'Okeee, 4h nha!',
                style: TextStyle(fontSize: fs(), color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
