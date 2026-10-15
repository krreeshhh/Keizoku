import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/firebase_service.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'dialogs.dart';
import 'glass.dart';
import 'liquid_notch.dart';

Future<String?> showHandlePromptDialog(
  BuildContext context, {
  required String currentHandle,
  String? reason,
  bool barrierDismissible = false,
}) {
  return showAppDialog<String>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dctx) => PopScope(
      canPop: barrierDismissible,
      child: _HandlePromptDialog(
        currentHandle: currentHandle,
        reason: reason,
        canCancel: barrierDismissible,
      ),
    ),
  );
}

class _HandlePromptDialog extends StatefulWidget {
  const _HandlePromptDialog({
    required this.currentHandle,
    this.reason,
    required this.canCancel,
  });

  final String currentHandle;
  final String? reason;
  final bool canCancel;

  @override
  State<_HandlePromptDialog> createState() => _HandlePromptDialogState();
}

class _HandlePromptDialogState extends State<_HandlePromptDialog> {
  late final TextEditingController _ctrl;
  Timer? _debounce;
  bool _checking = false;
  bool? _isAvailable;
  bool _claiming = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentHandle);
    if (_ctrl.text.isNotEmpty) {
      _checkAvailability(_ctrl.text);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String val) {
    _debounce?.cancel();
    final clean = val.trim().toLowerCase().replaceAll('@', '').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (clean.isEmpty) {
      setState(() {
        _isAvailable = null;
        _checking = false;
        _error = 'Username cannot be empty';
      });
      return;
    }
    setState(() {
      _checking = true;
      _isAvailable = null;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 320), () => _checkAvailability(clean));
  }

  Future<void> _checkAvailability(String clean) async {
    final available = await firebaseService.isHandleAvailable(clean);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _isAvailable = available;
      if (!available) {
        _error = '@$clean is already taken by another athlete';
      } else {
        _error = null;
      }
    });
  }

  Future<void> _submit() async {
    final clean = _ctrl.text.trim().toLowerCase().replaceAll('@', '').replaceAll(RegExp(r'[^a-z0-9_]'), '');
    if (clean.isEmpty) return;

    setState(() => _claiming = true);
    final ok = await firebaseService.claimHandle(clean);
    if (!mounted) return;
    setState(() => _claiming = false);

    if (ok) {
      fit.setProfileHandle(clean);
      await firebaseService.syncUserProfile();
      if (!mounted) return;
      showNotchToast(
        context,
        'Username Claimed! ✓',
        subtitle: 'You are now known as @$clean',
        icon: PhosphorIconsFill.checkCircle,
        accent: context.gc.sage,
      );
      Navigator.of(context).pop(clean);
    } else {
      setState(() {
        _isAvailable = false;
        _error = '@$clean was just claimed. Please choose another.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final canSubmit = !_checking && !_claiming && _isAvailable == true && _ctrl.text.trim().isNotEmpty;

    return appDialog(
      gc,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: gc.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(PhosphorIconsBold.at, size: 20, color: gc.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Choose Unique Handle',
              style: AppTheme.f(18, weight: FontWeight.w800, color: gc.text),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.reason != null) ...[
            Text(
              widget.reason!,
              style: AppTheme.f(13.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _ctrl,
            onChanged: _onChanged,
            autofocus: true,
            style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text),
            cursorColor: gc.accent,
            decoration: InputDecoration(
              filled: true,
              fillColor: gc.bgRaised2,
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 6),
                child: Text('@', style: AppTheme.f(15, weight: FontWeight.w800, color: gc.textSecondary)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: _checking
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: gc.accent)),
                    )
                  : _isAvailable == true
                      ? Icon(PhosphorIconsBold.checkCircle, color: gc.sage, size: 20)
                      : _isAvailable == false
                          ? Icon(PhosphorIconsBold.warningCircle, color: gc.danger, size: 20)
                          : null,
              hintText: 'your_username',
              hintStyle: AppTheme.f(15, color: gc.textTertiary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(PhosphorIconsFill.warning, size: 14, color: gc.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: AppTheme.f(12, weight: FontWeight.w600, color: gc.danger),
                  ),
                ),
              ],
            ),
          ] else if (_isAvailable == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(PhosphorIconsFill.checkCircle, size: 14, color: gc.sage),
                const SizedBox(width: 6),
                Text(
                  'Username is available!',
                  style: AppTheme.f(12, weight: FontWeight.w600, color: gc.sage),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (widget.canCancel)
          dialogAction('Cancel', gc.textSecondary, () => Navigator.of(context).pop(null), strong: false),
        dialogAction(
          _claiming ? 'Saving...' : 'Confirm',
          canSubmit ? gc.accent : gc.textTertiary,
          canSubmit ? _submit : () {},
        ),
      ],
    );
  }
}
