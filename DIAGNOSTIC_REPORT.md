# Diagnóstico de Conectividad Supabase - Estado Actual

## Problema Principal
La aplicación Flutter BreakTime Tracker no se conecta a Supabase y siempre entra en modo demo automáticamente.

## Configuración Actual

### Credenciales Supabase
- **URL**: `https://ppyowdavsbkhvxzvaviy.supabase.co`
- **API Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBweW93ZGF2c2JraHZ4enZhdml5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5MTU4NjMsImV4cCI6MjA2NjQ5MTg2M30.ZFfAvT5icazQ1yh_JFYbQ-xbMunPJ8Q4Y47SpWWID2s`

### Esquema de Base de Datos Esperado
- **Tabla principal**: `usuarios`
  - Campos: `id`, `codigo`, `nombre`
- **Tabla de registros**: `descansos`
  - Campos: `id`, `usuario_id`, `tipo`, `fecha`, `inicio`, `fin`
  - Relación: `usuario_id` → `usuarios.id`

## Implementación Actual

### Funcionalidades Implementadas ✅
1. **Inicialización robusta de Supabase** con logs detallados
2. **Manejo de errores completo** con fallback automático a modo demo
3. **Diagnóstico automático** al inicializar la aplicación
4. **Modo demo funcional** con empleados y códigos de prueba
5. **UI adaptativa** para móvil, tablet y escritorio
6. **Códigos de prueba** incluidos: KA22, HP30, VS26, CB29, 001-004

### Archivos de Diagnóstico Creados 🔧
- `test_http_direct.dart` - Test HTTP directo sin dependencias Flutter
- `diagnose_supabase.dart` - Test completo de conectividad
- `test_supabase_detailed.dart` - Test detallado existente
- `simple_test.dart` - Test básico

## Posibles Causas del Problema

### 1. **Tabla no existe** (más probable)
```
Error: relation "usuarios" does not exist
```
- **Causa**: La tabla `usuarios` no está creada en Supabase
- **Solución**: Crear tabla en Supabase con los campos correctos

### 2. **Políticas RLS (Row Level Security)**
```
Error: 403 Forbidden
```
- **Causa**: Políticas RLS muy restrictivas
- **Solución**: Configurar políticas para permitir lectura anónima

### 3. **Credenciales incorrectas**
```
Error: 401 Unauthorized
```
- **Causa**: API key incorrecta o expirada
- **Solución**: Verificar credenciales en dashboard Supabase

### 4. **Error de red/conectividad**
```
Error: timeout, network error
```
- **Causa**: Problemas de conectividad
- **Solución**: Verificar conexión a internet

## Próximos Pasos para Diagnóstico

### Paso 1: Verificar Existencia de Tablas
```sql
-- Ejecutar en Supabase SQL Editor
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

### Paso 2: Crear Tabla si no existe
```sql
-- Crear tabla usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Crear tabla descansos
CREATE TABLE IF NOT EXISTS descansos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES usuarios(id),
    tipo VARCHAR(50) DEFAULT 'descanso',
    fecha DATE NOT NULL,
    inicio TIMESTAMP WITH TIME ZONE NOT NULL,
    fin TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Paso 3: Insertar Datos de Prueba
```sql
-- Insertar usuarios de prueba
INSERT INTO usuarios (codigo, nombre) VALUES
('001', 'Juan Pérez'),
('002', 'María García'),
('003', 'Carlos López'),
('004', 'Ana Martínez'),
('KA22', 'Kenny Aguilar'),
('HP30', 'Usuario Test'),
('VS26', 'Demo User'),
('CB29', 'Test Demo')
ON CONFLICT (codigo) DO NOTHING;
```

### Paso 4: Configurar Políticas RLS
```sql
-- Habilitar RLS
ALTER TABLE usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE descansos ENABLE ROW LEVEL SECURITY;

-- Crear políticas para lectura anónima
CREATE POLICY "Allow anonymous read usuarios" ON usuarios
    FOR SELECT USING (true);

CREATE POLICY "Allow anonymous read descansos" ON descansos
    FOR SELECT USING (true);

-- Políticas para inserción/actualización (más restrictivas si es necesario)
CREATE POLICY "Allow anonymous insert descansos" ON descansos
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow anonymous update descansos" ON descansos
    FOR UPDATE USING (true);
```

## Comandos de Testing

### Para ejecutar en la aplicación Flutter:
```bash
flutter run -d chrome --debug
```

### Para ejecutar tests independientes:
```bash
dart run test_http_direct.dart
dart run diagnose_supabase.dart
```

## Estado del Código

### Archivo Principal: `lib/main.dart`
- ✅ Restaurado y funcional
- ✅ Diagnóstico automático implementado
- ✅ Logs detallados de errores
- ✅ Fallback a modo demo

### Configuración: `lib/config/supabase_config.dart`
- ✅ Credenciales configuradas
- ⚠️ Pendiente verificar validez

## Conclusión

La aplicación está técnicamente completa y robusta. El problema más probable es que **las tablas no existen en la base de datos Supabase**. Una vez que se verifique y corrija la configuración de la base de datos, la aplicación debería conectarse automáticamente.

La implementación actual garantiza que:
1. Si la BD funciona → Se conecta automáticamente
2. Si la BD falla → Activa modo demo sin problemas  
3. Los logs son claros para diagnosticar problemas
4. La UI es adaptativa y funcional en cualquier dispositivo

**Recomendación**: Verificar el estado de las tablas en Supabase y ejecutar los scripts SQL proporcionados.
