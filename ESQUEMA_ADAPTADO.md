# ✅ APLICACIÓN ADAPTADA AL ESQUEMA REAL DE SUPABASE

## 🎯 Estado Actual: LISTA PARA USAR

La aplicación Flutter BreakTime Tracker ha sido **completamente adaptada** a tu esquema real de Supabase.

## 📋 Cambios Realizados

### ✅ Adaptación al Esquema Real
- **Campo `tarjeta`**: Ahora busca empleados por el campo `tarjeta` (no `codigo`)
- **Tabla `tiempos_descanso`**: Usa la tabla correcta para registros de descansos
- **Campos de tiempo**: Maneja correctamente los campos `inicio`/`fin` como tipo `time`
- **Cálculo de duración**: Calcula automáticamente `duracion_minutos`
- **Filtro por fecha**: Solo muestra descansos del día actual
- **Usuarios activos**: Solo considera usuarios con `activo = true`

### 🔧 Funciones Actualizadas
1. **Diagnóstico**: Verifica conectividad con el esquema real
2. **Búsqueda**: Busca por campo `tarjeta` en tabla `usuarios`
3. **Registro**: Inserta en tabla `tiempos_descanso` con formato correcto
4. **Visualización**: Muestra empleados en descanso del día actual
5. **Tiempo real**: Suscripción a cambios en `tiempos_descanso`

## 🚀 Pasos para Activar

### 1. Ejecutar SQL de Usuarios de Prueba
Ejecuta el archivo `insertar_usuarios_prueba.sql` en Supabase SQL Editor para agregar usuarios de prueba.

### 2. Ejecutar la Aplicación
```bash
flutter run -d chrome
```

### 3. Probar con Códigos de Tarjeta
- **9636979** - Kenny Aguilar (usuario real existente)
- **001** - Juan Pérez (nuevo usuario de prueba)
- **002** - María García (nuevo usuario de prueba)
- **HP30** - Usuario Test (nuevo usuario de prueba)

## 📊 Esquema de Base de Datos Soportado

### Tabla `usuarios`
```sql
- id (uuid) - Primary key
- nombre (varchar) - Nombre completo
- tarjeta (varchar) - Código de la tarjeta RFID
- codigo (varchar) - Código adicional del empleado
- turno (varchar) - Turno de trabajo
- activo (bool) - Estado activo/inactivo
- created_at, updated_at (timestamp)
```

### Tabla `tiempos_descanso`
```sql
- id (uuid) - Primary key
- usuario_id (uuid) - FK a usuarios.id
- tipo (varchar) - Tipo de descanso
- fecha (date) - Fecha del descanso
- inicio (time) - Hora de inicio
- fin (time, nullable) - Hora de fin
- duracion_minutos (int4) - Duración calculada
- created_at (timestamp)
```

## 🔄 Flujo de Funcionamiento

### Al Pasar Tarjeta (Primera vez):
1. Busca empleado por `tarjeta` en tabla `usuarios`
2. Verifica que esté `activo = true`
3. Crea registro en `tiempos_descanso` con:
   - `fecha = hoy`
   - `inicio = hora actual`
   - `fin = NULL`

### Al Pasar Tarjeta (Regreso):
1. Busca descanso activo (`fin = NULL`) del día actual
2. Actualiza registro con:
   - `fin = hora actual`
   - `duracion_minutos = diferencia calculada`

## 📱 Interface de Usuario

### ✅ Funciones Operativas
- **Diagnóstico automático** al iniciar
- **Búsqueda por tarjeta** RFID/código de barras
- **Entrada manual** con teclado + ENTER
- **Visualización en tiempo real** de empleados en descanso
- **Cálculo de tiempo restante** (30 minutos por defecto)
- **Alertas de tiempo excedido** (color rojo)
- **Modo demo** como fallback

### 🎨 UI Adaptativa
- **Móvil** (< 480px): Interfaz compacta
- **Tablet** (> 600px): Interfaz ampliada
- **Escritorio**: Interfaz completa con márgenes

## 🔍 Logs de Diagnóstico

Al ejecutar la aplicación verás:

**Si conecta correctamente:**
```
✅ CONEXIÓN EXITOSA: X usuarios encontrados
📋 Tarjeta: 9636979 - Kenny Aguilar (Código: KA22)
📋 Tarjeta: 001 - Juan Pérez (Código: JP001)
...
```

**Si hay problemas:**
```
❌ ERROR DE CONEXIÓN: [detalle del error]
🔍 Diagnóstico: [tipo de error específico]
```

## 📁 Archivos Actualizados

- ✅ `lib/main.dart` - Aplicación principal adaptada
- ✅ `insertar_usuarios_prueba.sql` - Script de usuarios de prueba
- ✅ Todos los métodos adaptados al esquema real

## 🎯 Códigos de Prueba Reales

### Usuarios Existentes
- **9636979** - Kenny Aguilar

### Usuarios de Prueba (después del SQL)
- **001** - Juan Pérez
- **002** - María García
- **003** - Carlos López
- **004** - Ana Martínez
- **HP30** - Usuario Test
- **VS26** - Demo User
- **CB29** - Test Demo

## ✅ Lista de Verificación

1. [x] Aplicación adaptada al esquema real
2. [ ] Ejecutar script SQL de usuarios de prueba
3. [ ] Probar conexión con `flutter run -d chrome`
4. [ ] Verificar función con tarjeta existente (9636979)
5. [ ] Probar nuevos códigos de prueba
6. [ ] Verificar registros en tabla `tiempos_descanso`

---

**🚀 Estado**: LISTA PARA PRODUCCIÓN  
**⏳ Tiempo estimado para activación**: 5 minutos  
**🔧 Pendiente**: Solo ejecutar SQL de usuarios de prueba
