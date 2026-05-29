import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../timecard_notifier.dart';
import 'onboarding_screen.dart';

class TimecardScreen extends StatefulWidget {
  const TimecardScreen({super.key});

  @override
  State<TimecardScreen> createState() => _TimecardScreenState();
}

class _TimecardScreenState extends State<TimecardScreen> {
  TimecardNotifier? _notifier;

  @override
  void initState() {
    super.initState();
    // Provider isn't accessible in initState directly — use post-frame callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier = context.read<TimecardNotifier>();
      _notifier!.addListener(_handleToast);
    });
  }

  @override
  void dispose() {
    _notifier?.removeListener(_handleToast);
    super.dispose();
  }

  void _handleToast() {
    final msg = _notifier?.toastMessage;
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _notifier?.clearToast();
    }
  }

  // ── ❓ tap: show onboarding ──────────────────────────────────────────────
  void _showHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }

  // ── ❓ long-press: confirmation dialog → reset to first-run ─────────────
  void _showResetDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset'),
        content: const Text('Reset to first-run experience?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('onboarding_done');
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              context.read<TimecardNotifier>().clearAll();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                // ignore: use_build_context_synchronously
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (_) => false,
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TimecardNotifier>();

    return Scaffold(
      backgroundColor: kAppBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // ── Header ───────────────────────────────────────────────────────
              // Row with a mirrored left spacer keeps the title truly centred
              // while the ❓ floats at the right edge — identical to Compose's
              // Box(fillMaxWidth) + Alignment.CenterEnd pattern.
              Row(
                children: [
                  // Invisible left spacer — same intrinsic width as the ❓ button
                  // so the title column is centred in the remaining space.
                  const SizedBox(width: 38),
                  Expanded(
                    child: Text(
                      'Timecard Utility',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: kPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _showHelp,
                    onLongPress: _showResetDialog,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('❓', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              const Text(
                'Enter a value, expression, or elapsed time',
                style: TextStyle(fontSize: 14, color: kTextSecondary),
              ),
              const SizedBox(height: 20),

              // ── Input Field ─────────────────────────────────────────────────
              GestureDetector(
                // Tapping anywhere on the field area keeps focus but no keyboard.
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: kCardBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: notifier.controller,
                    readOnly: true,       // prevents system keyboard
                    showCursor: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Courier New',
                      color: kTextPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g.  0.25   or   1.5+0.5   or   10:30 AM 1.5',
                      hintStyle: TextStyle(
                          fontSize: 14, color: Color(0xFFBDBDBD)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    cursorColor: kPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Convert / Clear Buttons ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: notifier.convert,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Convert',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: notifier.clearAll,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimary,
                          side: const BorderSide(color: kPrimary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Clear',
                            style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Result Display (animated) ────────────────────────────────────
              AnimatedOpacity(
                opacity: notifier.result != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: notifier.result != null
                    ? Column(
                        children: [
                          Text(
                            notifier.result!.primary,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: kPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            notifier.result!.detail,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: kTextSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      )
                    : const SizedBox(height: 0),
              ),

              // ── Keypad Divider ──────────────────────────────────────────────
              const Divider(color: kDividerColor, thickness: 1),
              const SizedBox(height: 8),
              const Text('Keypad',
                  style: TextStyle(fontSize: 12, color: kTextSecondary)),
              const SizedBox(height: 8),

              // ── Keypad ──────────────────────────────────────────────────────
              _Keypad(notifier: notifier),

            ],
          ),
        ),
      ),
    );
  }
}

// ── Keypad ─────────────────────────────────────────────────────────────────────

class _Keypad extends StatelessWidget {
  final TimecardNotifier notifier;
  const _Keypad({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: 1 2 3 +
        _KeyRow(children: [
          _KDigit('1', notifier), _KDigit('2', notifier),
          _KDigit('3', notifier), _KOp('+', notifier),
        ]),
        const SizedBox(height: 6),
        // Row 2: 4 5 6 -
        _KeyRow(children: [
          _KDigit('4', notifier), _KDigit('5', notifier),
          _KDigit('6', notifier), _KOp('-', notifier),
        ]),
        const SizedBox(height: 6),
        // Row 3: 7 8 9 *
        _KeyRow(children: [
          _KDigit('7', notifier), _KDigit('8', notifier),
          _KDigit('9', notifier), _KOp('*', notifier),
        ]),
        const SizedBox(height: 6),
        // Row 4: . 0 : /
        _KeyRow(children: [
          _KDigit('.', notifier), _KDigit('0', notifier),
          _KDigit(':', notifier), _KOp('/', notifier),
        ]),
        const SizedBox(height: 6),
        // Row 5: AM PM SPACE(2x) ⌫
        _Row5(notifier: notifier),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  final List<Widget> children;
  const _KeyRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children
          .map((w) => Expanded(child: w))
          .toList(),
    );
  }
}

// Row 5 uses custom flex weights: AM(1) PM(1) SPACE(2) ⌫(1)
class _Row5 extends StatelessWidget {
  final TimecardNotifier notifier;
  const _Row5({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 1, child: _KSpecial('AM', notifier)),
        Expanded(flex: 1, child: _KSpecial('PM', notifier)),
        Expanded(flex: 2, child: _KSpecial('SPACE', notifier)),
        Expanded(flex: 1, child: _KBack(notifier)),
      ],
    );
  }
}

// ── Individual key widgets ─────────────────────────────────────────────────────

class _KDigit extends StatelessWidget {
  final String label;
  final TimecardNotifier notifier;
  const _KDigit(this.label, this.notifier);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () => notifier.appendToInput(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: kCardBackground,
            foregroundColor: kTextPrimary,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

class _KOp extends StatelessWidget {
  final String label;
  final TimecardNotifier notifier;
  const _KOp(this.label, this.notifier);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () => notifier.appendToInput(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: kButtonSecondary,
            foregroundColor: kPrimary,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _KSpecial extends StatelessWidget {
  final String label;
  final TimecardNotifier notifier;
  const _KSpecial(this.label, this.notifier);

  @override
  Widget build(BuildContext context) {
    final String ch = label == 'SPACE' ? ' ' : label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () => notifier.appendToInput(ch),
          style: ElevatedButton.styleFrom(
            backgroundColor: kButtonSecondary,
            foregroundColor: kPrimary,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _KBack extends StatelessWidget {
  final TimecardNotifier notifier;
  const _KBack(this.notifier);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: notifier.backspace,
          style: ElevatedButton.styleFrom(
            backgroundColor: kButtonSecondary,
            foregroundColor: kPrimary,
            elevation: 1,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('⌫',
              style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
