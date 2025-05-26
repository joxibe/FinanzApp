import 'package:flutter/material.dart';
import 'package:finanz_app/core/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // Reducido de 2s a 1.5s
      vsync: this,
    );

    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    ));

    _initializeApp();
  }

  // Método optimizado que carga datos mientras se reproduce la animación
  Future<void> _initializeApp() async {
    // Iniciar la animación inmediatamente
    _controller.forward();
    
    // Cargar datos en paralelo con la animación
    final Future<SharedPreferences> prefsFuture = SharedPreferences.getInstance();
    
    // Esperar a que termine la animación (mínimo tiempo para UX)
    await Future.wait([
      _controller.forward(),
      Future.delayed(const Duration(milliseconds: 1800)), // Tiempo mínimo de splash
    ]);
    
    // Obtener las preferencias (ya deberían estar cargadas)
    final prefs = await prefsFuture;
    final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    
    if (mounted && !_isNavigating) {
      _isNavigating = true;
      _navigateToNextScreen(onboardingSeen);
    }
  }

  void _navigateToNextScreen(bool onboardingSeen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => onboardingSeen
            ? const HomeScreen()
            : OnboardingScreen(onFinish: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, a, b) => const HomeScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 300), // Reducido
                  ),
                );
              }),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300), // Reducido
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF1E1E2E)
          : const Color(0xFF6B8AFE),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animado
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Hero( // Añadido Hero para transición suave
                    tag: 'app_logo',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 100, // Reducido ligeramente
                        height: 100,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 60, // Reducido proporcionalmente
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24), // Reducido
            
            // Título animado
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _textAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - _textAnimation.value)), // Reducido
                    child: Column(
                      children: [
                        const Text(
                          'FinanzApp',
                          style: TextStyle(
                            fontSize: 26, // Ligeramente reducido
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Controla tus gastos hormiga',
                          style: TextStyle(
                            fontSize: 15, // Ligeramente reducido
                            color: Colors.white70,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 32), // Reducido
                        // Indicador de carga más elegante
                        SizedBox(
                          width: 24, // Más pequeño
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                            strokeWidth: 2.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}