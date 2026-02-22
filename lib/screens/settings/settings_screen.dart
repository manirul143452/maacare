// ============================================================
//  SettingsScreen – MaaCare
//  Language, theme, and privacy controls
// ============================================================

import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../widgets/maa_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  String _language = 'English';
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings ⚙️')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionTitle('Personalization'),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(_language),
            leading: const Icon(Icons.language_rounded, color: MaaColors.deepPink),
            onTap: _showLanguagePicker,
          ),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Soft dark themes for tired eyes 🌙'),
            value: _darkMode,
            onChanged: (v) => setState(() => _darkMode = v),
            activeColor: MaaColors.deepPink,
          ),
          const Divider(),
          _buildSectionTitle('Notifications'),
          SwitchListTile(
            title: const Text('Daily Reminders'),
            subtitle: const Text('Mood checks and baby updates 👶'),
            value: _notifications,
            onChanged: (v) => setState(() => _notifications = v),
            activeColor: MaaColors.deepPink,
          ),
          const Divider(),
          _buildSectionTitle('Privacy & Legal'),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(context, '/privacy'),
          ),
          ListTile(
            title: const Text('Terms & Conditions'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(context, '/terms'),
          ),
          ListTile(
            title: const Text('Export My Data', style: TextStyle(color: MaaColors.deepPink)),
            subtitle: const Text('Download all your logs in JSON format'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing your data bundle... 📦')),
              );
            },
          ),
          const SizedBox(height: 32),
          MaaButton(
            label: 'Request Data Deletion',
            outlined: true,
            onPressed: _showDeletionConfirm,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: MaaColors.textGrey, letterSpacing: 1.2),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('English'), onTap: () => _updateLang('English')),
          ListTile(title: const Text('Hindi (हिन्दी)'), onTap: () => _updateLang('Hindi')),
        ],
      ),
    );
  }

  void _updateLang(String l) {
    setState(() => _language = l);
    Navigator.pop(context);
  }

  void _showDeletionConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Data? ⚠️'),
        content: const Text('This will permanently erase all your logs and profile. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // Algorithm: GDPR data deletion logic
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data deletion request sent! ✋')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
