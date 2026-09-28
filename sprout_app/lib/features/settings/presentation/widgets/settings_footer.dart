import 'package:flutter/material.dart';

import 'package:sprout/core/core.dart';
import 'package:sprout/core/debug/debug_entry_gesture_sequence.dart';
import 'package:sprout/ui/export.dart';

class SettingsFooter extends StatefulWidget {
  const SettingsFooter({
    super.key,
    required this.versionLabel,
    required this.busy,
    required this.onSignOut,
    required this.onPrivacy,
    required this.onTerms,
    this.onVersionDebugEntry,
  });

  final String? versionLabel;
  final bool busy;
  final VoidCallback onSignOut;
  final VoidCallback onPrivacy;
  final VoidCallback onTerms;

  /// Hidden PROD debug entry (#114): double-tap then long-press on version.
  ///
  /// Caller must gate (silent no-op when `debug_lens_enabled` is off). The
  /// version label stays plain metadata with no affordance chrome.
  final VoidCallback? onVersionDebugEntry;

  @override
  State<SettingsFooter> createState() => _SettingsFooterState();
}

class _SettingsFooterState extends State<SettingsFooter> {
  final DebugEntryGestureSequence _debugEntrySequence =
      DebugEntryGestureSequence();

  static final ButtonStyle _linkStyle = TextButton.styleFrom(
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.compact,
    minimumSize: Size.zero,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );

  void _onVersionDoubleTap() {
    if (widget.onVersionDebugEntry == null) return;
    _debugEntrySequence.onDoubleTap();
  }

  void _onVersionLongPress() {
    final onEntry = widget.onVersionDebugEntry;
    if (onEntry == null) return;
    if (!_debugEntrySequence.onLongPress()) return;
    onEntry();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SproutOutlinedButton.icon(
          identifier: SemanticsIds.accountSignOut,
          label: AppStrings.signOut,
          onPressed: widget.busy ? null : widget.onSignOut,
          icon: widget.busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.error,
                  ),
                )
              : Icon(Icons.logout_rounded, color: scheme.error),
          labelWidget: Text(
            AppStrings.signOut,
            style: textTheme.labelLarge?.copyWith(color: scheme.error),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.error,
            side: BorderSide(color: scheme.error.withValues(alpha: 0.45)),
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppStrings.appTitle,
          style: textTheme.titleMedium?.copyWith(color: AppColors.seed),
        ),
        if (widget.versionLabel != null) ...[
          const SizedBox(height: 2),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTap: widget.onVersionDebugEntry == null
                ? null
                : _onVersionDoubleTap,
            onLongPress: widget.onVersionDebugEntry == null
                ? null
                : _onVersionLongPress,
            child: Semantics(
              identifier: SemanticsIds.settingsAppVersion,
              container: true,
              child: Text(
                widget.versionLabel!,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SproutTextButton(
              identifier: SemanticsIds.accountPrivacy,
              label: AppStrings.privacyPolicy,
              onPressed: widget.busy ? null : widget.onPrivacy,
              style: _linkStyle,
              child: Text(
                AppStrings.privacyPolicy,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
              ),
            ),
            Text(
              '·',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            SproutTextButton(
              identifier: SemanticsIds.accountTerms,
              label: AppStrings.termsOfService,
              onPressed: widget.busy ? null : widget.onTerms,
              style: _linkStyle,
              child: Text(
                AppStrings.termsOfService,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
