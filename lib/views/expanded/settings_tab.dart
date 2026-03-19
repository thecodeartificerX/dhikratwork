// lib/views/expanded/settings_tab.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dhikratwork/viewmodels/settings_viewmodel.dart';
import 'package:dhikratwork/views/settings/hotkey_record_dialog.dart';

/// The Settings tab in the expanded shell.
/// Sections: Global Hotkey, Subscription, Data Export, About.
class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().loadSettings();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _recordHotkey() async {
    final newHotkey = await showDialog<String>(
      context: context,
      builder: (_) => const HotkeyRecordDialog(),
    );
    if (newHotkey != null && mounted) {
      await context.read<SettingsViewModel>().changeHotkey(newHotkey);
    }
  }

  Future<void> _verifySubscription() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    await context.read<SettingsViewModel>().verifySubscription(email);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<SettingsViewModel>();

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Global Hotkey ────────────────────────────────────────────────
            _SectionHeader(title: 'Global Hotkey'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.keyboard, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Current hotkey:',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          child: SelectableText(
                            vm.hotkeyString,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (vm.hotkeyError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        vm.hotkeyError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _recordHotkey,
                      icon: const Icon(Icons.fiber_manual_record, size: 16),
                      label: const Text('Record New'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Subscription ─────────────────────────────────────────────────
            _SectionHeader(title: 'Subscription'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vm.isSubscribed) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: theme.colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Subscribed',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (vm.subscriptionEmail != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          vm.subscriptionEmail!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Unlock premium features with a subscription.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _launchUrl(
                          'https://dhikratwork.app/subscribe',
                        ),
                        child: const Text('Subscribe — \$5/month'),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Already subscribed? Verify your email:',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: 'your@email.com',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: vm.isVerifyingSubscription
                                ? null
                                : _verifySubscription,
                            child: vm.isVerifyingSubscription
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Verify'),
                          ),
                        ],
                      ),
                    ],
                    if (vm.subscriptionError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        vm.subscriptionError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Data Export ──────────────────────────────────────────────────
            _SectionHeader(title: 'Data Export'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export your dhikr data to a file.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: vm.isExporting
                              ? null
                              : () => context
                                  .read<SettingsViewModel>()
                                  .exportData('json'),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export JSON'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: vm.isExporting
                              ? null
                              : () => context
                                  .read<SettingsViewModel>()
                                  .exportData('csv'),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export CSV'),
                        ),
                        if (vm.isExporting) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    if (vm.exportError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        vm.exportError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── About ────────────────────────────────────────────────────────
            _SectionHeader(title: 'About'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DhikrAtWork',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'An Islamic dhikr tracking desktop app.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _launchUrl('https://dhikratwork.app'),
                      child: const Text('dhikratwork.app'),
                    ),
                    TextButton(
                      onPressed: () => _launchUrl(
                        'https://dhikratwork.app/privacy',
                      ),
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.primary,
      ),
    );
  }
}
