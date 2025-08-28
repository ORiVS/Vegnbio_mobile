import 'package:flutter/material.dart';

class PrimaryCta extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  const PrimaryCta({super.key, required this.text, this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: loading ? const CircularProgressIndicator() : Text(text),
      ),
    );
  }
}
