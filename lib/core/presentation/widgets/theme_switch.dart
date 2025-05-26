import 'package:flutter/material.dart';

class ThemeSwitch extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  const ThemeSwitch({
    super.key,
    required this.isDarkMode,
    required this.onChanged,
  });

  @override
  State<ThemeSwitch> createState() => _ThemeSwitchState();
}

class _ThemeSwitchState extends State<ThemeSwitch> 
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _bounceController;
  
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador principal para la transición
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Controlador para el efecto de rebote
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Animación de rotación suave
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    // Animación de escala con efecto elástico
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    // Animación de desvanecimiento cruzado
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));

    // Animación de rebote sutil
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeInOut,
    ));

    // Configurar estado inicial
    if (widget.isDarkMode) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ThemeSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isDarkMode != oldWidget.isDarkMode) {
      _animateThemeChange();
    }
  }

  void _animateThemeChange() async {
    // Activar efecto de rebote
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });

    // Animar transición principal
    if (widget.isDarkMode) {
      await _controller.forward();
    } else {
      await _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _bounceController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _bounceAnimation.value,
          child: IconButton(
            onPressed: () => widget.onChanged(!widget.isDarkMode),
            iconSize: 28,
            icon: Stack(
              alignment: Alignment.center,
              children: [
                // Sol (modo claro)
                Transform.rotate(
                  angle: (1 - _rotationAnimation.value) * 0.5,
                  child: AnimatedOpacity(
                    opacity: 1 - _fadeAnimation.value,
                    duration: const Duration(milliseconds: 100),
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      color: Colors.amber.shade600,
                      size: 28,
                    ),
                  ),
                ),
                // Luna (modo oscuro)
                Transform.rotate(
                  angle: _rotationAnimation.value * -0.8,
                  child: AnimatedOpacity(
                    opacity: _fadeAnimation.value,
                    duration: const Duration(milliseconds: 100),
                    child: Icon(
                      Icons.nightlight_round,
                      color: Colors.indigo.shade400,
                      size: 28,
                    ),
                  ),
                ),
                // Estrella decorativa para modo oscuro
                if (_fadeAnimation.value > 0.5)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 2,
                      child: AnimatedOpacity(
                        opacity: (_fadeAnimation.value - 0.5) * 2,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.star,
                          color: Colors.yellow.shade300,
                          size: 8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: widget.isDarkMode 
              ? 'Cambiar a modo claro' 
              : 'Cambiar a modo oscuro',
          ),
        );
      },
    );
  }
}