import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/presentation/screens/onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sección de Apariencia
          _buildSection(
            context,
            'Apariencia',
            [
              _buildThemeSelector(context),
            ],
          ),

          const SizedBox(height: 24),

          // Sección de Ayuda
          _buildSection(
            context,
            'Ayuda y Soporte',
            [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Ver Tutorial'),
                subtitle: const Text('Aprende a usar la aplicación'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingScreen(
                        onFinish: () => Navigator.pop(context),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Acerca de'),
                subtitle: const Text('Información de la aplicación'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Finanz App'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Versión 1.0.0',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'FinanzApp te ayuda a llevar un control claro y visual de tus ingresos, gastos fijos y gastos hormiga. Navega entre las pestañas para ver tu balance diario, gestionar tu presupuesto fijo, analizar tus gastos y consultar resúmenes mensuales o anuales.',
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Desarrollado por JXL Softworks',
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Tema'),
          subtitle: Text(appState.isDarkMode ? 'Modo oscuro' : 'Modo claro'),
          trailing: Switch(
            value: appState.isDarkMode,
            onChanged: (value) {
              appState.toggleTheme();
            },
          ),
        );
      },
    );
  }
} 