// lib/views/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../viewmodels/settings_viewmodel.dart';
import 'dhikr_multi_select.dart';
import 'hotkey_record_dialog.dart';

/// Stripe Checkout placeholder URL. Replace with live URL before release.
const _stripeCheckoutUrl =
    'https://buy.stripe.com/placeholder_replace_before_release';

/// Donation transparency page URL.
const _donationTransparencyUrl =
    'https://dhikratwork.app/donate/transparency';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Trigger load after first frame so Provider is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().loadSettings();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsViewModel>(
        builder: (context, vm, _) {
          // Show snackbar when hotkey registration fails.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (vm.hotkeyError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(vm.hotkeyError!),
                  action: SnackBarAction(
                    label: 'Change Hotkey',
                    onPressed: () {
                      // The Global Hotkey section allows changing the hotkey.
                    },
                  ),
                  duration: const Duration(seconds: 8),
                  backgroundColor:
                      Theme.of(context).colorScheme.errorContainer,
                ),
              );
            }
          });

          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _GlobalHotkeySection(vm: vm),
                    const _SectionDivider(),
                    _FloatingWidgetSection(vm: vm),
                    const _SectionDivider(),
                    _SubscriptionSection(
                      vm: vm,
                      emailFormKey: _emailFormKey,
                      emailController: _emailController,
                    ),
                    const _SectionDivider(),
                    _DataExportSection(vm: vm),
                    const _SectionDivider(),
                    const _AboutSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Section: Global Hotkey ────────────────────────────────────────────────────

class _GlobalHotkeySection extends StatelessWidget {
  final SettingsViewModel vm;
  const _GlobalHotkeySection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Global Hotkey', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Tooltip(
              message: 'Current global hotkey combination',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  color:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: SelectableText(
                  vm.hotkeyString,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Tooltip(
              message: 'Record a new global hotkey',
              child: OutlinedButton.icon(
                icon: const Icon(Icons.keyboard),
                label: const Text('Change'),
                onPressed: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (_) => const HotkeyRecordDialog(),
                  );
                  if (result != null && context.mounted) {
                    await context
                        .read<SettingsViewModel>()
                        .updateHotkey(result);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Press this key combination from any app to count your active dhikr.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ── Section: Floating Widget ──────────────────────────────────────────────────

class _FloatingWidgetSection extends StatelessWidget {
  final SettingsViewModel vm;
  const _FloatingWidgetSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Floating Widget', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        // Toggle switch row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Show floating toolbar'),
            Tooltip(
              message: 'Toggle the always-on-top floating dhikr toolbar',
              child: Switch(
                value: vm.settings.widgetVisible,
                onChanged: (_) =>
                    context.read<SettingsViewModel>().toggleWidgetVisible(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Reset position button
        Tooltip(
          message: 'Move the floating widget back to its default position',
          child: OutlinedButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Reset Widget Position'),
            onPressed: () =>
                context.read<SettingsViewModel>().resetWidgetPosition(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Widget Dhikr List',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Select which dhikrs appear in the floating toolbar.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: DhikrMultiSelect(
            dhikrs: vm.allDhikrs,
            selectedIds: vm.widgetDhikrIdsList,
            onChanged: (ids) => context
                .read<SettingsViewModel>()
                .updateWidgetDhikrSelection(ids),
          ),
        ),
      ],
    );
  }
}

// ── Section: Subscription ─────────────────────────────────────────────────────

class _SubscriptionSection extends StatelessWidget {
  final SettingsViewModel vm;
  final GlobalKey<FormState> emailFormKey;
  final TextEditingController emailController;

  const _SubscriptionSection({
    required this.vm,
    required this.emailFormKey,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subscription', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),

        // Status row
        Row(
          children: [
            const Text('Status: '),
            SelectableText(
              vm.isSubscribed ? 'Active — Subscribed' : 'Free',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: vm.isSubscribed
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),

        if (vm.isSubscribed && vm.subscriptionEmail != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Email: '),
              SelectableText(
                vm.subscriptionEmail!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],

        const SizedBox(height: 12),

        // Subscribe button (only shown when not subscribed)
        if (!vm.isSubscribed)
          Tooltip(
            message:
                'Opens Stripe Checkout in your browser. All proceeds are donated for the sake of Allah.',
            child: FilledButton.icon(
              icon: const Icon(Icons.favorite_outline),
              label: const Text('Subscribe — \$5/month'),
              onPressed: () async {
                final uri = Uri.parse(_stripeCheckoutUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),

        const SizedBox(height: 16),
        Text(
          'Verify Subscription',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'After subscribing, enter your email to activate.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),

        // Email verification form
        Form(
          key: emailFormKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email used at checkout',
                    hintText: 'you@example.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    final emailRegex =
                        RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Check Firestore for your subscription status',
                child: FilledButton(
                  onPressed: vm.isVerifyingSubscription
                      ? null
                      : () async {
                          if (emailFormKey.currentState!.validate()) {
                            await context
                                .read<SettingsViewModel>()
                                .verifySubscription(
                                  emailController.text.trim(),
                                );
                          }
                        },
                  child: vm.isVerifyingSubscription
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
              ),
            ],
          ),
        ),

        // Subscription result / error feedback
        if (vm.subscriptionError != null) ...[
          const SizedBox(height: 8),
          Text(
            vm.subscriptionError!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (vm.isSubscribed) ...[
          const SizedBox(height: 8),
          Text(
            'Subscription verified. JazakAllahu Khayran.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ],
    );
  }
}

// ── Section: Data Export ──────────────────────────────────────────────────────

class _DataExportSection extends StatelessWidget {
  final SettingsViewModel vm;
  const _DataExportSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Data Export', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Exports all dhikrs and sessions to your Documents folder.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Tooltip(
              message: 'Export all data as JSON to Documents folder',
              child: OutlinedButton.icon(
                icon: const Icon(Icons.data_object),
                label: const Text('Export JSON'),
                onPressed: vm.isExporting
                    ? null
                    : () =>
                        context.read<SettingsViewModel>().exportData('json'),
              ),
            ),
            Tooltip(
              message: 'Export all data as CSV to Documents folder',
              child: OutlinedButton.icon(
                icon: const Icon(Icons.table_chart_outlined),
                label: const Text('Export CSV'),
                onPressed: vm.isExporting
                    ? null
                    : () =>
                        context.read<SettingsViewModel>().exportData('csv'),
              ),
            ),
            if (vm.isExporting) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const Text('Exporting...'),
            ],
          ],
        ),
        if (vm.exportError != null) ...[
          const SizedBox(height: 8),
          Text(
            vm.exportError!,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

// ── Section: About ────────────────────────────────────────────────────────────

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        SelectableText(
          'DhikrAtWork',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        // Version pulled from package_info_plus if available in future phases.
        const SelectableText('Version 1.0.0'),
        const SizedBox(height: 8),
        const Text(
          'All subscription proceeds are donated for the sake of Allah. '
          'None of the money is kept.',
        ),
        const SizedBox(height: 8),
        Tooltip(
          message: 'View full donation transparency report',
          child: TextButton.icon(
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Donation Transparency'),
            onPressed: () async {
              final uri = Uri.parse(_donationTransparencyUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Divider(),
    );
  }
}
