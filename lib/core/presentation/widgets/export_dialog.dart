import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/utils/export_service.dart';
import 'package:finanz_app/core/presentation/widgets/import_dialog.dart';

class ExportDialog extends StatefulWidget {
  final int year;
  final int? month;

  const ExportDialog({
    Key? key,
    required this.year,
    this.month,
  }) : super(key: key);

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  bool _isExporting = false;
  String? _errorMessage;
  bool _isMonthly = false;
  bool _isYearly = true;
  bool _isFullBackup = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Exportar Datos'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona el tipo de exportación:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Opciones de exportación
            _buildExportOption(
              title: 'Datos del mes actual',
              description: widget.month != null 
                ? 'Exportar solo las transacciones del mes ${_getMonthName(widget.month!)} ${widget.year}'
                : 'Exportar solo las transacciones del mes actual',
              icon: Icons.today,
              isSelected: _isMonthly,
              onTap: () => setState(() {
                _isMonthly = true;
                _isYearly = false;
                _isFullBackup = false;
              }),
            ),
            
            _buildExportOption(
              title: 'Datos del año completo',
              description: 'Exportar todas las transacciones del año ${widget.year}',
              icon: Icons.calendar_today,
              isSelected: _isYearly,
              onTap: () => setState(() {
                _isMonthly = false;
                _isYearly = true;
                _isFullBackup = false;
              }),
            ),
            
            _buildExportOption(
              title: 'Respaldo completo (JSON)',
              description: 'Crear un archivo de respaldo con todos tus datos',
              icon: Icons.backup,
              isSelected: _isFullBackup,
              onTap: () => setState(() {
                _isMonthly = false;
                _isYearly = false;
                _isFullBackup = true;
              }),
            ),
            
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Botón de importación
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => const ImportDialog(),
                  );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Importar Respaldo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isExporting ? null : _exportData,
          child: _isExporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Exportar'),
        ),
      ],
    );
  }

  Widget _buildExportOption({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: isSelected,
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  Future<void> _exportData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    setState(() {
      _isExporting = true;
      _errorMessage = null;
    });

    try {
      String filePath;
      String subject;
      
      if (_isFullBackup) {
        // Exportar respaldo completo (JSON)
        filePath = await ExportService.exportToJSON(appState);
        subject = 'Respaldo completo de FinanzApp';
      } else {
        // Exportar a CSV (mensual o anual)
        filePath = await ExportService.exportToCSV(
          antTransactions: appState.antTransactions,
          fixedTransactions: appState.fixedTransactions,
          year: widget.year,
          month: _isMonthly ? widget.month ?? DateTime.now().month : null,
        );
        
        if (_isMonthly) {
          final monthName = _getMonthName(widget.month ?? DateTime.now().month);
          subject = 'Transacciones de $monthName ${widget.year} - FinanzApp';
        } else {
          subject = 'Transacciones del año ${widget.year} - FinanzApp';
        }
      }

      // Compartir el archivo
      try {
        await ExportService.shareFile(filePath, subject: subject);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Datos exportados correctamente!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Si falla el compartir pero el archivo se creó correctamente
        if (e.toString().contains('cancelada')) {
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('El archivo se guardó pero no se compartió: ${e.toString()}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      String errorMessage;
      
      // Mensajes de error más amigables
      if (e.toString().contains('No hay transacciones')) {
        errorMessage = 'No hay datos para exportar en el período seleccionado';
      } else if (e.toString().contains('No hay datos para exportar')) {
        errorMessage = 'No hay datos para crear el respaldo';
      } else if (e.toString().contains('no se pudo crear')) {
        errorMessage = 'No se pudo guardar el archivo. Verifica el espacio disponible';
      } else if (e.toString().contains('vacío')) {
        errorMessage = 'Error al generar el archivo: el contenido está vacío';
      } else {
        errorMessage = 'Error al exportar: ${e.toString()}';
      }

      setState(() {
        _errorMessage = errorMessage;
        _isExporting = false;
      });

      // Mostrar el error también como un SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 