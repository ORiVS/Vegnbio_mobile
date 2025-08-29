// lib/widgets/api_result_dialogs.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../core/api_error.dart';

Future<void> showSuccessDialog(
    BuildContext context, {
      required String title,
      List<String>? messages,
      String primaryLabel = 'OK',
      VoidCallback? onPrimary,
      String? secondaryLabel,
      VoidCallback? onSecondary,
    }) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.check_circle, color: kPrimaryGreenDark),
          SizedBox(width: 8),
          Expanded(child: Text('Succès', style: TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (messages != null && messages.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...messages.map((m) => _Bullet(m)),
          ],
        ],
      ),
      actions: [
        if (secondaryLabel != null)
          TextButton(onPressed: () { Navigator.of(context).pop(); onSecondary?.call(); }, child: Text(secondaryLabel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
          onPressed: () { Navigator.of(context).pop(); onPrimary?.call(); },
          child: Text(primaryLabel),
        ),
      ],
    ),
  );
}

Future<void> showErrorDialog(
    BuildContext context, {
      String title = 'Échec de l’opération',
      required ApiError error,
      String primaryLabel = 'Fermer',
    }) {
  final messages = error.messages;
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: const [
          Icon(Icons.error_rounded, color: Colors.red),
          SizedBox(width: 8),
          Expanded(child: Text('Erreur', style: TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...messages.map((m) => _Bullet(m)),
          ],
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(primaryLabel),
        ),
      ],
    ),
  );
}

Future<bool?> showConfirmDialog(
    BuildContext context, {
      required String title,
      String? message,
      String confirmLabel = 'Confirmer',
      String cancelLabel = 'Annuler',
    }) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: kPrimaryGreen),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
