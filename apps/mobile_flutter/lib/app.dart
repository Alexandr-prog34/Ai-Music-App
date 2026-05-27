import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/cache/local_media_cache_provider.dart';
import 'shared/routing/app_router.dart';
import 'shared/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize LocalMediaCache on app startup
    ref.watch(localMediaCacheProvider);

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
