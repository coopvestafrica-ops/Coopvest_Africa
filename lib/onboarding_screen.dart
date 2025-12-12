import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  final List<_OnboardingPageData> _pages = const [
    _OnboardingPageData(
      icon: Icons.groups,
      title: 'Welcome to Coopvest Africa',
      description: 'Your cooperative platform for salaried earners. Save, borrow, and grow together.',
      imageAsset: 'assets/images/onboarding/1.png',
    ),
    _OnboardingPageData(
      icon: Icons.savings,
      title: 'Save & Earn',
      description: 'Contribute and grow your savings with other members.',
      imageAsset: 'assets/images/onboarding/2.png',
    ),
    _OnboardingPageData(
      icon: Icons.handshake,
      title: 'Borrow Easily',
      description: 'Access loans with flexible repayment options.',
      imageAsset: 'assets/images/onboarding/3.png',
    ),
    _OnboardingPageData(
      icon: Icons.dashboard,
      title: 'Easy Access',
      description: 'Secure in-app wallet for savings, loan disbursements, and transfers.',
      imageAsset: 'assets/images/onboarding/4.png',
    ),
    _OnboardingPageData(
      icon: Icons.rocket_launch,
      title: 'Get Started',
      description: 'Earn rewards for inviting coworkers. Use QR scan to add guarantors or referrals. Join us at Coopvest and empower your financial future.',
      imageAsset: 'assets/images/onboarding/5.png',
    ),
    
  ];

  Future<void> _markOnboardingAsComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
    } catch (e) {
      debugPrint('Error saving onboarding status: $e');
    }
  }

  Future<void> _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final navigator = Navigator.of(context);
      await _markOnboardingAsComplete();
      if (!mounted) return;
      
      navigator.pushReplacementNamed('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    await _markOnboardingAsComplete();
                    if (!mounted) return;
                    navigator.pushReplacementNamed('/signup');
                  },
                  child: Text(
                    'Skip',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 180,
                          width: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[200],
                          ),
                          child: page.imageAsset.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    page.imageAsset,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Error loading image: $error');
                                      return Icon(
                                        page.icon,
                                        size: 80,
                                        color: Theme.of(context).colorScheme.primary,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  page.icon,
                                  size: 80,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (index == _pages.length - 1) ...[
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 26),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  'Coopvest Africa Mission',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'This mission aligns with Coopvest Africa’s goal of creating a trusted digital cooperative platform that supports wealth-building, financial education, and economic stability for its members across Africa.',
                                  style: TextStyle(fontSize: 15, color: Colors.black87),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(_pages.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 20 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: _currentPage == index 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      );
                    }),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 48),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final String imageAsset;
  
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.imageAsset,
  });
}
