import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/localization/shop_localizations.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/domain/app_user.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return profile.when(
      loading: () => Semantics(
        label: ShopLocalizations.of(context).text('loadingProfile'),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => ErrorView(
        message: ShopLocalizations.of(context).text('profileLoadError'),
        onRetry: () => ref.invalidate(profileProvider),
      ),
      data: (result) => switch (result) {
        Success<AppUser>(:final data) => _ProfileContent(user: data),
        Error<AppUser>(:final error) => _ProfileFailure(failure: error),
      },
    );
  }
}

class _ProfileFailure extends ConsumerWidget {
  const _ProfileFailure({required this.failure});
  final Failure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (failure is UnauthorizedFailure) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(sessionProvider.notifier).signOut(notice: 'session_expired');
      });
      return const Center(child: CircularProgressIndicator());
    }
    return ErrorView(
      message: failure.message,
      onRetry: () => ref.invalidate(profileProvider),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundImage: user.image.isEmpty
                          ? null
                          : CachedNetworkImageProvider(user.image),
                      child: Text(
                        user.fullName.isEmpty
                            ? '?'
                            : user.fullName.substring(0, 1),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ShopLocalizations.of(context).text('profileMember'),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 22),
                    _ProfileLine(
                      icon: Icons.email_outlined,
                      label: ShopLocalizations.of(context).text('email'),
                      value: user.email,
                    ),
                    const SizedBox(height: 16),
                    _ProfileLine(
                      icon: Icons.phone_outlined,
                      label: ShopLocalizations.of(context).text('phone'),
                      value: user.phone,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.read(sessionProvider.notifier).signOut(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: Text(ShopLocalizations.of(context).text('logout')),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 2),
            Text(
              value.isEmpty
                  ? ShopLocalizations.of(context).text('notProvided')
                  : value,
            ),
          ],
        ),
      ),
    ],
  );
}
