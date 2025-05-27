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
import 'package:finanz_app/core/presentation/screens/settings_screen.dart';
import 'dart:async';
import 'dart:math' as math;

class AdHelper {
  // IDs de producción de AdMob
  //static String get bannerAdUnitId => 'ca-app-pub-7539659588201107/3038959785';
  //static String get interstitialAdUnitId => 'ca-app-pub-7539659588201107/7483818860';

  // IDs de prueba
  static String get bannerAdUnitId => 'ca-app-pub-3940256099942544/6300978111';
  static String get interstitialAdUnitId => 'ca-app-pub-3940256099942544/1033173712';
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
  int _bannerAdAttempts = 0;
  static const int maxAttempts = 3;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    
    // Configuración de anuncios para producción
    MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
        testDeviceIds: [],
      ),
    );
    
    // Primer intento de carga de anuncios con delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _loadBannerAd();
        _loadInterstitialAd();
      }
    });
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
    if (_bannerAdAttempts >= maxAttempts) {
      debugPrint('Máximo número de intentos de carga de banner alcanzado');
      return;
    }

    try {
      _bannerAd = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted) {
              setState(() {
                _isBannerAdReady = true;
                _bannerAdAttempts = 0; // Resetear intentos si se carga exitosamente
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: ${error.message}');
            _isBannerAdReady = false;
            ad.dispose();
            
            _bannerAdAttempts++;
            if (_bannerAdAttempts < maxAttempts) {
              // Reintento con backoff exponencial
              Timer(Duration(seconds: math.min(30, 5 * _bannerAdAttempts)), () {
                if (mounted) _loadBannerAd();
              });
            }
          },
        ),
      );

      _bannerAd!.load();
    } catch (e) {
      debugPrint('Error al inicializar banner ad: $e');
      _bannerAdAttempts++;
    }
  }

  void _loadInterstitialAd() {
    if (_interstitialAdAttempts >= maxAttempts) {
      debugPrint('Máximo número de intentos de carga de intersticial alcanzado');
      return;
    }

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
          _interstitialAdAttempts = 0; // Resetear intentos si se carga exitosamente
          
          _interstitialAd!.setImmersiveMode(true);
          
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {},
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
              debugPrint('Intersticial failed to show: ${error.message}');
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
          debugPrint('Intersticial ad failed to load: ${error.message}');
          _isInterstitialAdReady = false;
          _interstitialAdAttempts++;
          
          if (_interstitialAdAttempts < maxAttempts) {
            Timer(Duration(seconds: math.min(30, 5 * _interstitialAdAttempts)), () {
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
            title: StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) => setState(() => _isPressed = false),
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeInOut,
                    tween: Tween(begin: 1.0, end: _isPressed ? 0.95 : 1.0),
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Text(
                          'FinanzApp',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                tooltip: 'Información de la pantalla',
                onPressed: () {
                  String info = '';
                  String title = '';
                  switch (appState.selectedIndex) {
                    case 0:
                      title = 'Balance';
                      info = 'Registra tus gastos e ingresos hormiga del mes actual. Estos son gastos variables que debes registrar cada mes, ya que no se copian automáticamente al siguiente mes.';
                      break;
                    case 1:
                      title = 'Presupuesto';
                      info = 'Gestiona tus ingresos y gastos fijos mensuales. Estos se copian automáticamente cada mes para tu comodidad, pero puedes modificarlos en cualquier momento.';
                      break;
                    case 2:
                      title = 'Informes';
                      info = 'Analiza tus gastos por categoría y accede a estadísticas útiles. Aquí puedes ver el historial completo de todos tus movimientos y tendencias de gastos.';
                      break;
                    case 3:
                      title = 'Resumen';
                      info = 'Consulta el resumen mensual o anual de todos tus movimientos. Podrás ver el historial completo de tus gastos fijos y hormiga de meses anteriores.';
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
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Configuración',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
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

  String _getScreenTitle(int index) {
    switch (index) {
      case 0:
        return 'Balance';
      case 1:
        return 'Presupuesto';
      case 2:
        return 'Informes';
      case 3:
        return 'Resumen';
      default:
        return 'FinanzApp';
    }
  }
}