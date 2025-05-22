import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.account_balance_wallet,
      title: '¡Bienvenido a FinanzApp!',
      description: 'Lleva el control de tus finanzas personales de forma sencilla, visual y moderna. FinanzApp te ayuda a entender y mejorar tu salud financiera.',
    ),
    _OnboardingPageData(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Balance Diario',
      description: 'Consulta tu balance diario de ingresos y gastos hormiga del mes actual. Añade, edita y elimina movimientos fácilmente.',
    ),
    _OnboardingPageData(
      icon: Icons.calendar_month,
      title: 'Presupuesto Fijo',
      description: 'Gestiona tus ingresos y gastos fijos mensuales y visualiza tu saldo disponible para gastos variables.',
    ),
    _OnboardingPageData(
      icon: Icons.bar_chart,
      title: 'Informes y Análisis',
      description: 'Analiza tus gastos por categoría y accede a estadísticas útiles para mejorar tus finanzas.',
    ),
    _OnboardingPageData(
      icon: Icons.summarize,
      title: 'Resumen Mensual y Anual',
      description: 'Revisa un resumen mensual o anual de todos tus movimientos y balances, y accede al detalle de cada transacción.',
    ),
    _OnboardingPageData(
      icon: Icons.ondemand_video,
      title: 'Publicidad en la App',
      description: 'Para mantener la app gratuita, verás un banner en cada seccion y videos publicitarios en la sección de informes.',
    ),
    _OnboardingPageData(
      icon: Icons.celebration,
      title: '¡Comienza a usar Finanz App!',
      description: 'Ya puedes empezar a registrar tus movimientos y mejorar tu salud financiera. ¡Bienvenido!',
    ),
    _OnboardingPageData(
      icon: Icons.new_releases,
      title: '¡Nuevas funciones próximamente!',
      description: 'Si la app tiene buena recepción, se agregarán nuevas funciones y mejoras. ¡Tu opinión es importante!',
    ),
  ];

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(page.icon, size: 80, color: theme.colorScheme.primary),
                            const SizedBox(height: 32),
                            Text(
                              page.title,
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              page.description,
                              style: theme.textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            if (index == 0) ...[
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.privacy_tip_outlined),
                                label: const Text('Política de privacidad'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Política de Privacidad'),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Esta app utiliza Google AdMob para mostrar anuncios. No recopilamos información personal identificable de los usuarios. Los datos de uso pueden ser compartidos con Google para personalizar la publicidad. Para más información, consulta la política de privacidad de Google y la nuestra en el siguiente enlace:',
                                              style: TextStyle(fontSize: 15),
                                            ),
                                            SizedBox(height: 12),
                                            SelectableText(
                                              'https://joxibe.github.io/FinanzApp_Web/',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'Al usar esta app, aceptas estas condiciones.',
                                              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Cerrar'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            const url = 'https://joxibe.github.io/FinanzApp_Web/';
                                            if (await canLaunchUrl(Uri.parse(url))) {
                                              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                            }
                                          },
                                          child: Text('Abrir en navegador'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  )),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () {
                            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                          },
                          child: const Text('Atrás'),
                        )
                      else
                        const SizedBox(width: 64),
                      if (_currentPage < _pages.length - 1)
                        FilledButton(
                          onPressed: () {
                            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                          },
                          child: const Text('Siguiente'),
                        )
                      else
                        FilledButton(
                          onPressed: _finishOnboarding,
                          child: const Text('Empezar'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_currentPage < _pages.length - 1)
              Positioned(
                top: 12,
                right: 16,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: const Text('Omitir'),
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
  const _OnboardingPageData({required this.icon, required this.title, required this.description});
} 