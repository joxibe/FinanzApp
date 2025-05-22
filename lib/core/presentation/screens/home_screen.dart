import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:finanz_app/core/domain/models/app_state.dart' as app_models;
import 'package:finanz_app/core/presentation/widgets/theme_switch.dart';
import 'package:finanz_app/features/balance/presentation/screens/balance_screen.dart';
import 'package:finanz_app/features/budget/presentation/screens/budget_screen.dart';
import 'package:finanz_app/features/reports/presentation/screens/reports_screen.dart';
import 'package:finanz_app/features/summary/presentation/screens/summary_screen.dart';
import 'package:finanz_app/core/presentation/screens/onboarding_screen.dart';
import 'dart:async';

class AdHelper {
  // IDs de producción de AdMob
  static String get bannerAdUnitId => 'ca-app-pub-7539659588201107/3038959785';
  static String get interstitialAdUnitId => 'ca-app-pub-7539659588201107/7483818860';
}

class HomeScreen extends StatefulWidget {
  final VoidCallback? onShowOnboarding;
  const HomeScreen({super.key, this.onShowOnboarding});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  int? _lastInterstitialIndex;
  bool _isShowingInterstitial = false;
  Timer? _interstitialTimer;
  
  // Variables para anuncios
  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  int _interstitialAdAttempts = 0;
  static const int maxInterstitialAttempts = 3;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadBannerAd();
    _loadInterstitialAd();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _interstitialTimer?.cancel();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdReady = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdReady = false;
          ad.dispose();
          
          Timer(const Duration(seconds: 30), () {
            if (mounted) _loadBannerAd();
          });
        },
      ),
    );

    _bannerAd!.load();
  }

  void _loadInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.dispose();
      _interstitialAd = null;
    }
    
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAdAttempts = 0;
          
          _interstitialAd!.setImmersiveMode(true);
          
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              // Ya no necesitamos actualizar _lastInterstitialShown
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (mounted) {
                setState(() {
                  _isShowingInterstitial = false;
                  _isInterstitialAdReady = false;
                });
              }
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (mounted) {
                setState(() {
                  _isShowingInterstitial = false;
                  _isInterstitialAdReady = false;
                });
              }
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
          _interstitialAdAttempts++;
          
          if (_interstitialAdAttempts <= maxInterstitialAttempts) {
            Timer(Duration(seconds: 10 * _interstitialAdAttempts), () {
              if (mounted) _loadInterstitialAd();
            });
          }
        },
      ),
    );
  }

  bool _canShowInterstitial() {
    // Ya no necesitamos verificar el intervalo
    return true;
  }

  void _showInterstitialAd() {
    if (!_canShowInterstitial()) return;
    
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      _showPlaceholderInterstitial();
    }
  }

  void _showPlaceholderInterstitial() async {
    if (!mounted) return;
    
    setState(() {
      _isShowingInterstitial = true;
    });
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return AlertDialog(
          title: const Text('Publicidad'),
          content: const Text('Aquí se mostrará un video publicitario obligatorio.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
    
    if (mounted) {
      setState(() {
        _isShowingInterstitial = false;
      });
    }
  }

  void _onPageChanged(int index) {
    _lastInterstitialIndex = index;
    _interstitialTimer?.cancel();
    
    // Mostrar intersticial en la pestaña de Informes (índice 2) después de 5 segundos
    if (index == 2 && !_isShowingInterstitial) {
      _interstitialTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _lastInterstitialIndex == 2 && !_isShowingInterstitial) {
          setState(() {
            _isShowingInterstitial = true;
          });
          _showInterstitialAd();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_models.AppState>(
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
            leading: IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: 'Ver tutorial',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OnboardingScreen(
                      onFinish: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              },
            ),
            title: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('¿Qué es Finanz App?'),
                    content: const Text(
                        'FinanzApp te ayuda a llevar un control claro y visual de tus ingresos, gastos fijos y gastos hormiga. Navega entre las pestañas para ver tu balance diario, gestionar tu presupuesto fijo, analizar tus gastos y consultar resúmenes mensuales o anuales.'),
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
                'FinanzApp',
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
          body: Column(
            children: [
              // Banner publicitario
              if (_isBannerAdReady && _bannerAd != null)
                SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                )
              else
                Container(
                  width: double.infinity,
                  height: 60,
                  color: Colors.amber[200],
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Cargando anuncio...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              // Contenido principal
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    if (appState.selectedIndex != index) {
                      appState.selectedIndex = index;
                    }
                    _onPageChanged(index);
                  },
                  physics: const BouncingScrollPhysics(),
                  children: const [
                    BalanceScreen(),
                    BudgetScreen(),
                    ReportsScreen(),
                    SummaryScreen(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: appState.selectedIndex,
            onDestinationSelected: (index) {
              if (appState.selectedIndex != index) {
                appState.selectedIndex = index;
                _onPageChanged(index);
              }
            },
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundColor: Theme.of(context).colorScheme.surface,
            animationDuration: const Duration(milliseconds: 500),
            destinations: [
              _buildNavDestination(0, Icons.account_balance_wallet_outlined, 
                          Icons.account_balance_wallet, 'Balance', appState.selectedIndex, context),
              _buildNavDestination(1, Icons.calendar_month_outlined, 
                          Icons.calendar_month, 'Presupuesto', appState.selectedIndex, context),
              _buildNavDestination(2, Icons.bar_chart_outlined, 
                          Icons.bar_chart, 'Informes', appState.selectedIndex, context),
              _buildNavDestination(3, Icons.summarize_outlined, 
                          Icons.summarize, 'Resumen', appState.selectedIndex, context),
            ],
          ),
        );
      },
    );
  }
  
  NavigationDestination _buildNavDestination(
    int index, 
    IconData icon, 
    IconData selectedIcon, 
    String label, 
    int currentIndex, 
    BuildContext context
  ) {
    final isSelected = index == currentIndex;
    final colorScheme = Theme.of(context).colorScheme;
    
    final Color iconColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant.withOpacity(0.7);
        
    return NavigationDestination(
      icon: Icon(
        isSelected ? selectedIcon : icon,
        color: iconColor,
      ),
      label: label,
    );
  }
}