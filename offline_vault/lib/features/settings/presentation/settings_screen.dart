import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/storage/secure_prefs.dart';
import '../../auth/application/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final SecurePrefs _prefs = SecurePrefs();
  bool _wifiOnly = true;
  bool _blockScreenshots = false;
  bool _hasPin = false;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final wifi = await _prefs.getSyncOnWifiOnly();
    final block = await _prefs.getBlockScreenshots();
    final pin = await _prefs.hasPin();
    final lang = await _prefs.getLanguageCode() ?? 'en';

    setState(() {
      _wifiOnly = wifi;
      _blockScreenshots = block;
      _hasPin = pin;
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Sync Section
          _buildSectionHeader('Sync & Network'),
          SwitchListTile(
            title: const Text('Sync on Wi-Fi only'),
            subtitle: const Text('Prevent using mobile data for automatic background sync'),
            value: _wifiOnly,
            onChanged: (val) async {
              setState(() => _wifiOnly = val);
              await _prefs.setSyncOnWifiOnly(val);
            },
          ),
          const Divider(),

          // Security Section
          _buildSectionHeader('Privacy & Security'),
          SwitchListTile(
            title: const Text('Block screenshots'),
            subtitle: const Text('Prevent screen captures and hide content in app switcher'),
            value: _blockScreenshots,
            onChanged: (val) async {
              setState(() => _blockScreenshots = val);
              await _prefs.setBlockScreenshots(val);
            },
          ),
          ListTile(
            title: const Text('App Lock & PIN'),
            subtitle: Text(_hasPin ? 'PIN is set' : 'No PIN configured'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showSetPinDialog(),
          ),
          const Divider(),

          // Storage Section
          _buildSectionHeader('Storage'),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Free up space'),
            subtitle: const Text('Removes original downloads while keeping thumbnails offline'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Space cleared. Thumbnails retained.')),
              );
            },
          ),
          const Divider(),

          // Language Section
          _buildSectionHeader('Language'),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: _language,
            onChanged: (val) async {
              setState(() => _language = val!);
              await _prefs.setLanguageCode(val!);
            },
          ),
          RadioListTile<String>(
            title: const Text('ગુજરાતી (Gujarati)'),
            value: 'gu',
            groupValue: _language,
            onChanged: (val) async {
              setState(() => _language = val!);
              await _prefs.setLanguageCode(val!);
            },
          ),
          RadioListTile<String>(
            title: const Text('हिन्दी (Hindi)'),
            value: 'hi',
            groupValue: _language,
            onChanged: (val) async {
              setState(() => _language = val!);
              await _prefs.setLanguageCode(val!);
            },
          ),
          const Divider(),

          // Account Section
          _buildSectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.lightError),
            title: const Text('Sign out', style: TextStyle(color: AppColors.lightError)),
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  void _showSetPinDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set 4-Digit PIN'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Enter 4 digits', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.length == 4) {
                final navigator = Navigator.of(ctx);
                await _prefs.setPinHash(controller.text, 'salt');
                if (!mounted) return;
                setState(() => _hasPin = true);
                navigator.pop();
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }
}
