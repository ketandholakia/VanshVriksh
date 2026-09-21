import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand_background.dart';
import 'dashboard_models.dart';
import 'dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VanshVriksh'),
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 68,
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            const _HeroCard(),
            const SizedBox(height: 14),
            statsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load dashboard: $error'),
                ),
              ),
              data: (stats) => _StatsGrid(stats: stats),
            ),
            const SizedBox(height: 14),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            _DashboardActionCard(
              title: 'Add Family Member',
              subtitle: 'Create a new person profile',
              icon: Icons.person_add_alt_1,
              accent: Colors.green,
              onTap: () => context.push('/people/add?returnTo=/people'),
            ),
            _DashboardActionCard(
              title: 'Upcoming Birthdays',
              subtitle: 'View birthdays in the next 60 days',
              icon: Icons.cake_outlined,
              accent: Colors.orange,
              onTap: () => context.push('/birthdays'),
            ),
            _DashboardActionCard(
              title: 'People',
              subtitle: 'View and search family members',
              icon: Icons.people_alt_outlined,
              accent: Colors.teal,
              onTap: () => context.push('/people'),
            ),
            _DashboardActionCard(
              title: 'Family Tree',
              subtitle: 'Explore visual family relationships',
              icon: Icons.account_tree_outlined,
              accent: Colors.brown,
              onTap: () => context.push('/tree'),
            ),
            _DashboardActionCard(
              title: 'Backup & Restore',
              subtitle: 'Export or restore your family data',
              icon: Icons.backup_outlined,
              accent: Colors.blueGrey,
              onTap: () => context.push('/backup'),
            ),
            _DashboardActionCard(
              title: 'Settings',
              subtitle: 'App info, privacy, backup options and future imports',
              icon: Icons.settings_outlined,
              accent: Colors.deepPurple,
              onTap: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final brightness =
        MediaQuery.maybeOf(context)?.platformBrightness ?? Brightness.light;
    final brandLogo = brightness == Brightness.dark
        ? 'assets/vanshvriksh_logo_dark.png'
        : 'assets/vanshvriksh_logo_light.png';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/tree'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              const Positioned.fill(
                child: BrandWatermark(
                  alignment: Alignment.centerRight,
                  opacity: 0.055,
                  scale: 1.2,
                  padding: EdgeInsets.only(right: 6),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Family Tree',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.62),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(brandLogo),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VanshVriksh',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to open the family tree and explore relationships.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.35,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _StatCard(
          title: 'Members',
          value: stats.totalMembers.toString(),
          icon: Icons.people_alt_outlined,
          accent: Colors.green,
          onTap: () => context.push('/people'),
        ),
        _StatCard(
          title: 'Relations',
          value: stats.totalRelationships.toString(),
          icon: Icons.link_outlined,
          accent: Colors.teal,
          onTap: () => context.push('/tree'),
        ),
        _StatCard(
          title: 'Birthdays',
          value: stats.upcomingBirthdays.toString(),
          icon: Icons.cake_outlined,
          accent: Colors.orange,
          onTap: () => context.push('/birthdays'),
        ),
        _StatCard(
          title: 'With Photos',
          value: stats.membersWithPhotos.toString(),
          icon: Icons.photo_camera_outlined,
          accent: Colors.blue,
          onTap: () => context.push('/people?filter=with-photos'),
        ),
        _StatCard(
          title: 'Missing Photos',
          value: stats.missingPhotos.toString(),
          icon: Icons.no_photography_outlined,
          accent: Colors.blueGrey,
          onTap: () => context.push('/people?filter=missing-photos'),
        ),
        _StatCard(
          title: 'Living',
          value: stats.livingMembers.toString(),
          icon: Icons.favorite_outline,
          accent: Colors.pink,
          onTap: () => context.push('/people?filter=living'),
        ),
        _StatCard(
          title: 'Deceased',
          value: stats.deceasedMembers.toString(),
          icon: Icons.history_toggle_off_outlined,
          accent: Colors.brown,
          onTap: () => context.push('/people?filter=deceased'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Stack(
          children: [
            const Positioned.fill(
              child: BrandWatermark(
                alignment: Alignment.centerRight,
                opacity: 0.03,
                scale: 0.92,
                padding: EdgeInsets.only(right: 4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: accent),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Stack(
          children: [
            const Positioned.fill(
              child: BrandWatermark(
                alignment: Alignment.centerRight,
                opacity: 0.03,
                scale: 0.88,
                padding: EdgeInsets.only(right: 2),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.14),
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accent.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(icon, color: accent),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              height: 1.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.chevron_right,
                      color: accent.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
