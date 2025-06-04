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
      description: 'Tu compañero financiero personal que te ayuda a tomar el control de tus finanzas. Organiza tus gastos, establece presupuestos y alcanza tus metas financieras.',
    ),
    _OnboardingPageData(
      icon: Icons.security,
      title: 'Privacidad Primero',
      description: 'Tus datos financieros son 100% privados y se almacenan localmente en tu dispositivo. No recolectamos información personal ni la compartimos con terceros. Tu privacidad es nuestra prioridad.',
    ),
    _OnboardingPageData(
      icon: Icons.sync,
      title: 'Respaldo de Datos',
      description: 'Exporta tus datos financieros cuando quieras para tener un respaldo seguro. Puedes importarlos en cualquier momento o en otro dispositivo, manteniendo el control total de tu información.',
    ),
    _OnboardingPageData(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Gastos Hormiga',
      description: 'Registra tus gastos hormiga diarios por categorías, visualiza tu saldo disponible y mantén un registro detallado de cada movimiento. Ideal para controlar gastos pequeños que pueden sumar mucho.',
    ),
    _OnboardingPageData(
      icon: Icons.calendar_month,
      title: 'Presupuesto Mensual',
      description: 'Configura tus ingresos y gastos fijos mensuales como salario, arriendo, servicios, etc. El sistema los copiará automáticamente cada mes para que no tengas que ingresarlos de nuevo.',
    ),
    _OnboardingPageData(
      icon: Icons.pie_chart,
      title: 'Categorización Inteligente',
      description: 'Organiza tus gastos en categorías predefinidas siguiendo la regla 50/30/20: 50% para necesidades básicas, 30% para gastos personales y 20% para ahorro e inversión.',
    ),
    _OnboardingPageData(
      icon: Icons.bar_chart,
      title: 'Informes Detallados',
      description: 'Analiza tus patrones de gasto con gráficos intuitivos, compara meses anteriores y descubre oportunidades de ahorro. Visualiza el impacto de tus gastos hormiga en tu presupuesto.',
    ),
    _OnboardingPageData(
      icon: Icons.summarize,
      title: 'Resumen Financiero',
      description: 'Accede a un panorama completo de tus finanzas con resúmenes mensuales y anuales. Visualiza tu progreso y toma decisiones informadas sobre tu dinero.',
    ),
    _OnboardingPageData(
      icon: Icons.savings_outlined,
      title: 'Próximamente: Ahorro',
      description: 'Establece metas de ahorro, crea fondos de emergencia y haz seguimiento de tu progreso (+). Te ayudaremos a desarrollar hábitos de ahorro saludables y alcanzar tus objetivos financieros.',
    ),
    _OnboardingPageData(
      icon: Icons.credit_card,
      title: 'Próximamente: Gestión de Deudas',
      description: 'Organiza tus deudas, tarjetas de crédito y préstamos (+). Crea estrategias de pago, calcula intereses y visualiza tu camino hacia la libertad financiera.',
    ),
    _OnboardingPageData(
      icon: Icons.ondemand_video,
      title: 'Publicidad en la App',
      description: 'Para mantener la app gratuita y seguir mejorándola, verás banners publicitarios en cada sección y videos ocasionales en los informes. Tu apoyo nos permite seguir desarrollando nuevas funciones.',
    ),
    _OnboardingPageData(
      icon: Icons.celebration,
      title: '¡Comienza tu Viaje Financiero!',
      description: '¡Es hora de tomar el control de tus finanzas! Empieza registrando tus ingresos y gastos fijos del mes, y luego añade tus gastos diarios. ¡Tu futuro financiero comienza hoy!',
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
                                              'Esta app respeta tu privacidad:\n\n'
                                              '• Tus datos financieros se almacenan localmente en tu dispositivo\n'
                                              '• No recolectamos información personal\n'
                                              '• No compartimos tus datos con terceros\n'
                                              '• Puedes exportar/importar tus datos cuando quieras\n\n'
                                              'La app utiliza Google AdMob para mostrar anuncios. Los datos de uso pueden ser compartidos con Google solo para personalizar la publicidad. Para más información, consulta nuestra política de privacidad completa en:',
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