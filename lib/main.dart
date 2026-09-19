import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database/database_manager.dart';
import 'domain/ai/ai_config.dart';
import 'domain/ai/ai_service.dart';
import 'domain/services/currency_service.dart';
import 'state/providers.dart';
import 'state/theme_provider.dart';
import 'ui/pages/main_shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CurrencyService.init();
  await ThemeNotifier.init();
  await AiConfigNotifier.init();
  await AiChatNotifier.init();

  // 初始化数据库管理器：打开全局库 → 无账本则创建默认账本 → 打开第一个账本
  final manager = DatabaseManager();
  final books = await manager.listBooks();
  if (books.isEmpty) {
    await manager.createBook(name: '默认账本');
  } else {
    await manager.openBook(books.first.id);
  }

  runApp(
    ProviderScope(
      overrides: [databaseManagerProvider.overrideWithValue(manager)],
      child: const XuPurseApp(),
    ),
  );
}

class XuPurseApp extends ConsumerWidget {
  const XuPurseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(currentThemeProvider);
    return MaterialApp(
      title: 'XuPurse',
      theme: buildAppTheme(
        Brightness.light,
        theme.seedColor,
        background: theme.background,
        cardColor: theme.cardColor,
      ),
      darkTheme: buildAppTheme(
        Brightness.dark,
        theme.seedColor,
        background: theme.background,
        cardColor: theme.cardColor,
      ),
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}
