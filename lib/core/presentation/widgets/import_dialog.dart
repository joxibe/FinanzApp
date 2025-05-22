import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finanz_app/core/domain/models/app_state.dart';
import 'package:finanz_app/core/utils/export_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:developer' as developer;

class ImportDialog extends StatefulWidget {
  const ImportDialog({Key? key}) : super(key: key);

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  bool _isImporting = false;
  String? _errorMessage;
  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importar Datos'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona un archivo de respaldo (JSON):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Botón para seleccionar archivo
            Center(
              child: OutlinedButton.icon(
                onPressed: _isImporting ? null : _pickFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_selectedFileName ?? 'Seleccionar archivo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
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
            
            const SizedBox(height: 16),
            const Text(
              'Nota: La importación reemplazará todos los datos actuales. '
              'Se recomienda hacer un respaldo antes de importar.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isImporting ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isImporting || _selectedFileName == null ? null : _importData,
          child: _isImporting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Importar'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Permitimos cualquier tipo de archivo
        withData: true,
        allowMultiple: false,
      );

      if (result != null) {
        // Log para depuración
        developer.log('Archivo seleccionado:');
        developer.log('Nombre: ${result.files.single.name}');
        developer.log('Tamaño: ${result.files.single.size} bytes');

        // Validar que el archivo no esté vacío
        if (result.files.single.size == 0) {
          throw Exception('El archivo seleccionado está vacío');
        }

        // Intentar decodificar el contenido como JSON para validar
        try {
          final content = utf8.decode(result.files.single.bytes!);
          // Intentar parsear el JSON para validar que es un JSON válido
          json.decode(content);
          
          // Si llegamos aquí, el archivo es un JSON válido
          setState(() {
            _selectedFileName = result.files.single.name;
            _selectedFileBytes = result.files.single.bytes;
            _errorMessage = null;
          });
        } catch (e) {
          throw Exception('El archivo seleccionado no es un JSON válido');
        }
      }
    } catch (e) {
      String errorMessage;
      
      if (e.toString().contains('vacío')) {
        errorMessage = 'El archivo seleccionado está vacío';
      } else if (e.toString().contains('JSON')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        errorMessage = 'Error al seleccionar archivo: ${e.toString()}';
      }

      setState(() {
        _errorMessage = errorMessage;
      });

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

  Future<void> _importData() async {
    if (_selectedFileName == null || _selectedFileBytes == null) return;

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      // Validar que el archivo no esté vacío
      if (_selectedFileBytes!.isEmpty) {
        throw Exception('El archivo está vacío');
      }

      // Convertir los bytes a string usando UTF-8
      final jsonContent = utf8.decode(_selectedFileBytes!);
      final newAppState = await ExportService.importFromJSON(jsonContent);
      
      if (mounted) {
        // Actualizar el estado de la app
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.updateFromImport(newAppState);
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Datos importados correctamente!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      String errorMessage;
      
      // Mensajes de error más amigables
      if (e.toString().contains('vacío')) {
        errorMessage = 'El archivo está vacío';
      } else if (e.toString().contains('formato válido')) {
        errorMessage = 'El archivo JSON no tiene un formato válido';
      } else if (e.toString().contains('información necesaria')) {
        errorMessage = 'El archivo no contiene la información necesaria para la importación';
      } else if (e.toString().contains('datos necesarios')) {
        errorMessage = 'El archivo no contiene todos los datos necesarios';
      } else if (e.toString().contains('convertir los datos')) {
        errorMessage = 'Error al procesar los datos del archivo';
      } else if (e.toString().contains('categoría')) {
        errorMessage = 'El archivo debe contener al menos una categoría de cada tipo';
      } else {
        errorMessage = 'Error al importar: ${e.toString()}';
      }

      setState(() {
        _errorMessage = errorMessage;
        _isImporting = false;
      });

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