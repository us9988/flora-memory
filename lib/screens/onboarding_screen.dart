import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../l10n/app_strings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<_OnboardingPage> get _pages => [
    _OnboardingPage(
      emoji: '🌸',
      title: AppStrings.onboardingTitle,
      subtitle: AppStrings.onboardingSubtitle,
      isWelcome: true,
    ),
    _OnboardingPage(
      emoji: '📷',
      title: AppStrings.step1Title,
      subtitle: AppStrings.step1Sub,
      step: 1,
    ),
    _OnboardingPage(
      emoji: '🔍',
      title: AppStrings.step2Title,
      subtitle: AppStrings.step2Sub,
      step: 2,
    ),
    _OnboardingPage(
      emoji: '📖',
      title: AppStrings.step3Title,
      subtitle: AppStrings.step3Sub,
      step: 3,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    await StorageService.setOnboardingDone();
    if (mounted) context.go('/home');
  }

  Future<void> _skip() async {
    await StorageService.setOnboardingDone();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: _currentPage == 0
                    ? const SizedBox(height: 40)
                    : GestureDetector(
                        onTap: _skip,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            AppStrings.skip,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFB5A89E),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D2520),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == 0
                            ? AppStrings.start
                            : _currentPage == _pages.length - 1
                            ? AppStrings.startRecording
                            : AppStrings.next,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF2D2520)
                              : const Color(0xFFE0DCD6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(page.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 32),
          if (page.step != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'STEP ${page.step}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB5A89E),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: page.isWelcome ? 28 : 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D2520),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFFB5A89E),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String emoji, title, subtitle;
  final int? step;
  final bool isWelcome;
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.step,
    this.isWelcome = false,
  });
}
