import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_names.dart';
import '../../../auth/data/repositories/auth_repository.dart';
import '../../../personality/data/repositories/personality_repository.dart';
import '../bloc/settings_bloc.dart';

/// Supported UI/conversation languages.
const _languages = <String, String>{
  'en': 'English',
  'es': 'Español',
  'fr': 'Français',
  'de': 'Deutsch',
  'hi': 'हिन्दी',
  'zh': '中文',
  'ar': 'العربية',
  'ja': '日本語',
};

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final personalities = sl<PersonalityRepository>().getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final settings = state.settings;
          final bloc = context.read<SettingsBloc>();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle(context, 'Account'),
              _accountCard(context),
              _sectionTitle(context, 'Appearance'),
              Card(
                child: RadioGroup<ThemeMode>(
                  groupValue: settings.themeMode,
                  onChanged: (v) =>
                      v == null ? null : bloc.add(ThemeModeChanged(v)),
                  child: const Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text('System'),
                        value: ThemeMode.system,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('Light'),
                        value: ThemeMode.light,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('Dark'),
                        value: ThemeMode.dark,
                      ),
                    ],
                  ),
                ),
              ),
              _sectionTitle(context, 'Language'),
              Card(
                child: ListTile(
                  title: const Text('Conversation language'),
                  trailing: DropdownButton<String>(
                    value: settings.languageCode,
                    underline: const SizedBox.shrink(),
                    items: _languages.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        v == null ? null : bloc.add(LanguageChanged(v)),
                  ),
                ),
              ),
              _sectionTitle(context, 'Assistant'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Active personality'),
                      trailing: DropdownButton<String>(
                        value: _safePersonalityValue(
                            settings.activePersonalityId, personalities),
                        underline: const SizedBox.shrink(),
                        items: personalities
                            .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                ))
                            .toList(),
                        onChanged: (v) => v == null
                            ? null
                            : bloc.add(ActivePersonalityChanged(v)),
                      ),
                    ),
                    ListTile(
                      title: const Text('Manage personalities'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(RouteNames.personality),
                    ),
                    SwitchListTile(
                      title: const Text('Use local memory'),
                      subtitle: const Text(
                          'Let the assistant remember facts you save.'),
                      value: settings.memoryEnabled,
                      onChanged: (v) => bloc.add(MemoryToggled(v)),
                    ),
                    ListTile(
                      title: const Text('Speech rate'),
                      subtitle: Slider(
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        value: settings.speechRate,
                        label: settings.speechRate.toStringAsFixed(1),
                        onChanged: (v) => bloc.add(SpeechRateChanged(v)),
                      ),
                    ),
                  ],
                ),
              ),
              _sectionTitle(context, 'Data'),
              Card(
                child: ListTile(
                  leading: Icon(Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error),
                  title: const Text('Clear all data'),
                  subtitle: const Text(
                      'Deletes conversations, history and memory on this device.'),
                  onTap: () => _confirmClear(context, bloc),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _accountCard(BuildContext context) {
    final auth = sl<AuthRepository>();
    final user = auth.currentUser;
    final isGuest = auth.status == AuthStatus.guest || user == null;

    if (isGuest) {
      return Card(
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
          title: const Text('Guest'),
          subtitle: const Text('Sign in to sync and personalize'),
          trailing: const Icon(Icons.login),
          onTap: () => context.go(RouteNames.login),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(user.label[0].toUpperCase()),
            ),
            title: Text(user.label),
            subtitle: user.email == null ? null : Text(user.email!),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.error),
            title: const Text('Sign out'),
            onTap: () => _confirmSignOut(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in anytime.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirmed == true) {
      // Status flips to unauthenticated; the router redirect navigates to login.
      await sl<AuthRepository>().signOut();
    }
  }

  String? _safePersonalityValue(String id, List personalities) {
    final exists = personalities.any((p) => p.id == id);
    if (exists) return id;
    return personalities.isNotEmpty ? personalities.first.id : null;
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Future<void> _confirmClear(BuildContext context, SettingsBloc bloc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This permanently deletes your conversations, history and saved '
            'memories on this device. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(const AllDataCleared());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared.')),
        );
      }
    }
  }
}
