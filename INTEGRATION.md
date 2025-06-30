# BreakTime Tracker Flutter - Integración con Supabase

## 📋 Estructura de Base de Datos

Esta aplicación Flutter está configurada para trabajar con tu proyecto de Supabase que incluye las siguientes tablas:

### Tablas Principales:

#### 1. **usuarios** (Empleados)
- `id` (uuid4) - ID único del usuario
- `nombre` (varchar) - Nombre completo del empleado  
- `codigo` (varchar) - Código de la tarjeta RFID/Código de barras
- `turno` (varchar) - Turno del empleado
- `activo` (bool) - Estado activo/inactivo
- `created_at` (timestamp) - Fecha de creación
- `updated_at` (timestamp) - Fecha de actualización

#### 2. **descansos** (Registros de Descansos)
- `id` (uuid4) - ID único del descanso
- `usuario_id` (uuid4) - FK hacia usuarios
- `tipo` (varchar) - Tipo de descanso
- `fecha` (date) - Fecha del descanso
- `inicio` (time) - Hora de inicio del descanso
- `fin` (time) - Hora de fin del descanso (NULL mientras está activo)
- `duracion_minutos` (int4) - Duración calculada en minutos
- `created_at` (timestamp) - Fecha de creación

#### 3. **tiempos_descanso** (Configuración)
- `id` (uuid4) - ID único
- `usuario_id` (uuid4) - FK hacia usuarios
- `tipo` (varchar) - Tipo de descanso
- `fecha` (date) - Fecha
- `inicio` (time) - Hora inicio
- `fin` (time) - Hora fin
- `duracion_minutos` (int4) - Duración
- `created_at` (timestamp) - Fecha creación

#### 4. **administradores** (Gestión de usuarios admin)
- `id` (uuid4) - ID único
- `usuario` (varchar) - Usuario administrador
- `clave` (varchar) - Contraseña
- `nombre` (varchar) - Nombre del administrador
- `activo` (bool) - Estado activo
- `ultimo_acceso` (timestampz) - Último acceso
- `created_at` (timestampz) - Fecha creación
- `updated_at` (timestampz) - Fecha actualización

## 🔧 Configuración de la Aplicación

### 1. Credenciales de Supabase

Edita el archivo `lib/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'TU_SUPABASE_URL';
  static const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
}
```

### 2. Estructura de Consultas

**✅ CORREGIDO** - La aplicación ahora usa la sintaxis correcta para consultas NULL:

- **Descansos activos**: `.isFilter('fin', null)` - Busca registros donde `fin` es NULL
- **Empleados en descanso**: `select('*, usuarios!inner(*)')` - Join con información del empleado
- **Actualización de regreso**: `update({'fin': timestamp})` - Marca fin del descanso
Actualiza el archivo `lib/config/supabase_config.dart` con las credenciales de tu proyecto:

```dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://ppyowdavsbkhvxzvaviy.supabase.co';
  static const String supabaseAnonKey = 'tu-anon-key-aqui';
}
```

### 2. Mapeo de Campos
La aplicación Flutter mapea los campos de la siguiente manera:

**Consultas de Usuarios:**
- `usuarios.codigo` → Código de tarjeta para buscar empleado
- `usuarios.nombre` → Nombre a mostrar en la interfaz

**Registros de Descansos:**
- `descansos.usuario_id` → ID del empleado
- `descansos.tipo = 'descanso'` → Filtro por tipo de descanso
- `descansos.inicio` → Hora de salida a descanso
- `descansos.fin` → Hora de regreso (NULL = aún en descanso)

## 🚀 Funcionalidades Implementadas

### ✅ **Lectura de Tarjetas**
- Compatible con lectores RFID/códigos de barras
- Soporte para teclado inalámbrico
- Auto-procesamiento para códigos largos
- Procesamiento manual con ENTER

