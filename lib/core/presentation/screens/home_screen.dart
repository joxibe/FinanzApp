import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/presentation/widgets/theme_switch.dart';
import 'package:finanz_app/features/balance/presentation/screens/balance_screen.dart';
import 'package:finanz_app/features/budget/presentation/screens/budget_screen.dart';
import 'package:finanz_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:finanz_app/features/summary/presentation/screens/summary_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int? _lastInterstitialIndex;
  bool _isShowingInterstitial = false;
  Timer? _interstitialTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _interstitialTimer?.cancel();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final wasInReports = _lastInterstitialIndex == 2;
    _lastInterstitialIndex = index;
    _interstitialTimer?.cancel();
    if (index == 2 && !_isShowingInterstitial) {
      // Esperar 5 segundos antes de mostrar el interstitial
      _interstitialTimer = Timer(const Duration(seconds: 5), () async {
        if (mounted && _lastInterstitialIndex == 2 && !_isShowingInterstitial) {
          setState(() {
            _isShowingInterstitial = true;
          });
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              Future.delayed(const Duration(seconds: 7), () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
              return AlertDialog(
                title: const Text('Publicidad'),
                content: const Text('Aquí se mostrará un video publicitario obligatorio.'),
              );
            },
          );
          if (mounted) {
            setState(() {
              _isShowingInterstitial = false;
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Sincronizar el PageController con el índice seleccionado
        if (_pageController.hasClients && _pageController.page?.round() != appState.selectedIndex) {
          _pageController.animateToPage(
            appState.selectedIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('¿Qué es Finanz App?'),
                    content: const Text(
                      'Finanz App te ayuda a llevar un control claro y visual de tus ingresos, gastos fijos y gastos hormiga. Navega entre las pestañas para ver tu balance diario, gestionar tu presupuesto fijo, analizar tus gastos y consultar resúmenes mensuales o anuales.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'Finanz App',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            actions: [
              ThemeSwitch(
                isDarkMode: appState.isDarkMode,
                onChanged: (value) => appState.toggleTheme(),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Información de la pantalla',
                onPressed: () {
                  String info = '';
                  String title = '';
                  switch (appState.selectedIndex) {
                    case 0:
                      title = 'Balance';
                      info = 'Consulta tu balance diario de ingresos y gastos hormiga del mes actual.';
                      break;
                    case 1:
                      title = 'Presupuesto';
                      info = 'Gestiona tus ingresos y gastos fijos mensuales y visualiza tu saldo disponible.';
                      break;
                    case 2:
                      title = 'Informes';
                      info = 'Analiza tus gastos por categoría y accede a estadísticas útiles para mejorar tus finanzas.';
                      break;
                    case 3:
                      title = 'Resumen';
                      info = 'Revisa un resumen mensual o anual de todos tus movimientos y balances.';
                      break;
                  }
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('¿Para qué sirve "$title"?'),
                      content: Text(info),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Entendido'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          // Banner publicitario fijo arriba
          body: Column(
            children: [
              Container(
                width: double.infinity,
                height: 60,
                color: Colors.amber[200],
                alignment: Alignment.center,
                child: const Text(
                  'Banner Publicitario (aquí va AdMob u otro proveedor)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: _HomeContent(
                  pageController: _pageController,
                  onPageChanged: _onPageChanged,
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: appState.selectedIndex,
            onDestinationSelected: (index) {
              appState.selectedIndex = index;
              _onPageChanged(index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
              );
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundColor: Theme.of(context).colorScheme.surface,
            animationDuration: const Duration(milliseconds: 500),
            destinations: [
              _NavigationDestination(
                icon: Icons.account_balance_wallet_outlined,
                selectedIcon: Icons.account_balance_wallet,
                label: 'Balance',
                index: 0,
                currentIndex: appState.selectedIndex,
              ),
              _NavigationDestination(
                icon: Icons.calendar_month_outlined,
                selectedIcon: Icons.calendar_month,
                label: 'Presupuesto',
                index: 1,
                currentIndex: appState.selectedIndex,
              ),
              _NavigationDestination(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart,
                label: 'Informes',
                index: 2,
                currentIndex: appState.selectedIndex,
              ),
              _NavigationDestination(
                icon: Icons.summarize_outlined,
                selectedIcon: Icons.summarize,
                label: 'Resumen',
                index: 3,
                currentIndex: appState.selectedIndex,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavigationDestination extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;
  final int currentIndex;

  const _NavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final iconColor = isSelected 
      ? Colors.white.withOpacity(0.9)
      : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7);

    return NavigationDestination(
      icon: Icon(
        icon,
        color: iconColor,
      ),
      selectedIcon: Icon(
        selectedIcon,
        color: iconColor,
      ),
      label: label,
    );
  }
}

class _HomeContent extends StatelessWidget {
  final PageController pageController;
  final void Function(int)? onPageChanged;

  const _HomeContent({
    required this.pageController,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final screens = const [
          BalanceScreen(),
          BudgetScreen(),
          ReportsScreen(),
          SummaryScreen(),
        ];

        return PageView(
          controller: pageController,
          onPageChanged: (index) {
            appState.selectedIndex = index;
            if (onPageChanged != null) onPageChanged!(index);
          },
          physics: const BouncingScrollPhysics(),
          children: screens.map((screen) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(appState.selectedIndex),
              child: screen,
            ),
          )).toList(),
        );
      },
    );
  }
} 