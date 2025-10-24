import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(const AttendanceQRApp());
}

class AttendanceQRApp extends StatelessWidget {
  const AttendanceQRApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asistencia QR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AttendanceHomePage(user: 'Usuario Demo'),
    );
  }
}

class AttendanceHomePage extends StatefulWidget {
  final String user;
  const AttendanceHomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<AttendanceHomePage> createState() => _AttendanceHomePageState();
}

class _AttendanceHomePageState extends State<AttendanceHomePage> {
  String? qrText;
  final TextEditingController _qrController = TextEditingController();
  bool isSyncing = false;

  // Configuración del endpoint y secreto (guardados en SharedPreferences)
  String functionUrl = '';
  String hmacSecret = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Asistencia QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettingsDialog,
            tooltip: 'Ajustes',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showAttendanceRecords,
            tooltip: 'Ver registros',
          ),
          IconButton(
            icon: isSyncing
                ? const Icon(Icons.sync)
                : const Icon(Icons.cloud_upload),
            onPressed: _syncPendingQueue,
            tooltip: 'Sincronizar pendientes',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            if (functionUrl.isEmpty || hmacSecret.isEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(color: Colors.amber),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Falta configurar el endpoint',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Los registros se guardarán en el dispositivo y se enviarán cuando configures FUNCTION_URL y HMAC_SECRET.',
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _openSettingsDialog,
                              icon: const Icon(Icons.settings),
                              label: const Text('Abrir ajustes'),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Generador de QR
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text('Generar QR de Asistencia:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  QrImageView(
                    data: 'PROF_001',
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                  const Text('QR de ejemplo: PROF_001'),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Campo manual para código QR
            TextField(
              controller: _qrController,
              decoration: const InputDecoration(
                labelText: 'Código QR escaneado',
                border: OutlineInputBorder(),
                hintText: 'Ingresa o escanea el código QR',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _processQRCode(_qrController.text.trim()),
              child: const Text('Registrar Asistencia'),
            ),
            const SizedBox(height: 20),
            if (qrText != null)
              Text('Último código procesado: $qrText',
                  style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }

  void _processQRCode(String code) async {
    if (code.isEmpty) return;

    setState(() {
      qrText = code;
    });

    final record = {
      'qrCode': code,
      'user': widget.user,
      'timestamp': DateTime.now().toIso8601String(),
      'deviceId': 'flutter_app_simple',
    };

    // Guardar localmente
    await _saveAttendanceRecord(record);

    // Intentar enviar al servidor (encolar si falta config o no hay red)
    // ignore: unawaited_futures
    _sendToServer(record);

    // Limpiar el campo de texto
    _qrController.clear();

    // Mostrar mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Asistencia registrada correctamente')),
      );
    }
  }

  Future<void> _saveAttendanceRecord(Map<String, dynamic> record) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener registros existentes
      final existingRecords = prefs.getStringList('attendance_records') ?? [];

      // Añadir nuevo registro
      existingRecords.add(jsonEncode(record));

      // Guardar de vuelta
      await prefs.setStringList('attendance_records', existingRecords);

      debugPrint('Registro guardado: $record');
    } catch (e) {
      debugPrint('Error guardando registro: $e');
    }
  }

  // Encolar pendientes si no se puede enviar
  Future<void> _enqueuePending(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('pending_queue') ?? [];
    queue.add(jsonEncode(record));
    await prefs.setStringList('pending_queue', queue);
  }

  // Firma HMAC del mensaje determinístico qrCode|deviceId|timestamp
  String _signRecord(Map<String, dynamic> record) {
    final message =
        '${record['qrCode']}|${record['deviceId']}|${record['timestamp']}';
    final key = utf8.encode(hmacSecret);
    final bytes = utf8.encode(message);
    final digest = Hmac(sha256, key).convert(bytes);
    return digest.toString();
  }

  Future<void> _sendToServer(Map<String, dynamic> record) async {
    if (functionUrl.isEmpty || hmacSecret.isEmpty) {
      await _enqueuePending(record);
      return;
    }
    final signature = _signRecord(record);
    try {
      final resp = await http
          .post(Uri.parse(functionUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'signature': signature, 'data': record}))
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        debugPrint('Registro sincronizado OK');
      } else {
        debugPrint('Fallo al sincronizar (${resp.statusCode}): ${resp.body}');
        await _enqueuePending(record);
      }
    } catch (e) {
      debugPrint('Error de red: $e');
      await _enqueuePending(record);
    }
  }

  Future<void> _syncPendingQueue() async {
    if (isSyncing) return;
    setState(() => isSyncing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList('pending_queue') ?? [];
      if (queue.isEmpty) return;

      final remaining = <String>[];
      for (final item in queue) {
        final record = jsonDecode(item) as Map<String, dynamic>;
        final signature = _signRecord(record);
        try {
          final resp = await http
              .post(Uri.parse(functionUrl),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'signature': signature, 'data': record}))
              .timeout(const Duration(seconds: 10));
          if (resp.statusCode != 200) remaining.add(item);
        } catch (_) {
          remaining.add(item);
        }
      }
      await prefs.setStringList('pending_queue', remaining);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(remaining.isEmpty
                ? 'Todo sincronizado'
                : 'Pendientes: ${remaining.length}')));
      }
    } finally {
      if (mounted) setState(() => isSyncing = false);
    }
  }

  // Cargar/guardar configuración de endpoint
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        functionUrl = prefs.getString('FUNCTION_URL') ?? '';
        hmacSecret = prefs.getString('HMAC_SECRET') ?? '';
      });
      if (!kReleaseMode && (functionUrl.isEmpty || hmacSecret.isEmpty)) {
        final discovered = await _autoDiscoverLocalProxy();
        if (!discovered) {
          functionUrl = functionUrl.isEmpty
              ? 'http://localhost:3000/api/attendance'
              : functionUrl;
          hmacSecret = hmacSecret.isEmpty ? 'dev_secret' : hmacSecret;
          await prefs.setString('FUNCTION_URL', functionUrl);
          await prefs.setString('HMAC_SECRET', hmacSecret);
        }
      }
      if (functionUrl.isNotEmpty && hmacSecret.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncPendingQueue();
        });
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
  }

  Future<bool> _autoDiscoverLocalProxy() async {
    final candidates = List<int>.generate(6, (i) => 3000 + i);
    for (final p in candidates) {
      try {
        final uri = Uri.parse('http://localhost:$p/port');
        final resp =
            await http.get(uri).timeout(const Duration(milliseconds: 600));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final ip = data['ip']?.toString() ?? 'localhost';
          final port = data['port']?.toString() ?? '$p';
          final url = 'http://$ip:$port/api/attendance';
          await _saveConfig(
              url, hmacSecret.isEmpty ? 'dev_secret' : hmacSecret);
          debugPrint('Auto-discovered proxy: $url');
          return true;
        }
      } catch (_) {
        // ignore
      }
    }
    return false;
  }

  Future<void> _saveConfig(String url, String secret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('FUNCTION_URL', url);
    await prefs.setString('HMAC_SECRET', secret);
    setState(() {
      functionUrl = url;
      hmacSecret = secret;
    });
    if (functionUrl.isNotEmpty && hmacSecret.isNotEmpty) {
      // ignore: unawaited_futures
      _syncPendingQueue();
    }
  }

  void _openSettingsDialog() {
    final urlController = TextEditingController(text: functionUrl);
    final secretController = TextEditingController(text: hmacSecret);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajustes de sincronización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration:
                  const InputDecoration(labelText: 'FUNCTION_URL (HTTPS)'),
            ),
            TextField(
              controller: secretController,
              decoration: const InputDecoration(labelText: 'HMAC_SECRET'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final url = urlController.text.trim();
              final secret = secretController.text.trim();
              await _saveConfig(url, secret);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuración guardada')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Función para ver registros guardados
  Future<void> _showAttendanceRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = prefs.getStringList('attendance_records') ?? [];

      if (records.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay registros guardados')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Registros de Asistencia'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = jsonDecode(records[index]);
                final timestamp = DateTime.parse(record['timestamp']);
                return Card(
                  child: ListTile(
                    title: Text('QR: ${record['qrCode']}'),
                    subtitle: Text(
                        'Fecha: ${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'),
                    leading: const Icon(Icons.qr_code),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('attendance_records');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Registros eliminados')),
                );
              },
              child: const Text('Limpiar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error mostrando registros: $e');
    }
  }
}
