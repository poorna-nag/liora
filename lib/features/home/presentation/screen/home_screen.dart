import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../data/models/feature_tile.dart';
import '../bloc/home_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Choose companion',
            icon: const Icon(Icons.face_retouching_natural_outlined),
            onPressed: () => context.push(RouteNames.characterSelection),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RouteNames.settings),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _HomeHeader(reminder: state.reminder)),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _TileCard(tile: state.tiles[i]),
                    childCount: state.tiles.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String? reminder;
  const _HomeHeader({this.reminder});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = sl<AuthRepository>();
    final user = auth.currentUser;
    final isGuest = auth.status == AuthStatus.guest || user == null;
    final name = (user != null && !user.isGuest) ? user.label : null;
    final greeting = name == null ? _greeting() : '${_greeting()}, $name';
    final today = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            today,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          if (reminder != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(reminder!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(RouteNames.planner),
              ),
            ),
          ],
          if (isGuest) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('You\'re in Guest Mode'),
                subtitle:
                    const Text('Sign in to sync and keep your conversations.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(RouteNames.login),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  final FeatureTile tile;
  const _TileCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(tile.route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: tile.color.withValues(alpha: 0.15),
                child: Icon(tile.icon, color: tile.color),
              ),
              const Spacer(),
              Text(
                tile.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                tile.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
