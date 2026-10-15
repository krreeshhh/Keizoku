import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'glass.dart';
import 'svg_icon.dart';
import 'ui_kit.dart';

Future<bool?> showRestoreAccountSheet(
  BuildContext context, {
  VoidCallback? onRestored,
}) {
  return showAppSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _RestoreAccountSheet(
      onRestored: onRestored,
    ),
  );
}

class _RestoreAccountSheet extends StatefulWidget {
  const _RestoreAccountSheet({this.onRestored});

  final VoidCallback? onRestored;

  @override
  State<_RestoreAccountSheet> createState() => _RestoreAccountSheetState();
}

class _RestoreAccountSheetState extends State<_RestoreAccountSheet> {
  final _handleController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _handleController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final handle = _handleController.text.trim();
    final code = _codeController.text.trim();

    if (handle.isEmpty) {
      setState(() => _error = 'Please enter your username / handle');
      return;
    }
    if (code.isEmpty) {
      setState(() => _error = 'Please enter your account backup code');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    FocusScope.of(context).unfocus();

    final result = await firebaseService.restoreAccountWithBackupCode(handle, code);

    if (!mounted) return;

    if (result.success) {
      HapticFeedback.mediumImpact();
      setState(() {
        _loading = false;
        _successMessage =
            'Account restored successfully! Found ${result.routinesCount} routines, ${result.friendsCount} friends, and ${result.streak}d streak.';
      });

      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (!mounted) return;

      widget.onRestored?.call();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _loading = false;
        _error = result.error ?? 'Failed to restore account. Please check details and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Container(
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: gc.border.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: gc.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIconsRegular.key, size: 22, color: gc.accent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Restore Account',
                        style: AppTheme.f(20, weight: FontWeight.w800, color: gc.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Log in with your username and backup code',
                        style: AppTheme.f(12.5, color: gc.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: gc.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gc.danger.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.warningCircle, size: 18, color: gc.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTheme.f(12.5, weight: FontWeight.w600, color: gc.danger),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_successMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: gc.sage.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: gc.sage.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsRegular.checkCircle, size: 18, color: gc.sage),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: AppTheme.f(12.5, weight: FontWeight.w600, color: gc.sage),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'USERNAME / HANDLE',
              style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: gc.bgRaised2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: gc.border.withValues(alpha: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  Text(
                    '@',
                    style: AppTheme.f(16, weight: FontWeight.w700, color: gc.accent),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: _handleController,
                      enabled: !_loading,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      style: AppTheme.f(15, weight: FontWeight.w600, color: gc.text),
                      decoration: InputDecoration(
                        hintText: 'your_username',
                        hintStyle: AppTheme.f(15, color: gc.textTertiary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'BACKUP CODE',
              style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: gc.bgRaised2,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: gc.border.withValues(alpha: 0.5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.shieldCheck, size: 18, color: gc.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      enabled: !_loading,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _restore(),
                      style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text, letterSpacing: 1.5),
                      decoration: InputDecoration(
                        hintText: 'GYM-XXXX-XXXX',
                        hintStyle: AppTheme.f(15, color: gc.textTertiary, letterSpacing: 1.5),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(PhosphorIconsRegular.clipboardText, size: 18, color: gc.accent),
                    tooltip: 'Paste',
                    onPressed: _loading
                        ? null
                        : () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null && data!.text!.isNotEmpty) {
                              _codeController.text = data.text!.trim();
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Restores all your routines, custom exercises, active streak, and community friends from cloud backup.',
              style: AppTheme.f(11.5, color: gc.textTertiary, height: 1.35),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _loading ? 'Restoring Account...' : 'Restore & Log In',
              icon: _loading ? null : Ic.checkBold,
              onTap: _loading ? null : _restore,
            ),
          ],
        ),
      ),
    ),
  ),
);
  }
}
