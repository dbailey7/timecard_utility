import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'timecard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Called by "Get Started" (last page) and "Skip" (all other pages).
  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      // Launched from ❓ tap — just go back to the main screen.
      Navigator.pop(context);
    } else {
      // Initial launch — replace with main screen.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TimecardScreen()),
      );
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Pager ─────────────────────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _page1(),
                  _page2(),
                  _page3(),
                  _page4(),
                ],
              ),
            ),

            // ── Dots + Buttons ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final bool active = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width:  active ? 10 : 8,
                        height: active ? 10 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? kPrimary : const Color(0xFFBDBDBD),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  if (_currentPage < _totalPages - 1) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Next',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    TextButton(
                      onPressed: _complete,
                      child: Text('Skip',
                          style: TextStyle(color: kPrimary)),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _complete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Get Started',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Page 1: Welcome ────────────────────────────────────────────────────────
  Widget _page1() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⏱️', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          const Text('Timecard Utility',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kPrimary)),
          const SizedBox(height: 12),
          Text(
            'Payroll math made simple.\n'
            'Convert, add up, or calculate elapsed time — in seconds.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: kTextSecondary),
          ),
        ],
      ),
    );
  }

  // ── Page 2: Three Modes ───────────────────────────────────────────────────
  Widget _page2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Three Modes',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary)),
          const SizedBox(height: 20),
          _modeCard(
            'Convert',
            '1.75  →  1 Hour, 45 Minutes\n8:30  →  8.5 decimal hours',
            'Enter a decimal number or clock time — get the other format instantly.',
          ),
          const SizedBox(height: 12),
          _modeCard(
            'Add Up',
            '1.5 + 0.25 + 0.5  →  2 Hours, 15 Minutes',
            'Add, subtract, multiply, or divide up to 5 decimal-hour values.',
          ),
          const SizedBox(height: 12),
          _modeCard(
            'Elapsed Time',
            '10:30 AM 1.5  →  12:00:00 PM',
            'Enter a start time (HH:MM AM/PM) then the duration in decimal hours.',
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _modeCard(String title, String example, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimary)),
          const SizedBox(height: 6),
          Text(example,
              style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Courier New',
                  color: kTextPrimary)),
          const SizedBox(height: 6),
          Text(description,
              style: const TextStyle(fontSize: 13, color: kTextSecondary)),
        ],
      ),
    );
  }

  // ── Page 3: How to Use ────────────────────────────────────────────────────
  Widget _page3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('How to Use',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary)),
          const SizedBox(height: 20),
          _stepCard('1', 'Enter your value',
              'Use the keypad to type a decimal number, expression, or elapsed time. '
              'Tap AM / PM / SPACE as needed for elapsed-time entries.'),
          const SizedBox(height: 16),
          _stepCard('2', 'Tap Convert',
              'The result appears immediately above the keypad.'),
          const SizedBox(height: 16),
          _stepCard('3', 'Need help?',
              'Tap ❓ in the top-right corner to view this guide again at any time.'),
          const SizedBox(height: 16),
          _stepCard('4', 'Start over',
              'Tap Clear to reset the input and result.'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _stepCard(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
              color: kPrimary, shape: BoxShape.circle),
          child: Center(
            child: Text(number,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary)),
              const SizedBox(height: 4),
              Text(description,
                  style: const TextStyle(
                      fontSize: 13, color: kTextSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Page 4: You're Ready! ─────────────────────────────────────────────────
  Widget _page4() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('✅', style: TextStyle(fontSize: 72)),
          SizedBox(height: 24),
          Text("You're Ready!",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary)),
          SizedBox(height: 12),
          Text(
            'Timecard Utility is ready to help you with payroll math.\n'
            'Tap Get Started to begin.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: kTextSecondary),
          ),
        ],
      ),
    );
  }
}
