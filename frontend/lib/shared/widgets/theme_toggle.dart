import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    final isLight = themeMode == ThemeMode.light;

    return Tooltip(
      message: isLight ? 'Dark mode' : 'Light mode',
      child: IconButton(
        key: const Key('theme-toggle'),
        icon: Icon(isLight ? Icons.dark_mode : Icons.light_mode),
        tooltip: isLight ? 'Dark mode' : 'Light mode',
        onPressed: () {
          ref.read(themeProvider.notifier).setThemeMode(
                isLight ? ThemeMode.dark : ThemeMode.light,
              );
        },
      ),
    );
  }
}
