import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../navigation/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth_ui.dart';

/// Screen 13. Preferences are local demo data, not an authenticated account.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key, required this.onThemeChanged});

  final ValueChanged<bool> onThemeChanged;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String _ownerName = 'Store owner';
  String _storeName = 'My store';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _ownerName = prefs.getString('demo_owner_name') ?? 'Store owner';
      _storeName = prefs.getString('demo_store_name') ?? 'My store';
    });
  }

  Future<void> _editStore() async {
    final controller = TextEditingController(text: _storeName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit store name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Store name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Do not manually dispose the controller while its dialog is still animating.
    if (!mounted || newName == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('demo_store_name', newName);
    if (mounted) setState(() => _storeName = newName);
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Leave the app demo and return to Sign In?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.signIn, (_) => false);
  }

  Widget _settingsTile(IconData icon, String title, String subtitle, VoidCallback onTap) =>
      Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  @override
  Widget build(BuildContext context) => AccountPage(
        title: 'Profile & settings',
        subtitle: 'Account access and preferences',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=760&q=75',
                height: 126,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) => Container(
                  height: 126,
                  color: AppColors.accent,
                  alignment: Alignment.center,
                  child: const Icon(Icons.storefront, size: 56, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('PROFILE', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(_ownerName),
                subtitle: Text(_storeName),
              ),
            ),
            const SizedBox(height: 20),
            Text('STORE SETTINGS', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            _settingsTile(Icons.store_outlined, 'Edit store information', _storeName, _editStore),
            const SizedBox(height: 12),
            Text('APPEARANCE', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Card(
              child: SwitchListTile.adaptive(
                title: const Text('Dark mode'),
                subtitle: const Text('Switch between light and dark themes'),
                secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: widget.onThemeChanged,
              ),
            ),
            const SizedBox(height: 12),
            Text('ACCOUNT SECURITY', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            _settingsTile(
              Icons.lock_outline,
              'Change password',
              'Password reset UI preview',
              () => Navigator.pushNamed(context, AppRoutes.resetPassword),
            ),
            const SizedBox(height: 17),
            AccountPrimaryButton(
              label: 'Save preferences',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo preferences are saved on this device.')),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
            const DemoNotice(),
          ],
        ),
      );
}
