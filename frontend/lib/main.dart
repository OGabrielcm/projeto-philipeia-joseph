import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/auth/auth_notifier.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

void main() {
  runApp(const ProviderScope(child: _AppInit()));
}

class _AppInit extends ConsumerStatefulWidget {
  const _AppInit();

  @override
  ConsumerState<_AppInit> createState() => _AppInitState();
}

class _AppInitState extends ConsumerState<_AppInit> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = ref.read(authProvider.notifier).init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                    const SizedBox(height: 16),
                    const Text(
                      'Falha ao inicializar o app.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, color: AppColors.accent),
                      label: const Text('Tentar novamente',
                          style: TextStyle(color: AppColors.accent)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.accent)),
                      onPressed: () => setState(() {
                        _initFuture = ref.read(authProvider.notifier).init();
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return MaterialApp.router(
          title: 'Philipeia',
          theme: AppTheme.dark,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
