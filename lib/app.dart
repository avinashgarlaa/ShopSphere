import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shopsphere/core/localization/locale_controller.dart';

import 'core/di/providers.dart';
import 'core/error/result.dart';
import 'core/localization/shop_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/presentation/session_controller.dart';
import 'features/cart/presentation/cart_screen.dart';
import 'features/products/presentation/products_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

class ShopSphereApp extends ConsumerWidget {
  const ShopSphereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ShopSphere',
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ref.watch(themeProvider),
    locale: ref.watch(localeProvider),
    supportedLocales: ShopLocalizations.supportedLocales,
    localizationsDelegates: const [
      ShopLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: const AppGate(),
  );
}

class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    return switch (session) {
      SessionChecking() => const SplashScreen(),
      SessionSignedOut(:final notice) => LoginScreen(notice: notice),
      SessionSignedIn() => const ShopperShell(),
    };
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text('ShopSphere', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ],
      ),
    ),
  );
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.notice});

  final String? notice;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController(text: 'emilys');
  final _password = TextEditingController(text: 'emilyspass');
  var _hidePassword = true;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await ref
        .read(sessionProvider.notifier)
        .login(_username.text.trim(), _password.text);
    if (!mounted) return;
    if (result is Error<AuthSession>) {
      setState(() => _error = result.error.message);
    }
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ShopLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: scheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.shopping_bag_rounded,
                                color: scheme.onPrimaryContainer,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SHOPSPHERE',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: scheme.primary,
                                          letterSpacing: 1.6,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    strings.text('welcome'),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          strings.text('signInIntro'),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (widget.notice != null) ...[
                          const SizedBox(height: 20),
                          _MessageCard(
                            message: widget.notice == 'session_expired'
                                ? strings.text('sessionExpired')
                                : widget.notice!,
                            icon: Icons.info_outline_rounded,
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 20),
                          _MessageCard(
                            message: _error!,
                            icon: Icons.error_outline_rounded,
                            isError: true,
                          ),
                        ],
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _username,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username],
                          decoration: InputDecoration(
                            labelText: strings.text('username'),
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return strings.text('enterUsername');
                            }
                            if (value.trim().length < 3) {
                              return strings.text('usernameMin');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _password,
                          obscureText: _hidePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: strings.text('password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _hidePassword
                                  ? strings.text('showPassword')
                                  : strings.text('hidePassword'),
                              onPressed: () => setState(
                                () => _hidePassword = !_hidePassword,
                              ),
                              icon: Icon(
                                _hidePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return strings.text('enterPassword');
                            }
                            if (value.length < 6) {
                              return strings.text('passwordMin');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          liveRegion: true,
                          label: _submitting ? strings.text('signingIn') : null,
                          child: FilledButton(
                            onPressed: _submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(strings.text('signIn')),
                          ),
                        ),
                        const SizedBox(height: 18),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_open_rounded,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    strings.text('demoCredentials'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.message,
    required this.icon,
    this.isError = false,
  });

  final String message;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    final background = isError
        ? scheme.errorContainer
        : scheme.primaryContainer;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: .2)),
        ),
        child: Row(
          children: [
            ExcludeSemantics(child: Icon(icon, color: color)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: TextStyle(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

class ShopperShell extends ConsumerWidget {
  const ShopperShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ShopLocalizations.of(context);
    final selected = ref.watch(navigationIndexProvider);
    final width = MediaQuery.sizeOf(context).width;
    final rail = width >= 600;
    final cartCount = ref.watch(cartProvider).totals.itemCount;
    final pages = const [ProductsScreen(), CartScreen(), ProfileScreen()];
    final current = pages[selected];
    final content = selected == 0 && width >= 1024
        ? const ProductsScreen(expanded: true)
        : current;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          [
            strings.text('discover'),
            strings.text('cart'),
            strings.text('profile'),
          ][selected],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: strings.text('language'),
            icon: const Icon(Icons.language_rounded),
            onSelected: ref.read(localeProvider.notifier).setLanguage,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'en', child: Text(strings.text('english'))),
              PopupMenuItem(value: 'hi', child: Text(strings.text('hindi'))),
            ],
          ),
          IconButton(
            tooltip: strings.text('themeToggle'),
            icon: Icon(
              ref.watch(themeProvider) == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
          ),
          _CartButton(
            count: cartCount,
            onPressed: () =>
                ref.read(navigationIndexProvider.notifier).state = 1,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: rail
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: selected,
                  labelType: NavigationRailLabelType.all,
                  onDestinationSelected: (index) =>
                      ref.read(navigationIndexProvider.notifier).state = index,
                  destinations: [
                    NavigationRailDestination(
                      icon: const Icon(Icons.storefront_outlined),
                      selectedIcon: const Icon(Icons.storefront),
                      label: Text(strings.text('discover')),
                    ),
                    NavigationRailDestination(
                      icon: _CartGlyph(count: cartCount),
                      selectedIcon: _CartGlyph(count: cartCount, filled: true),
                      label: Text(strings.text('cart')),
                    ),
                    NavigationRailDestination(
                      icon: const Icon(Icons.person_outline),
                      selectedIcon: const Icon(Icons.person),
                      label: Text(strings.text('profile')),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: rail
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (index) =>
                  ref.read(navigationIndexProvider.notifier).state = index,
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.storefront_outlined),
                  selectedIcon: const Icon(Icons.storefront),
                  label: strings.text('discover'),
                ),
                NavigationDestination(
                  icon: _CartGlyph(count: cartCount),
                  selectedIcon: _CartGlyph(count: cartCount, filled: true),
                  label: strings.text('cart'),
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: strings.text('profile'),
                ),
              ],
            ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: ShopLocalizations.of(
      context,
    ).text('cartButton').replaceAll('{count}', '$count'),
    onPressed: onPressed,
    icon: _CartGlyph(count: count),
  );
}

class _CartGlyph extends StatelessWidget {
  const _CartGlyph({required this.count, this.filled = false});
  final int count;
  final bool filled;

  @override
  Widget build(BuildContext context) => Badge(
    isLabelVisible: count > 0,
    label: Text(count > 99 ? '99+' : '$count'),
    child: Icon(filled ? Icons.shopping_bag : Icons.shopping_bag_outlined),
  );
}
