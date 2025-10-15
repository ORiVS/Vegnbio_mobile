// lib/screens/vetbot/vegbot_chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vetbot_models.dart';
import '../../providers/vetbot_providers.dart';

// Palette locale (vert inhé, orange, rouge)
const _green = Color(0xFF2E7D32);
const _orange = Color(0xFFEF6C00);
const _red = Color(0xFFC62828);
const _chipBg = Color(0xFFF1F5F3);

class VegbotChatScreen extends ConsumerStatefulWidget {
  static const route = '/vegbot';
  const VegbotChatScreen({super.key});

  @override
  ConsumerState<VegbotChatScreen> createState() => _VegbotChatScreenState();
}

class _VegbotChatScreenState extends ConsumerState<VegbotChatScreen> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    ref.read(chatProvider.notifier).sendUserText(t);
    _ctrl.clear();
    // auto-scroll après un léger délai
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) _scroll.animateTo(
        _scroll.position.maxScrollExtent + 180,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vegbot', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              itemCount: state.items.length,
              itemBuilder: (c, i) {
                final item = state.items[i];
                if (item is ChatText) return _BubbleText(item: item);
                if (item is ChatResult) return _ResultCard(item: item);
                return const SizedBox.shrink();
              },
            ),
          ),
          if (state.loading) const _LoaderBar(),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(state.error!, style: const TextStyle(color: Colors.red)),
            ),
          _Composer(
            controller: _ctrl,
            onSend: _send,
            onQuick: (t) => ref.read(chatProvider.notifier).quickPrompt(t),
          ),
        ],
      ),
    );
  }
}

// ===== Chat bubbles =====
class _BubbleText extends StatelessWidget {
  final ChatText item;
  const _BubbleText({required this.item});

  @override
  Widget build(BuildContext context) {
    final isUser = item.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? _green.withOpacity(0.12) : const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isUser ? _green.withOpacity(0.35) : Colors.grey.shade300),
        ),
        child: Text(
          item.text,
          style: TextStyle(
            color: isUser ? _green : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ===== Composer + quick chips =====
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final void Function(String) onQuick;
  const _Composer({required this.controller, required this.onSend, required this.onQuick});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: -6,
            children: [
              for (final s in const [
                'Mon chien vomit',
                'Mon chat tousse',
                'Mon chien est apathique',
                'Mon chat ne mange plus'
              ])
                ActionChip(
                  label: Text(s),
                  backgroundColor: _chipBg,
                  onPressed: () => onQuick(s),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Décrivez le souci de votre animal…',
                      filled: true,
                      fillColor: const Color(0xFFF7F7F8),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'send',
                  backgroundColor: _green,
                  onPressed: onSend,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Result card (triage + hypotheses + red flags + advice) =====
class _ResultCard extends StatefulWidget {
  final ChatResult item;
  const _ResultCard({required this.item});
  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> with SingleTickerProviderStateMixin {
  bool _expanded = false;
  String _animatedAdvice = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final advice = widget.item.result.advice;
    if (advice.length <= 300) {
      _typeWriter(advice);
    } else {
      _animatedAdvice = advice;
    }
  }

  void _typeWriter(String full) {
    int i = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 12), (t) {
      if (i >= full.length) return t.cancel();
      setState(() => _animatedAdvice = full.substring(0, i++));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _triageColor(TriageLevel l) {
    switch (l) {
      case TriageLevel.high:   return _red;
      case TriageLevel.medium: return _orange;
      case TriageLevel.low:    return _green;
    }
  }

  String _triageLabel(TriageLevel l) {
    switch (l) {
      case TriageLevel.high:   return 'Urgence élevée';
      case TriageLevel.medium: return 'Surveillance renforcée';
      case TriageLevel.low:    return 'Faible urgence';
    }
  }

  /// Conseils dynamiques **front** si l’IA n’a pas reformulé.
  String? _frontExtraTips() {
    if (!widget.item.usedFallbackAdvice) return null;
    final tri = widget.item.result.triage;
    final first = widget.item.result.differential.isNotEmpty ? widget.item.result.differential.first : null;
    if (first == null) return null;

    final disease = first.disease;
    switch (tri) {
      case TriageLevel.high:
        return "⚠️ Votre description suggère un risque important. Évitez toute nourriture, "
            "laissez de l’eau à disposition, gardez votre animal au calme et surveillez la respiration. ";
      case TriageLevel.medium:
        return "ℹ️ À surveiller de près. Limitez l’effort, fractionnez l’eau/les repas. "
            "Si l’état se dégrade ou si des signaux d’alerte apparaissent, consultez.";
      case TriageLevel.low:
        return "🙂 Sur la base des éléments, $disease est possible mais peu grave dans l’immédiat. "
            "Observez 6–12 h, réintroduisez l’alimentation progressivement si les symptômes régressent.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.item.result;
    final color = _triageColor(r.triage);

    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 180),
      child: Card(
        elevation: 0.8,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bannière triage
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _triageLabel(r.triage),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                    _Thermometer(level: r.triage),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Hypothèses
              if (r.differential.isNotEmpty) ...[
                Row(
                  children: [
                    const Text('Hypothèses', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => setState(()=>_expanded = !_expanded),
                      icon: Icon(_expanded ? Icons.unfold_less : Icons.unfold_more),
                      label: Text(_expanded ? 'Réduire' : 'Voir détails'),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  firstChild: _HypothesesList(list: r.differential),
                  secondChild: const SizedBox.shrink(),
                  crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                ),
                const SizedBox(height: 8),
              ],

              // Red flags
              if (r.redFlags.isNotEmpty) ...[
                const Text('Signaux d’alerte', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: r.redFlags.map((t) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(t)),
                      ],
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Advice (IA ou fallback) + tips front si fallback
              const Text('Conseils', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(_animatedAdvice),
              const SizedBox(height: 8),
              if (_frontExtraTips() != null)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Text(_frontExtraTips()!),
                ),

              const SizedBox(height: 12),
              const Divider(height: 20),
              const Text(
                "Ce service n’est pas un diagnostic. Consultez votre vétérinaire.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HypothesesList extends StatelessWidget {
  final List<Hypothesis> list;
  const _HypothesesList({required this.list});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: list.map((h) {
        final pct = (h.prob * 100).clamp(0, 100).toStringAsFixed(1);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${h.disease} — $pct %', style: const TextStyle(fontWeight: FontWeight.w700)),
              if (h.why.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(h.why, style: const TextStyle(color: Colors.black87)),
              ]
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _Thermometer extends StatelessWidget {
  final TriageLevel level;
  const _Thermometer({required this.level});

  @override
  Widget build(BuildContext context) {
    final stops = {
      TriageLevel.low: 0.33,
      TriageLevel.medium: 0.66,
      TriageLevel.high: 1.0,
    }[level]!;
    return SizedBox(
      width: 84, height: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          children: [
            Container(color: Colors.grey.shade200),
            LayoutBuilder(builder: (_, c) {
              final w = c.maxWidth * stops;
              final color = {
                TriageLevel.low: _green,
                TriageLevel.medium: _orange,
                TriageLevel.high: _red,
              }[level]!;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: w, height: c.maxHeight, color: color,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LoaderBar extends StatefulWidget {
  const _LoaderBar();
  @override
  State<_LoaderBar> createState() => _LoaderBarState();
}

class _LoaderBarState extends State<_LoaderBar> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() { _ac.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(valueColor: _ac.drive(ColorTween(begin: _green, end: _orange)));
  }
}
