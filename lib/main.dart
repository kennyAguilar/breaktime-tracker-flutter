import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar localización
  await initializeDateFormatting('es_ES', null);

  // Inicializar Supabase con manejo de errores detallado
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
      debug: true, // Habilitar logs detallados
    );
    debugPrint('✅ Supabase inicializado correctamente');
    debugPrint('URL: ${SupabaseConfig.supabaseUrl}');
  } catch (e) {
    debugPrint('❌ Error inicializando Supabase: $e');
    debugPrint('URL: ${SupabaseConfig.supabaseUrl}');
    debugPrint('Key length: ${SupabaseConfig.supabaseAnonKey.length}');
  }

  runApp(const BreakTimeApp());
}

class BreakTimeApp extends StatelessWidget {
  const BreakTimeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BreakTime Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1F2937),
      ),
      home: const CardReaderScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CardReaderScreen extends StatefulWidget {
  const CardReaderScreen({Key? key}) : super(key: key);

  @override
  State<CardReaderScreen> createState() => _CardReaderScreenState();
}

class _CardReaderScreenState extends State<CardReaderScreen> {
  final TextEditingController _cardController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final supabase = Supabase.instance.client;

  bool _isProcessing = false;
  String _statusMessage = '';
  List<Map<String, dynamic>> _employeesOnBreak = [];
  Timer? _refreshTimer;
  StreamSubscription? _breakSubscription;

  // Variables para modo demo
  bool _demoMode = false;
  final List<Map<String, dynamic>> _demoEmployees = [
    {'id': '1', 'nombre': 'Juan Pérez', 'tarjeta': '001', 'codigo': 'JP001'},
    {'id': '2', 'nombre': 'María García', 'tarjeta': '002', 'codigo': 'MG002'},
    {'id': '3', 'nombre': 'Carlos López', 'tarjeta': '003', 'codigo': 'CL003'},
    {'id': '4', 'nombre': 'Ana Martínez', 'tarjeta': '004', 'codigo': 'AM004'},
    {
      'id': '5',
      'nombre': 'Kenny Aguilar',
      'tarjeta': '9636979',
      'codigo': 'KA22'
    },
    {'id': '6', 'nombre': 'Usuario Test', 'tarjeta': 'HP30', 'codigo': 'UT30'},
    {'id': '7', 'nombre': 'Demo User', 'tarjeta': 'VS26', 'codigo': 'DU26'},
    {'id': '8', 'nombre': 'Test Demo', 'tarjeta': 'CB29', 'codigo': 'TD29'},
  ];
  final List<Map<String, dynamic>> _demoBreaks = [];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();

    // Ejecutar diagnóstico simplificado al inicializar
    _performDiagnosis();

    // Configurar suscripción de tiempo real con manejo de errores
    _setupRealtimeSubscriptionSafe();

    // Cargar empleados con manejo de errores
    _fetchEmployeesOnBreakSafe();

