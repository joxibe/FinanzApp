import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/presentation/screens/onboarding_screen.dart';
import 'package:finanz_app/core/presentation/widgets/export_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Configuración'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Apariencia
            _buildModernSection(
              context,
              'Apariencia',
              Icons.palette_outlined,
              [
                _buildThemeSelector(context),
              ],
            ),

            const SizedBox(height: 28),

            // Sección de Ayuda
            _buildModernSection(
              context,
              'Ayuda y Soporte',
              Icons.help_outline_rounded,
              [
                _buildModernTile(
                  context,
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Ver Tutorial',
                  subtitle: 'Aprende a usar la aplicación',
                  iconColor: colorScheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => 
                          OnboardingScreen(onFinish: () => Navigator.pop(context)),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: animation.drive(
                              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
                            ),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildModernTile(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'Acerca de',
                  subtitle: 'Información de la aplicación',
                  iconColor: colorScheme.tertiary,
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Sección de Funciones avanzadas
            _buildModernSection(
              context,
              'Funciones Avanzadas',
              Icons.settings_outlined,
              [
                _buildModernTile(
                  context,
                  icon: Icons.download_rounded,
                  title: 'Exportar Datos',
                  subtitle: 'Exporta a CSV o respaldo completo',
                  iconColor: Colors.blue.shade600,
                  onTap: () => _showExportDialog(context),
                ),
                const SizedBox(height: 8),
                _buildModernTile(
                  context,
                  icon: Icons.delete_sweep_rounded,
                  title: 'Limpiar Transacciones',
                  subtitle: 'Eliminar datos del mes actual',
                  iconColor: Colors.red.shade500,
                  isDestructive: true,
                  onTap: () => _showDeleteDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection(
    BuildContext context, 
    String title, 
    IconData sectionIcon,
    List<Widget> children
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Row(
            children: [
              Icon(
                sectionIcon,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildModernTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isDestructive ? Colors.red.shade600 : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ] else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    appState.isDarkMode 
                      ? Icons.dark_mode_rounded 
                      : Icons.light_mode_rounded,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tema',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appState.isDarkMode ? 'Modo oscuro activo' : 'Modo claro activo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: appState.isDarkMode,
                  onChanged: (value) => appState.toggleTheme(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Finanz App'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Versión 1.0.0',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'FinanzApp te ayuda a llevar un control claro y visual de tus ingresos, gastos fijos y gastos hormiga. Navega entre las pestañas para ver tu balance diario, gestionar tu presupuesto fijo, analizar tus gastos y consultar resúmenes mensuales o anuales.',
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Desarrollado por JXL Softworks',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
        year: now.year,
        month: now.month,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) async {
    bool confirmed = false;
    bool deleteFixed = false;
    bool deleteAnt = false;
    
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '¿Qué deseas eliminar?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Selecciona qué tipo de transacciones deseas eliminar del mes actual. Esta acción no se puede deshacer.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildModernCheckbox(
                    context,
                    'Transacciones fijas',
                    deleteFixed,
                    (value) {
                      setState(() { deleteFixed = value ?? false; });
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildModernCheckbox(
                    context,
                    'Transacciones hormiga',
                    deleteAnt,
                    (value) {
                      setState(() { deleteAnt = value ?? false; });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (!deleteFixed && !deleteAnt)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Debes seleccionar al menos una opción.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (deleteFixed || deleteAnt)
                        ? Colors.red.shade600
                        : colorScheme.outline.withOpacity(0.3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: (deleteFixed || deleteAnt)
                      ? () async {
                          final seguro = await _showFinalConfirmation(context);
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
                    : 'Transacciones hormiga eliminadas.',
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Widget _buildModernCheckbox(
    BuildContext context,
    String title,
    bool value,
    Function(bool?) onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: value ? colorScheme.primaryContainer.withOpacity(0.3) : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? colorScheme.primary.withOpacity(0.3) : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: value ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool?> _showFinalConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.red.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '¿Estás seguro?',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
        content: Text(
          'Esta acción eliminará las transacciones seleccionadas del mes actual y no se puede deshacer. ¿Deseas continuar?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar'),
          ),
        ],
      ),
    );
  }
}