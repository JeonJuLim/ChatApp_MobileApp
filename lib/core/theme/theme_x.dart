import 'package:flutter/material.dart';

extension ThemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  Color get bg => Theme.of(this).scaffoldBackgroundColor;
  Color get surface => cs.surface;
  Color get text => cs.onSurface;
  Color get subtext => cs.onSurfaceVariant;
  Color get primary => cs.primary;
  Color get divider => Theme.of(this).dividerColor;
}