    // Actualizar cada 30 segundos para refrescar tiempos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchEmployeesOnBreakSafe();
    });
  }

  Future<void> _performDiagnosis() async {
    debugPrint('\n=== 🔍 DIAGNÓSTICO SIMPLIFICADO ===');

    try {
      // Test básico: consultar tabla usuarios con el esquema real
      final result = await supabase
          .from('usuarios')
          .select('tarjeta, nombre, codigo')
          .limit(3);

      debugPrint('✅ CONEXIÓN EXITOSA: ${result.length} usuarios encontrados');
      for (final user in result) {
        debugPrint(
            '  📋 Tarjeta: ${user['tarjeta']} - ${user['nombre']} (Código: ${user['codigo']})');
      }

      setState(() {
        _statusMessage = '✅ Base de datos conectada';
      });
    } catch (e) {
      debugPrint('❌ ERROR DE CONEXIÓN: $e');

      // Determinar tipo de error
      String errorMsg = '';
      if (e.toString().contains('relation') &&
          e.toString().contains('does not exist')) {
        errorMsg = '❌ Tabla "usuarios" no existe en BD';
      } else if (e.toString().contains('401')) {
        errorMsg = '🔐 Error de autenticación con BD';
      } else if (e.toString().contains('403')) {
        errorMsg = '🚫 Sin permisos de acceso (RLS)';
      } else if (e.toString().contains('timeout') ||
          e.toString().contains('network')) {
        errorMsg = '🌐 Error de red o timeout';
      } else {
        errorMsg = '❌ Error desconocido de BD';
      }

      debugPrint('🔍 Diagnóstico: $errorMsg');

      setState(() {
        _demoMode = true;
        _statusMessage = '$errorMsg - Modo demo activo';
      });
    }

    // Limpiar mensaje después de 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _statusMessage.isNotEmpty) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  void _setupRealtimeSubscriptionSafe() {
    try {
      _breakSubscription =
          supabase.from('tiempos_descanso').stream(primaryKey: ['id']).listen(
        (List<Map<String, dynamic>> data) {
          _fetchEmployeesOnBreakSafe();
        },
        onError: (error) {
          debugPrint('Error en suscripción tiempo real: $error');
        },
      );
    } catch (e) {
      debugPrint('Error configurando suscripción: $e');
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    _focusNode.dispose();
    _refreshTimer?.cancel();
    _breakSubscription?.cancel();
    super.dispose();
  }

  Future<void> _processCard(String cardCode) async {
    if (cardCode.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Procesando tarjeta...';
    });

    try {
      // Intentar con base de datos real primero
      await _processCardDatabase(cardCode);
    } catch (e) {
      // Si falla, usar modo demo
      debugPrint('Error de BD, usando modo demo: $e');
      await _processCardDemo(cardCode);
    }

    // Limpiar el campo y mantener el foco
    _cardController.clear();

    // Re-enfocar después de un momento para evitar conflictos
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });

    setState(() {
      _isProcessing = false;
    });

    // Limpiar mensaje después de 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _statusMessage = '';
        });
      }
    });
  }

  Future<void> _processCardDatabase(String cardCode) async {
    // Normalizar código (mayúsculas y sin espacios)
    final normalizedCode = cardCode.trim().toUpperCase();

    try {
      // Buscar empleado por código de tarjeta en tabla 'usuarios' usando campo 'tarjeta'
      debugPrint('🔍 Buscando empleado con tarjeta: $normalizedCode');

      final employeeResponse = await supabase
          .from('usuarios')
          .select()
          .eq('tarjeta', normalizedCode)
          .eq('activo', true) // Solo usuarios activos
          .maybeSingle();

      debugPrint('📋 Respuesta de búsqueda: $employeeResponse');

      if (employeeResponse == null) {
        setState(() {
          _statusMessage = 'Tarjeta no registrada: $normalizedCode';
        });
        return;
      }

      final employeeId = employeeResponse['id'];
      final employeeName = employeeResponse['nombre'];

      // Verificar si el empleado tiene un descanso activo en tabla 'tiempos_descanso'
      // Buscar descansos donde fin sea NULL
      debugPrint('🔍 Buscando descanso activo para empleado ID: $employeeId');

      final today =
          DateTime.now().toIso8601String().split('T')[0]; // Solo fecha

      final activeBreakResponse = await supabase
          .from('tiempos_descanso')
          .select()
          .eq('usuario_id', employeeId)
          .eq('fecha', today)
          .isFilter('fin', null)
          .maybeSingle();

      debugPrint('📋 Respuesta de descanso activo: $activeBreakResponse');

      if (activeBreakResponse != null) {
        // Registrar regreso del descanso - actualizar campo fin
        final now = DateTime.now();
        final timeOnly = DateFormat('HH:mm:ss').format(now);

        // Calcular duración en minutos
        final inicio = activeBreakResponse['inicio'];
        final inicioTime = DateFormat('HH:mm:ss').parse(inicio);
        final finTime = DateFormat('HH:mm:ss').parse(timeOnly);
        final duracionMinutos = finTime.difference(inicioTime).inMinutes;

        await supabase.from('tiempos_descanso').update({
          'fin': timeOnly,
          'duracion_minutos': duracionMinutos,
        }).eq('id', activeBreakResponse['id']);

        setState(() {
          _statusMessage =
              '✅ $employeeName ha regresado del descanso ($duracionMinutos min)';
        });
      } else {
        // Registrar salida a descanso
        final now = DateTime.now();
        final timeOnly = DateFormat('HH:mm:ss').format(now);

        await supabase.from('tiempos_descanso').insert({
          'usuario_id': employeeId,
          'tipo': 'descanso',
          'fecha': today,
          'inicio': timeOnly,
          'fin': null, // Explícitamente NULL para descanso activo
        });

        setState(() {
          _statusMessage = '🟡 $employeeName ha salido a descanso';
        });
      }

      _fetchEmployeesOnBreakSafe();
    } catch (e, stackTrace) {
      debugPrint('❌ Error detallado en _processCardDatabase: $e');
      debugPrint('📍 Stack trace: $stackTrace');

      // Re-lanzar el error para que sea manejado por _processCard
      rethrow;
    }
  }

  Future<void> _processCardDemo(String cardCode) async {
    // Activar modo demo
    _demoMode = true;

    // Normalizar código (mayúsculas y sin espacios)
    final normalizedCode = cardCode.trim().toUpperCase();

    // Buscar empleado en datos demo por tarjeta (comparación case-insensitive)
    final employee = _demoEmployees.firstWhere(
      (emp) => emp['tarjeta'].toString().toUpperCase() == normalizedCode,
      orElse: () => {},
    );

    if (employee.isEmpty) {
      setState(() {
        _statusMessage = '❌ DEMO: Tarjeta no encontrada: $normalizedCode';
      });
      return;
    }

    final employeeName = employee['nombre'];
    final employeeId = employee['id'];

    // Verificar si ya está en descanso
    final existingBreakIndex = _demoBreaks.indexWhere(
      (br) => br['usuario_id'] == employeeId && br['fin'] == null,
    );

    if (existingBreakIndex >= 0) {
      // Registrar regreso
      final now = DateTime.now();
      final timeOnly = DateFormat('HH:mm:ss').format(now);

      // Calcular duración
      final inicio = _demoBreaks[existingBreakIndex]['inicio'];
      final inicioTime = DateFormat('HH:mm:ss').parse(inicio);
      final finTime = DateFormat('HH:mm:ss').parse(timeOnly);
      final duracionMinutos = finTime.difference(inicioTime).inMinutes;

      _demoBreaks[existingBreakIndex]['fin'] = timeOnly;
      _demoBreaks[existingBreakIndex]['duracion_minutos'] = duracionMinutos;

      setState(() {
        _statusMessage =
            '✅ DEMO: $employeeName ha regresado del descanso ($duracionMinutos min)';
      });
    } else {
      // Registrar salida
      final now = DateTime.now();
      final timeOnly = DateFormat('HH:mm:ss').format(now);

      _demoBreaks.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'usuario_id': employeeId,
        'usuarios': employee,
        'inicio': timeOnly,
        'fin': null,
        'tipo': 'descanso',
        'fecha': now.toIso8601String().split('T')[0],
      });
      setState(() {
        _statusMessage = '🟡 DEMO: $employeeName ha salido a descanso';
      });
    }

    // Actualizar lista de empleados en descanso
    setState(() {
      _employeesOnBreak = _demoBreaks.where((br) => br['fin'] == null).toList();
    });
  }

  Future<void> _fetchEmployeesOnBreakSafe() async {
    try {
      debugPrint('🔍 Intentando cargar empleados en descanso...');

      final today =
          DateTime.now().toIso8601String().split('T')[0]; // Solo fecha

      final response = await supabase
          .from('tiempos_descanso')
          .select('*, usuarios!inner(*)')
          .eq('fecha', today)
          .isFilter('fin', null) // Buscar solo descansos activos (fin = NULL)
          .order('inicio', ascending: false);

      debugPrint('📋 Respuesta de empleados en descanso: $response');
      debugPrint('📊 Número de empleados en descanso: ${response.length}');

      if (mounted) {
        setState(() {
          _employeesOnBreak = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e, stackTrace) {
      // Si hay error de base de datos, mostrar mensaje informativo
      debugPrint('❌ Error detallado al cargar empleados: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      debugPrint('🔧 Tipo de error: ${e.runtimeType}');

      if (mounted) {
        if (e.toString().contains('relation') &&
            e.toString().contains('does not exist')) {
          setState(() {
            _statusMessage =
                '⚠️ Tablas de BD no encontradas. Usando modo demo.';
          });
        } else if (e.toString().contains('401') ||
            e.toString().contains('403')) {
          setState(() {
            _statusMessage =
                '🔐 Error de autenticación con BD. Usando modo demo.';
          });
        } else if (e.toString().contains('timeout') ||
            e.toString().contains('network')) {
          setState(() {
            _statusMessage = '🌐 Error de conexión a BD. Usando modo demo.';
          });
        } else {
          setState(() {
            _statusMessage =
                '❌ Error de BD: ${e.toString().substring(0, 50)}...';
          });
        }

        // Limpiar mensaje después de 5 segundos
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _statusMessage = '';
            });
          }
        });
      }
    }
  }

  String _calculateRemainingTime(String startTime) {
    try {
      // Convertir tiempo HH:mm:ss a DateTime de hoy
      final today = DateTime.now();
      final timeParts = startTime.split(':');
      final start = DateTime(
        today.year,
        today.month,
        today.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
        timeParts.length > 2 ? int.parse(timeParts[2]) : 0,
      );

      final now = DateTime.now();
      final elapsed = now.difference(start);
      final remaining = const Duration(minutes: 30) - elapsed;

      if (remaining.isNegative) {
        return 'Tiempo excedido';
      }

      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '--:--';
    try {
      // Si es formato HH:mm:ss, tomar solo HH:mm
      if (timeStr.contains(':')) {
        final parts = timeStr.split(':');
        return '${parts[0]}:${parts[1]}';
      }
      return timeStr;
    } catch (e) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isMobile = screenWidth < 480;

    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Header adaptativo
                  Container(
                    padding: EdgeInsets.all(isTablet
                        ? 32
                        : isMobile
                            ? 16
                            : 24),
                    child: Column(
                      children: [
                        Text(
                          'BreakTime Tracker',
                          style: TextStyle(
                            fontSize: isTablet
                                ? 40
                                : isMobile
                                    ? 24
                                    : 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy', 'es_ES')
                              .format(DateTime.now()),
                          style: TextStyle(
                            fontSize: isTablet
                                ? 18
                                : isMobile
                                    ? 14
                                    : 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card Reader Section adaptativo
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet
                          ? 48
                          : isMobile
                              ? 16
                              : 24,
                    ),
                    padding: EdgeInsets.all(isTablet
                        ? 32
                        : isMobile
                            ? 16
                            : 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51), // Corrección de withOpacity
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.credit_card,
                              size: isTablet
                                  ? 64
                                  : isMobile
                                      ? 40
                                      : 48,
                              color: Colors.blue,
                            ),
                            SizedBox(width: isTablet ? 24 : 16),
                            Icon(
                              Icons.keyboard,
                              size: isTablet
                                  ? 64
                                  : isMobile
                                      ? 40
                                      : 48,
                              color: Colors.green,
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 24 : 16),
                        Text(
                          'Pase su tarjeta por el lector',
                          style: TextStyle(
                            fontSize: isTablet
                                ? 24
                                : isMobile
                                    ? 16
                                    : 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isTablet ? 12 : 8),
                        Text(
                          'O escriba el código con teclado y presione ENTER',
                          style: TextStyle(
                            fontSize: isTablet
                                ? 16
                                : isMobile
                                    ? 12
                                    : 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isTablet ? 24 : 16),
                        TextField(
                          controller: _cardController,
                          focusNode: _focusNode,
                          autofocus: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Código de tarjeta',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: isTablet
                                  ? 18
                                  : isMobile
                                      ? 14
                                      : 16,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF4B5563),
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(8)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 24 : 16,
                              vertical: isTablet ? 20 : 16,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet
                                ? 20
                                : isMobile
                                    ? 14
                                    : 16,
                          ),
                          onChanged: (value) {
                            // Auto-procesar si el código tiene más de 5 caracteres
                            // (común para códigos de barras/RFID)
                            if (value.length >= 6) {
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                _processCard(value);
                              });
                            }
                          },
                          onSubmitted: (value) {
                            _processCard(value);
                          },
                        ),
                        if (_statusMessage.isNotEmpty) ...[
                          SizedBox(height: isTablet ? 20 : 16),
                          Container(
                            padding: EdgeInsets.all(isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: _statusMessage.contains('Error') ||
                                      _statusMessage.contains('❌')
                                  ? Colors.red.withAlpha(51) // Corrección de withOpacity
                                  : _statusMessage.contains('⚠️')
                                      ? Colors.orange.withAlpha(51) // Corrección de withOpacity
                                      : Colors.green.withAlpha(51), // Corrección de withOpacity
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _statusMessage.contains('Error') ||
                                        _statusMessage.contains('❌')
                                    ? Colors.red
                                    : _statusMessage.contains('⚠️')
                                        ? Colors.orange
                                        : Colors.green,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _statusMessage.contains('Error') ||
                                          _statusMessage.contains('❌')
                                      ? Icons.error_outline
                                      : _statusMessage.contains('⚠️')
                                          ? Icons.warning_outlined
                                          : Icons.check_circle_outline,
                                  color: _statusMessage.contains('Error') ||
                                          _statusMessage.contains('❌')
                                      ? Colors.red
                                      : _statusMessage.contains('⚠️')
                                          ? Colors.orange
                                          : Colors.green,
                                  size: isTablet ? 24 : 20,
                                ),
                                SizedBox(width: isTablet ? 12 : 8),
                                Expanded(
                                  child: Text(
                                    _statusMessage,
                                    style: TextStyle(
                                      color: _statusMessage.contains('Error') ||
                                              _statusMessage.contains('❌')
                                          ? Colors.red
                                          : _statusMessage.contains('⚠️')
                                              ? Colors.orange
                                              : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_isProcessing) ...[
                          SizedBox(height: isTablet ? 20 : 16),
                          CircularProgressIndicator(
                            color: Colors.blue,
                            strokeWidth: isTablet ? 4 : 3,
                          ),
                        ],
                      ],
                    ),
                  ),

                  SizedBox(height: isTablet ? 32 : 24),

                  // Employees on Break Section adaptativo
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isTablet
                            ? 48
                            : isMobile
                                ? 16
                                : 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                color: Colors.white,
                                size: isTablet ? 28 : 24,
                              ),
                              SizedBox(width: isTablet ? 12 : 8),
                              Text(
                                'Empleados en Descanso',
                                style: TextStyle(
                                  fontSize: isTablet ? 22 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              if (_demoMode)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 12 : 8,
                                    vertical: isTablet ? 6 : 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'MODO DEMO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isTablet ? 14 : 12,
                                    ),
                                  ),
                                ),
                              SizedBox(width: isTablet ? 12 : 8),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 16 : 12,
                                  vertical: isTablet ? 8 : 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4B5563),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${_employeesOnBreak.length} en descanso',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isTablet ? 16 : 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 20 : 16),
                          Expanded(
                            child: _employeesOnBreak.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: isTablet ? 80 : 60,
                                          color: Colors.green,
                                        ),
                                        SizedBox(height: isTablet ? 20 : 16),
                                        Text(
                                          'Nadie está en descanso',
                                          style: TextStyle(
                                            fontSize: isTablet ? 20 : 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _employeesOnBreak.length,
                                    itemBuilder: (context, index) {
                                      final record = _employeesOnBreak[index];
                                      final employee = record['usuarios'];
                                      final startTime = record['inicio'];
                                      final remainingTime =
                                          _calculateRemainingTime(startTime);
                                      final isOvertime =
                                          remainingTime == 'Tiempo excedido';

                                      return Container(
                                        margin: EdgeInsets.only(
                                          bottom: isTablet ? 16 : 12,
                                        ),
                                        padding: EdgeInsets.all(
                                          isTablet
                                              ? 20
                                              : isMobile
                                                  ? 12
                                                  : 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOvertime
                                              ? const Color(0xFF7F1D1D)
                                              : const Color(0xFF374151),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: isOvertime
                                              ? Border.all(
                                                  color: Colors.red, width: 2)
                                              : null,
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isOvertime
                                                  ? Colors.red
                                                  : Colors.blue,
                                              radius: isTablet
                                                  ? 28
                                                  : isMobile
                                                      ? 20
                                                      : 24,
                                              child: Text(
                                                employee['nombre']
                                                        ?.substring(0, 1)
                                                        .toUpperCase() ??
                                                    '?',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isTablet
                                                      ? 20
                                                      : isMobile
                                                          ? 14
                                                          : 16,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: isTablet ? 20 : 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    employee['nombre'] ??
                                                        'Desconocido',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: isTablet
                                                          ? 20
                                                          : isMobile
                                                              ? 14
                                                              : 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height: isTablet ? 6 : 4),
                                                  Text(
                                                    'Salió: ${_formatTime(startTime)}',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: isTablet
                                                          ? 16
                                                          : isMobile
                                                              ? 12
                                                              : 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isTablet ? 16 : 12,
                                                vertical: isTablet ? 8 : 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isOvertime
                                                    ? Colors.red
                                                    : Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                remainingTime,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isTablet
                                                      ? 14
                                                      : isMobile
                                                          ? 10
                                                          : 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 20 : 16),

                  // Sección de ayuda para demo adaptativa
                  if (_demoMode)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet
                            ? 48
                            : isMobile
                                ? 16
                                : 24,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(25), // Corrección: withOpacity -> withAlpha
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Modo Demo Activo',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: isTablet ? 12 : 8),
                            Text(
                              'La conexión con la base de datos falló. Puedes usar estos códigos de tarjeta para probar:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isTablet ? 16 : 14,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: isTablet ? 16 : 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: _demoEmployees
                                  .map(
                                    (e) => Chip(
                                      label: Text(e['tarjeta'] ?? ''),
                                      backgroundColor: const Color(0xFF374151),
                                      labelStyle:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
