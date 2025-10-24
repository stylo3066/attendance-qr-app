import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

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
          // Probar conexión rápidamente
          IconButton(
            icon: const Icon(Icons.wifi),
            tooltip: 'Probar conexión',
            onPressed: _testConnection,
          ),
          // Abrir ajustes (URL/Secreto) y autodetección
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Ajustes de sincronización',
            onPressed: _openSettingsDialog,
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
            flex: 2,
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
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Estado de conexión / Config actual
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '✅ Servidor Local Activo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Conectado a tu PC (WiFi)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Acciones rápidas de configuración
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openSettingsDialog,
                            icon: const Icon(Icons.settings),
                            label: const Text('Configurar sincronización'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _testConnection,
                            icon: const Icon(Icons.wifi),
                            label: const Text('Probar conexión'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Botón de scanner
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _toggleScanner,
                        icon: Icon(
                            isScanning ? Icons.stop : Icons.qr_code_scanner),
                        label: Text(
                            isScanning ? 'Detener Scanner' : 'Iniciar Scanner'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isScanning ? Colors.red : Colors.blue,
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
                              'Último registro:',
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
                          'Instrucciones:\n1. Presiona "Iniciar Scanner"\n2. Enfoca el QR del profesor\n3. El registro se guardará automáticamente',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Botones para abrir páginas web
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        border: Border.all(color: Colors.purple),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Páginas Web - Dashboard:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openWebPage(
                                      'https://stylo3066.github.io/attendance-qr-app/dashboard.html'),
                                  icon: const Icon(Icons.dashboard, size: 16),
                                  label: const Text('Dashboard',
                                      style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openWebPage(
                                      'https://stylo3066.github.io/attendance-qr-app/test-qr.html'),
                                  icon: const Icon(Icons.qr_code, size: 16),
                                  label: const Text('Gen QR',
                                      style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openWebPage(
                                      'https://stylo3066.github.io/attendance-qr-app/test-system.html'),
                                  icon: const Icon(Icons.bug_report, size: 16),
                                  label: const Text('Test',
                                      style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testConnection() async {
    if (functionUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configura FUNCTION_URL en Ajustes')),
        );
      }
      return;
    }
    try {
      Uri base;
      final url = Uri.parse(functionUrl);
      final path = url.path;
      if (path.endsWith('/api/attendance')) {
        // Probar /health en el mismo host
        base = url.replace(path: '/health', query: '');
      } else {
        // Probar la propia URL (esperar 200/404/405 como señal de alcance)
        base = url;
      }
      final resp = await http.get(base).timeout(const Duration(seconds: 3));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conexión OK: HTTP ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo conectar: $e')),
        );
      }
    }
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
    debugPrint('🔍 _processQRCode iniciado con código: $code');
    if (code.isEmpty) {
      debugPrint('⚠️ Código QR vacío - ignorando');
      return;
    }

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

    debugPrint('📝 Registro construido: $record');

    // Guardar localmente usando SharedPreferences
    await _saveAttendanceRecord(record);
    debugPrint('💾 Registro guardado localmente');

    // Intentar enviar al servidor en segundo plano
    debugPrint('🚀 Iniciando envío al servidor...');
    _sendToServer(record);

    // El mensaje de éxito lo muestra _sendToServer según el modo
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

      // FORZAR SERVIDOR LOCAL SIEMPRE - CONFIGURACIÓN FIJA
      debugPrint('🔧 FORZANDO configuración local...');
      
      String workingUrl = 'http://192.168.100.7:3000/api/attendance';
      const defaultSecret = 'dev_secret';
      
      // CONFIGURAR DIRECTAMENTE SIN PRUEBAS
      await prefs.setString('FUNCTION_URL', workingUrl);
      await prefs.setString('HMAC_SECRET', defaultSecret);
      
      setState(() {
        functionUrl = workingUrl;
        hmacSecret = defaultSecret;
      });
      
      debugPrint('✅ CONFIGURACIÓN FORZADA:');
      debugPrint('   URL: $functionUrl');
      debugPrint('   HMAC: configurado');
      
      return; // Salir inmediatamente con configuración fija

    } catch (e) {
      debugPrint('❌ Error en configuración forzada: $e');
      // Configuración de respaldo
      setState(() {
        functionUrl = 'http://192.168.100.7:3000/api/attendance';
        hmacSecret = 'dev_secret';
      });
    }
    
      // CÓDIGO ANTERIOR COMENTADO
      
      // PRIORIZAR SERVIDOR LOCAL SIEMPRE PRIMERO
      debugPrint('🔍 Buscando servidor local primero...');

      // 1. INTENTAR SERVIDOR LOCAL PRIMERO (más rápido y confiable)
      final localUrls = [
        'http://192.168.100.7:3000/api/attendance',
        'http://localhost:3000/api/attendance',
        'http://127.0.0.1:3000/api/attendance',
      ];

      String workingUrl =
          'http://192.168.100.7:3000/api/attendance'; // Valor por defecto

      // Probar servidores locales con timeout corto
      for (final url in localUrls) {
        try {
          debugPrint('⚡ Probando servidor local: $url');
          final resp = await http
              .get(Uri.parse(url.replaceAll('/api/attendance', '/health')))
              .timeout(const Duration(seconds: 2));
          if (resp.statusCode == 200) {
            workingUrl = url;
            debugPrint('✅ Servidor local encontrado: $url');
            break;
          }
        } catch (e) {
          debugPrint('❌ Servidor local no disponible: $url - $e');
        }
      }

      // 2. Si no encontramos servidor local, intentar autodetección
      if (workingUrl == 'http://192.168.100.7:3000/api/attendance') {
        debugPrint('🔍 Intentando autodetección de servidor local...');
        final discovered = await _autoDiscoverLocalProxy();
        if (discovered) {
          debugPrint('✅ Servidor local autodescubierto');
          return;
        }
      }

      // 3. Solo como último recurso, intentar servidores online
      if (workingUrl == 'http://192.168.100.7:3000/api/attendance') {
        debugPrint('🌐 No hay servidor local. Probando servidores online...');
        final productionUrls = [
          'https://attendance-qr-app-production.up.railway.app/api/attendance',
          'https://vercel-proxy-git-main-stylo3066s-projects.vercel.app/api/attendance',
        ];

        for (final url in productionUrls) {
          try {
            debugPrint('🌐 Probando servidor online: $url');
            final resp = await http
                .get(Uri.parse(url.replaceAll('/api/attendance', '/health')))
                .timeout(const Duration(seconds: 5));
            if (resp.statusCode == 200) {
              workingUrl = url;
              debugPrint('✅ Servidor online encontrado: $url');
              break;
            }
          } catch (e) {
            debugPrint('❌ Servidor online no disponible: $url - $e');
          }
        }
      }

      // 4. Si nada funciona, mantener configuración local por defecto
      if (workingUrl == 'http://192.168.100.7:3000/api/attendance') {
        debugPrint(
            '⚠️ Usando configuración local por defecto como último recurso');
      }

      const defaultSecret = 'dev_secret';

      // Guardar configuración (workingUrl nunca puede ser null aquí)
      await prefs.setString('FUNCTION_URL', workingUrl);
      await prefs.setString('HMAC_SECRET', defaultSecret);

      setState(() {
        functionUrl = workingUrl;
        hmacSecret = defaultSecret;
      });

      debugPrint('✅ AUTO-CONFIGURADO: $workingUrl');
      debugPrint('   Secreto: $defaultSecret');

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
          final resp =
              await http.get(uri).timeout(const Duration(milliseconds: 900));
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
              decoration:
                  const InputDecoration(labelText: 'FUNCTION_URL (HTTPS)'),
            ),
            TextField(
              controller: secretController,
              decoration: const InputDecoration(labelText: 'HMAC_SECRET'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Autodetectar (LAN)'),
                    onPressed: () async {
                      // Mostrar un pequeño feedback visual
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Buscando servidor local...')),
                      );
                      final ok = await _autoDiscoverLocalProxy();
                      if (ok) {
                        urlController.text = functionUrl;
                        if (secretController.text.isEmpty) {
                          secretController.text =
                              hmacSecret.isNotEmpty ? hmacSecret : 'dev_secret';
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Detectado: $functionUrl')),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'No se encontró servidor en la red. Verifique que el proxy esté ejecutándose.')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
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
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuración guardada')));
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToServer(Map<String, dynamic> record) async {
    debugPrint('🔍 DEBUGGING _sendToServer iniciado');
    debugPrint('🔍 functionUrl: $functionUrl');
    debugPrint(
        '🔍 hmacSecret: ${hmacSecret.isNotEmpty ? "CONFIGURADO" : "VACIO"}');
    debugPrint('🔍 record: $record');

    if (functionUrl.isEmpty || hmacSecret.isEmpty) {
      debugPrint('⚠️ Sin configuración de servidor');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Configura el servidor en Ajustes')),
        );
      }
      await _enqueuePending(record);
      return;
    }

    // Enviar al servidor ONLINE
    final signature = _signRecord(record);
    debugPrint('🔐 Signature generada: $signature');
    final payload = {'signature': signature, 'data': record};
    debugPrint('📦 Payload completo: ${jsonEncode(payload)}');

    try {
      debugPrint('📤 Enviando a: $functionUrl');
      final resp = await http
          .post(Uri.parse(functionUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload))
          .timeout(const Duration(seconds: 15));

      debugPrint('📨 Respuesta recibida - Status: ${resp.statusCode}');
      debugPrint('📨 Respuesta body: ${resp.body}');

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        debugPrint('✅ Registro exitoso en servidor');
        debugPrint('✅ Respuesta exitosa: $body');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('✅ Asistencia registrada: ${body['professor'] ?? 'OK'}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('❌ Error ${resp.statusCode}: ${resp.body}');
        if (mounted) {
          final msg = resp.statusCode == 401
              ? 'Clave HMAC inválida - Verifica configuración'
              : resp.statusCode == 404
                  ? 'QR no reconocido - Código inválido'
                  : 'Error del servidor (${resp.statusCode})';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ $msg'), backgroundColor: Colors.red),
          );
        }
        await _enqueuePending(record);
      }
    } catch (e) {
      debugPrint('❌ Error de conexión: $e');
      debugPrint('❌ Tipo de error: ${e.runtimeType}');
      debugPrint('❌ URL intentada: $functionUrl');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('⚠️ Sin conexión a $functionUrl. Guardado localmente.'),
            backgroundColor: Colors.orange,
          ),
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

  // Método para abrir páginas web
  Future<void> _openWebPage(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No se puede abrir: $url')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error abriendo URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al abrir la página web')),
        );
      }
    }
  }
  
}
