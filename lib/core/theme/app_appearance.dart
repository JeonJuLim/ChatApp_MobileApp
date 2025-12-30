import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppPalette { pastel, purple, blue }
enum FontScale { small, medium, large }
enum BubbleStyle { round, flat }

class AppAppearance extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppPalette _palette = AppPalette.pastel;
  FontScale _fontScale = FontScale.medium;
  BubbleStyle _bubbleStyle = BubbleStyle.round;

  ThemeMode get themeMode => _themeMode;
  AppPalette get palette => _palette;
  FontScale get fontScale => _fontScale;
  BubbleStyle get bubbleStyle => _bubbleStyle;

  bool get isDark => _themeMode == ThemeMode.dark;

  void setDarkMode(bool value) {
    _themeMode = value ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setPalette(AppPalette value) {
    _palette = value;
    notifyListeners();
  }

  void setFontScale(FontScale value) {
    _fontScale = value;
    notifyListeners();
  }

  void setBubbleStyle(BubbleStyle value) {
    _bubbleStyle = value;
    notifyListeners();
  }

  static const _kThemeMode = 'appearance_themeMode';
  static const _kPalette = 'appearance_palette';
  static const _kFontScale = 'appearance_fontScale';
  static const _kBubbleStyle = 'appearance_bubbleStyle';

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();

    final theme = sp.getString(_kThemeMode);
    final palette = sp.getString(_kPalette);
    final font = sp.getString(_kFontScale);
    final bubble = sp.getString(_kBubbleStyle);

    _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;

    _palette = AppPalette.values.firstWhere(
          (e) => e.name == palette,
      orElse: () => AppPalette.pastel,
    );

    _fontScale = FontScale.values.firstWhere(
          (e) => e.name == font,
      orElse: () => FontScale.medium,
    );

    _bubbleStyle = BubbleStyle.values.firstWhere(
          (e) => e.name == bubble,
      orElse: () => BubbleStyle.round,
    );

    notifyListeners();
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kThemeMode, isDark ? 'dark' : 'light');
    await sp.setString(_kPalette, _palette.name);
    await sp.setString(_kFontScale, _fontScale.name);
    await sp.setString(_kBubbleStyle, _bubbleStyle.name);
  }
}
