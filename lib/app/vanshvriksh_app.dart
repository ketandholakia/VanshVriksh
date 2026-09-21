import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers/family_tree_repository_provider.dart';
import '../core/constants/app_constants.dart';
import '../features/settings/app_settings_provider.dart';
import 'app_router.dart';
import 'brand_background.dart';
import 'app_theme.dart';

class VanshVrikshApp extends ConsumerStatefulWidget {
  const VanshVrikshApp({super.key});

  @override
  ConsumerState<VanshVrikshApp> createState() => _VanshVrikshAppState();
}

class _VanshVrikshAppState extends ConsumerState<VanshVrikshApp> {
  bool _isReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initializeApp);
  }

  Future<void> _initializeApp() async {
    try {
      final familyTreeRepository = ref.read(familyTreeRepositoryProvider);
      await familyTreeRepository.ensureDefaultTree();
      if (!mounted) return;
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeModeAsync = ref.watch(appThemeModeProvider);
    final brightness =
        MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.light;
    final brandLogo = brightness == Brightness.dark
        ? 'assets/vanshvriksh_logo_dark.png'
        : 'assets/vanshvriksh_logo_light.png';
    final themeMode = switch (themeModeAsync.value ?? appThemeModeDefault) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    if (_errorMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BrandBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.deepForest.withValues(alpha: 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 26,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image(
                          image: AssetImage(brandLogo),
                          width: 88,
                          height: 88,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AppTheme.deepForest,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConstants.appTagline,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppTheme.slate),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Failed to initialize database:\n$_errorMessage',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!_isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: BrandBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [_StartupSplash()],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'VanshVriksh',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) {
        return BrandBackground(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepForest.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 228,
              height: 228,
              child: Padding(
                padding: EdgeInsets.all(18),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: Image(
                    image: AssetImage('assets/vanshvriksh_logo_light.png'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.deepForest,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppConstants.appTagline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.slate,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppConstants.shortDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.text.withValues(alpha: 0.82),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
          ],
        ),
      ),
    );
  }
}