### ✅ **Gestión de Descansos**
- Registro automático de salida/regreso
- Cálculo de tiempo restante (30 min por defecto)
- Alertas visuales para tiempo excedido
- Actualización en tiempo real

### ✅ **Modo Demo**
Se activa automáticamente si la base de datos no está disponible:

**Códigos de Prueba:**
- `001` - Juan Pérez
- `002` - María García
- `003` - Carlos López
- `004` - Ana Martínez

### ✅ **Interfaz de Usuario**
- Tema oscuro moderno
- Indicadores visuales de estado
- Contador de tiempo en vivo
- Lista de empleados en descanso
- Responsive design

## 🔗 Relaciones de Base de Datos

```sql
-- Relación: descansos → usuarios
ALTER TABLE descansos 
ADD CONSTRAINT fk_descansos_usuario 
FOREIGN KEY (usuario_id) REFERENCES usuarios(id);

-- Relación: tiempos_descanso → usuarios  
ALTER TABLE tiempos_descanso
ADD CONSTRAINT fk_tiempos_usuario
FOREIGN KEY (usuario_id) REFERENCES usuarios(id);
```

## 📱 Uso de la Aplicación

### **Registro de Empleados**
1. Agregar empleados en la tabla `usuarios`
2. Asignar códigos únicos en el campo `codigo`
3. Activar el empleado con `activo = true`

### **Proceso de Descanso**
1. **Primera vez**: Empleado pasa tarjeta → Se registra salida
2. **Segunda vez**: Empleado pasa tarjeta → Se registra regreso
3. **Monitoreo**: La pantalla muestra empleados en descanso activo

### **Configuración de Tiempo**
Modificar duración del descanso en el código:
```dart
final remaining = const Duration(minutes: 30) - elapsed; // Cambiar 30
```

## 🛠️ Comandos de Desarrollo

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en web (recomendado para pruebas)
flutter run -d chrome

# Ejecutar en Android (requiere Modo Desarrollador)
flutter run

# Limpiar caché
flutter clean

# Analizar código
flutter analyze
```

## 🔧 Solución de Problemas

### **Error: "relation does not exist"**
- Verificar que las tablas existan en Supabase
- Revisar credenciales en `supabase_config.dart`
- Verificar políticas RLS (Row Level Security)

### **Error: "Card not found"**
- Verificar que el empleado esté registrado
- Confirmar que el código de tarjeta sea correcto
- Revisar que `activo = true`

### **Modo Demo se activa automáticamente**
- Normal cuando la BD no está configurada
- Usar códigos de prueba: 001, 002, 003, 004

### **Android no compila**
- Habilitar Modo Desarrollador en Windows
- Ejecutar: `start ms-settings:developers`
- Activar "Modo de desarrollador"

## 📊 Consultas SQL de Ejemplo

```sql
-- Ver empleados en descanso activo
SELECT u.nombre, d.inicio, d.tipo
FROM descansos d
JOIN usuarios u ON d.usuario_id = u.id  
WHERE d.fin IS NULL AND d.tipo = 'descanso';

-- Reporte de descansos por fecha
SELECT u.nombre, d.fecha, d.inicio, d.fin, d.duracion_minutos
FROM descansos d
JOIN usuarios u ON d.usuario_id = u.id
WHERE d.fecha = CURRENT_DATE
ORDER BY d.inicio;

-- Empleados con más tiempo de descanso
SELECT u.nombre, SUM(d.duracion_minutos) as total_minutos
FROM descansos d
JOIN usuarios u ON d.usuario_id = u.id
WHERE d.fecha >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY u.id, u.nombre
ORDER BY total_minutos DESC;
```

## 🚀 Próximas Mejoras

- [ ] Panel de administración web
- [ ] Reportes y estadísticas  
- [ ] Configuración de tiempo por empleado
- [ ] Notificaciones push
- [ ] Exportación de datos
- [ ] Múltiples tipos de descanso

---

Para más información, consulta el repositorio: https://github.com/kennyAguilar/BreakTimeTracker-Supabase
