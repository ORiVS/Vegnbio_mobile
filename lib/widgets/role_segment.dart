import 'package:flutter/material.dart';

class RoleSegment extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const RoleSegment({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'CLIENT', label: Text('Client')),
        ButtonSegment(value: 'FOURNISSEUR', label: Text('Fournisseur')),
        ButtonSegment(value: 'RESTAURATEUR', label: Text('Restaurateur')),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
