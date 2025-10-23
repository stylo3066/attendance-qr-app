import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  bool isScanning = false;
  MobileScannerController cameraController = MobileScannerController(
    facing: CameraFacing.back, // Forzar cámara trasera
    torchEnabled: false,
    returnImage: false,
  );
  bool isSyncing = false;
  bool isUsingBackCamera = true;

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
    cameraController.dispose();
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
      body: Column(
        children: [
          // Scanner de cámara
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: isScanning
                    ? Stack(
                        children: [
                          MobileScanner(
                            controller: cameraController,
                            onDetect: (BarcodeCapture barcodeCapture) {
                              _onBarcodeDetect(barcodeCapture);
                            },
                          ),
                          // Overlay con indicadores
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Stack(
                              children: [
                                // Botón para cambiar cámara
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: FloatingActionButton.small(
                                    heroTag: "switchCamera",
                                    onPressed: _switchCamera,
                                    backgroundColor: Colors.black54,
                                    child: Icon(
                                      isUsingBackCamera
                                          ? Icons.camera_rear
                                          : Icons.camera_front,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // Botón de linterna
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: FloatingActionButton.small(
                                    heroTag: "torch",
                                    onPressed: () =>
                                        cameraController.toggleTorch(),
                                    backgroundColor: Colors.black54,
                                    child: const Icon(
                                      Icons.flash_on,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // Indicador de QR en el centro
                                const Center(
                                  child: Icon(
                                    Icons.qr_code_scanner,
                                    size: 100,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner,
                                  size: 80, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Presiona "Iniciar Scanner" para\nescanear códigos QR de profesores',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Controles
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Aviso si falta configuración de endpoint/secret
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
                  // Botón de scanner
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _toggleScanner,
                      icon:
                          Icon(isScanning ? Icons.stop : Icons.qr_code_scanner),
                      label: Text(
                          isScanning ? 'Detener Scanner' : 'Iniciar Scanner'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isScanning ? Colors.red : Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Último código escaneado
                  if (qrText != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✅ Último registro:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Código: $qrText'),
                          Text('Profesor registrado exitosamente'),
                        ],
                      ),
                    ),

                  if (qrText == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '📱 Instrucciones:\n1. Presiona "Iniciar Scanner"\n2. Enfoca el QR del profesor\n3. El registro se guardará automáticamente',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para cambiar entre cámara delantera y trasera
  void _switchCamera() async {
    await cameraController.stop();

    setState(() {
      isUsingBackCamera = !isUsingBackCamera;
    });

    // Recrear el controller con la nueva cámara
    cameraController = MobileScannerController(
      facing: isUsingBackCamera ? CameraFacing.back : CameraFacing.front,
      torchEnabled: false,
      returnImage: false,
    );

    if (isScanning) {
      await cameraController.start();
    }
  }

  // Método para alternar el scanner
  void _toggleScanner() async {
    if (isScanning) {
      await cameraController.stop();
      setState(() {
        isScanning = false;
      });
    } else {
      // Verificar permisos de cámara
      final permission = await Permission.camera.request();
      if (permission.isGranted) {
        await cameraController.start();
        setState(() {
          isScanning = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Se necesita permiso de cámara para escanear códigos QR'),
          ),
        );
      }
    }
  }

  // Método cuando se detecta un código QR
  void _onBarcodeDetect(BarcodeCapture barcodeCapture) async {
    final List<Barcode> barcodes = barcodeCapture.barcodes;

    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;

      if (code != null && code.isNotEmpty) {
        // Detener el scanner temporalmente
        setState(() {
          isScanning = false;
        });
        await cameraController.stop();

        // Procesar el código QR
        _processQRCode(code);

        // Esperar un poco antes de reactivar el scanner
        await Future.delayed(const Duration(seconds: 2));

        // Reactivar el scanner automáticamente
        if (mounted) {
          await cameraController.start();
          setState(() {
            isScanning = true;
          });
        }
      }
    }
  }

  void _processQRCode(String code) async {
    if (code.isEmpty) return;

    setState(() {
      qrText = code;
    });

    // Construir registro
    final now = DateTime.now().toIso8601String();
    final record = {
      'qrCode': code,
      'user': widget.user,
      'timestamp': now,
      'deviceId': 'flutter_app',
    };

    // Guardar localmente usando SharedPreferences
    await _saveAttendanceRecord(record);

    // Intentar enviar al servidor en segundo plano
    _sendToServer(record);

    // Mostrar mensaje de éxito
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profesor registrado correctamente')),
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

  // Firma HMAC del mensaje determinístico qrCode|deviceId|timestamp
  String _signRecord(Map<String, dynamic> record) {
    final message =
        '${record['qrCode']}|${record['deviceId']}|${record['timestamp']}';
    final key = utf8.encode(hmacSecret);
    final bytes = utf8.encode(message);
    final digest = Hmac(sha256, key).convert(bytes);
    return digest.toString();
  }

  Future<void> _enqueuePending(Map<String, dynamic> record) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('pending_queue') ?? [];
    queue.add(jsonEncode(record));
    await prefs.setStringList('pending_queue', queue);
  }

  // Cargar configuraciones (functionUrl / hmacSecret) desde SharedPreferences
  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        functionUrl = prefs.getString('FUNCTION_URL') ?? '';
        hmacSecret = prefs.getString('HMAC_SECRET') ?? '';
      });
      // Intentar auto-descubrir el proxy local (entorno dev) si no hay configuración
      if (!kReleaseMode && (functionUrl.isEmpty || hmacSecret.isEmpty)) {
        final discovered = await _autoDiscoverLocalProxy();
        if (!discovered) {
          // Fallback a localhost:3000 si no se pudo descubrir
          functionUrl = functionUrl.isEmpty
              ? 'http://localhost:3000/api/attendance'
              : functionUrl;
          hmacSecret = hmacSecret.isEmpty ? 'dev_secret' : hmacSecret;
          await prefs.setString('FUNCTION_URL', functionUrl);
          await prefs.setString('HMAC_SECRET', hmacSecret);
        }
      }
      debugPrint('Config loaded: FUNCTION_URL=${functionUrl.isNotEmpty}, HMAC_SECRET=${hmacSecret.isNotEmpty}');
      // Tras cargar configuración, intentar sincronizar pendientes si aplica
      if (functionUrl.isNotEmpty && hmacSecret.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncPendingQueue();
        });
      }
    } catch (e) {
      debugPrint('Error loading config: $e');
    }
  }

  // Descubre el servidor local consultando /port en puertos 3000..3005 de localhost
  Future<bool> _autoDiscoverLocalProxy() async {
    // Probar varios hosts útiles en desarrollo: localhost (PC), 10.0.2.2 (Android Emulator)
    final hosts = <String>['localhost', '10.0.2.2'];
    final ports = List<int>.generate(6, (i) => 3000 + i);
    for (final host in hosts) {
      for (final p in ports) {
        try {
          final uri = Uri.parse('http://$host:$p/port');
          final resp = await http
              .get(uri)
              .timeout(const Duration(milliseconds: 900));
          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body) as Map<String, dynamic>;
            final ip = data['ip']?.toString() ?? host;
            final port = data['port']?.toString() ?? '$p';
            final url = 'http://$ip:$port/api/attendance';
            await _saveConfig(
                url, hmacSecret.isEmpty ? 'dev_secret' : hmacSecret);
            debugPrint('Auto-discovered proxy: $url');
            return true;
          }
        } catch (_) {
          // ignorar y continuar
        }
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
    // Tras guardar, intentar sincronizar cualquier pendiente
    if (functionUrl.isNotEmpty && hmacSecret.isNotEmpty) {
      // No bloquear el diálogo; lanzar en segundo plano
      // ignore: unawaited_futures
      _syncPendingQueue();
    }
  }

  // Dialogo para editar la URL del endpoint y el secreto HMAC
  void _openSettingsDialog() async {
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
              decoration: const InputDecoration(labelText: 'FUNCTION_URL (HTTPS)'),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToServer(Map<String, dynamic> record) async {
    if (functionUrl.isEmpty || hmacSecret.isEmpty) {
      // Si no está configurado, encolar y salir
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
        if (mounted) {
          final msg = resp.statusCode == 401
              ? 'Secreto HMAC inválido (401). Revisa HMAC_SECRET.'
              : resp.statusCode == 404
                  ? 'QR no reconocido (404). Usa un QR de /test-qr.'
                  : 'Error ${resp.statusCode} al sincronizar';
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
        await _enqueuePending(record);
      }
    } catch (e) {
      debugPrint('Error de red: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin conexión con el servidor')),
        );
      }
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
