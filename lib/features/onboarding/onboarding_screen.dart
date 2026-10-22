import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/spacing.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_provider.dart';

/// Three-screen first-run experience.
///
/// Notification permission is requested on the final step — *after* explaining
/// why it matters — rather than on cold launch.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _requesting = false;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.event_available_rounded,
      title: 'Never miss an important deadline',
      body:
          'See what is overdue, what is due today and what is coming up the '
          'moment you open the app.',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_rounded,
      title: 'Set reminders that work for you',
      body:
          'Stack several reminders on one task — a day before, a few hours '
          'before, and right at the deadline. They arrive even when the app is closed.',
    ),
    _OnboardingPage(
      icon: Icons.self_improvement_rounded,
      title: 'Stay organised without the mental load',
      body:
          'Capture a task in seconds, break it into subtasks and let DueMate '
          'keep track of the clock for you.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _requesting ? null : _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _PageView(page: _pages[index]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? scheme.primary : scheme.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _requesting
                      ? null
                      : (isLast ? _requestPermissionAndFinish : _next),
                  child: _requesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isLast ? 'Get started' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Future<void> _requestPermissionAndFinish() async {
    setState(() => _requesting = true);
    try {
      final service = ref.read(notificationServiceProvider);
      await service.initialize();
      await service.requestPermissions();
    } catch (_) {
      // A denied or failed permission must not block finishing onboarding.
    }
    await _finish();
  }

  Future<void> _finish() async {
    await ref.read(settingsControllerProvider).completeOnboarding();
    widget.onFinished();
  }
}

class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: AppRadius.xlAll,
            ),
            child: Icon(page.icon, size: 44, color: scheme.primary),
          ),
          const SizedBox(height: Spacing.xxxl),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headline,
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
