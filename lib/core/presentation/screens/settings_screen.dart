import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/presentation/screens/onboarding_screen.dart';
import 'package:finanz_app/core/presentation/widgets/export_dialog.dart';

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

          const SizedBox(height: 24),

          // Sección de Funciones avanzadas
          _buildSection(
            context,
            'Funciones avanzadas',
            [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Eliminar transacciones del mes actual', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Elimina transacciones fijas y/o hormiga del mes actual. Esta acción no se puede deshacer.'),
                onTap: () async {
                  int secondsLeft = 10;
                  bool confirmed = false;
                  bool deleteFixed = false;
                  bool deleteAnt = false;
                  bool timerActive = false;
                  void resetTimer(StateSetter setState) {
                    setState(() {
                      secondsLeft = 10;
                      timerActive = false;
                    });
                  }
                  await showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          // Iniciar el contador solo si hay alguna opción seleccionada y el timer no está activo
                          if ((deleteFixed || deleteAnt) && !timerActive) {
                            timerActive = true;
                            Future.doWhile(() async {
                              if (secondsLeft > 0 && (deleteFixed || deleteAnt)) {
                                await Future.delayed(const Duration(seconds: 1));
                                setState(() {
                                  secondsLeft--;
                                });
                                return true;
                              }
                              return false;
                            });
                          }
                          return AlertDialog(
                            title: const Text('¿Qué deseas eliminar?', style: TextStyle(color: Colors.red)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selecciona qué tipo de transacciones deseas eliminar del mes actual. Esta acción no se puede deshacer.',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                CheckboxListTile(
                                  value: deleteFixed,
                                  onChanged: (value) {
                                    resetTimer(setState);
                                    setState(() { deleteFixed = value ?? false; });
                                  },
                                  title: const Text('Transacciones fijas'),
                                ),
                                CheckboxListTile(
                                  value: deleteAnt,
                                  onChanged: (value) {
                                    resetTimer(setState);
                                    setState(() { deleteAnt = value ?? false; });
                                  },
                                  title: const Text('Transacciones hormiga'),
                                ),
                                const SizedBox(height: 16),
                                if (!deleteFixed && !deleteAnt)
                                  const Text('Debes seleccionar al menos una opción.', style: TextStyle(color: Colors.red)),
                                if (deleteFixed || deleteAnt)
                                  Row(
                                    children: [
                                      const Icon(Icons.warning, color: Colors.red, size: 20),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Espera $secondsLeft segundos para confirmar',
                                          style: const TextStyle(color: Colors.red, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                                    if (secondsLeft == 0 && (deleteFixed || deleteAnt)) {
                                      return Colors.red;
                                    }
                                    return Colors.grey;
                                  }),
                                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                                ),
                                onPressed: (secondsLeft == 0 && (deleteFixed || deleteAnt))
                                    ? () async {
                                        // Última confirmación
                                        final seguro = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('¿Estás seguro?', style: TextStyle(color: Colors.red)),
                                            content: const Text('Esta acción eliminará las transacciones seleccionadas del mes actual y no se puede deshacer. ¿Deseas continuar?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Cancelar'),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white,
                                                ),
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Sí, eliminar'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (seguro == true) {
                                          confirmed = true;
                                          Navigator.pop(context);
                                        }
                                      }
                                    : null,
                                child: const Text('Eliminar'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                  if (confirmed) {
                    final appState = Provider.of<AppState>(context, listen: false);
                    await appState.deleteCurrentMonthTransactions(deleteFixed: deleteFixed, deleteAnt: deleteAnt);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          deleteFixed && deleteAnt
                            ? 'Transacciones fijas y hormiga eliminadas.'
                            : deleteFixed
                              ? 'Transacciones fijas eliminadas.'
                              : 'Transacciones hormiga eliminadas.'
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text('Exportar datos', style: TextStyle(color: Colors.blue)),
                subtitle: const Text('Exporta tus datos a CSV o respaldo completo'),
                onTap: () {
                  final now = DateTime.now();
                  showDialog(
                    context: context,
                    builder: (context) => ExportDialog(
                      year: now.year,
                      month: now.month,
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