import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final darkModeProvider = StateProvider<bool>((ref) => false);
final notificationsProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);
    final notificationsEnabled = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Settings")),
      body: ListView(
        children: [
          // Dark Mode Toggle
          SwitchListTile(
            title: Text("Dark Mode"),
            value: isDarkMode,
            onChanged: (value) => ref.read(darkModeProvider.notifier).state = value,
            secondary: Icon(Icons.dark_mode),
          ),
          
          // Notifications Toggle
          SwitchListTile(
            title: Text("Enable Notifications"),
            value: notificationsEnabled,
            onChanged: (value) => ref.read(notificationsProvider.notifier).state = value,
            secondary: Icon(Icons.notifications_active),
          ),
          
          // Language Selection (Dummy)
          ListTile(
            leading: Icon(Icons.language),
            title: Text("Language"),
            subtitle: Text("English (Default)"),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Language selection coming soon!")),
              );
            },
            trailing: Icon(Icons.arrow_forward_ios),
          ),
        ],
      ),
    );
  }
}
