import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyOnboardingComplete = 'onboarding_complete';

Future<bool> hasSeenOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_keyOnboardingComplete) ?? false;
}

Future<void> setOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_keyOnboardingComplete, true);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    this.isTutorial = false,
  });

  final VoidCallback onComplete;
  final bool isTutorial;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    {
      'icon': Icons.music_note_rounded,
      'title': 'Bienvenido a CoroApp',
      'subtitle': 'Tu repertorio de coro, organizado por voz y listo para ensayar.',
    },
    {
      'icon': Icons.people_rounded,
      'title': 'Elige tu coro y voz',
      'subtitle': 'Selecciona tu coro e indica tu tipo de voz: tenor, bajo, contralto o soprano.',
    },
    {
      'icon': Icons.play_circle_outline_rounded,
      'title': 'Letras y audios',
      'subtitle': 'Accede a la letra en PDF, escucha tu pista o abre el contenido con la app que prefieras.',
    },
    {
      'icon': Icons.celebration_rounded,
      'title': '¡Listo para cantar!',
      'subtitle': 'Todo tu repertorio a mano. Comienza ahora.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (widget.isTutorial)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page['icon'] as IconData,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          page['title'] as String,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['subtitle'] as String,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.8),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (!widget.isTutorial) {
                      await setOnboardingComplete();
                    }
                    widget.onComplete();
                  },
                  child: Text(widget.isTutorial ? 'Entendido' : 'Comenzar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
