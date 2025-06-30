# BreakTime Tracker - Guía de Configuración Rápida

## Pasos para poner en marcha la aplicación:

### 1. Configurar Supabase

1. Ve a [https://supabase.com](https://supabase.com) y crea una cuenta
2. Crea un nuevo proyecto
3. Ve a Settings > API y copia:
   - Project URL
   - Anon (public) key

### 2. Configurar la aplicación

1. Abre `lib/config/supabase_config.dart`
2. Reemplaza los valores con tus credenciales:
   ```dart
   static const String supabaseUrl = 'TU_URL_AQUI';
   static const String supabaseAnonKey = 'TU_CLAVE_AQUI';
   ```

### 3. Configurar la base de datos

1. En el panel de Supabase, ve a SQL Editor
2. Copia y pega el contenido de `database_setup.sql`
3. Ejecuta el script

### 4. Probar la aplicación

```bash
flutter run
```

## Datos de prueba

Si quieres datos de ejemplo, descomenta las líneas en `database_setup.sql` que empiezan con:
```sql
INSERT INTO employees (name, card_code, department, position) VALUES...
```

## Configuración de hardware

### Lector de tarjetas USB
- La aplicación está configurada para recibir input de teclado
- Conecta tu lector de tarjetas RFID/Código de barras
- Configúralo para enviar el código seguido de ENTER

### Pantalla táctil (opcional)
- La aplicación funciona perfectamente en pantallas táctiles
- Recomendado para kioskos o estaciones fijas

## Solución de problemas comunes

### Error de conexión a Supabase
- Verifica que las credenciales sean correctas
- Asegúrate de que RLS esté configurado correctamente

### Tarjetas no reconocidas
- Verifica que el empleado esté registrado en la tabla `employees`
- Confirma que el `card_code` coincida exactamente

### Problemas de tiempo real
- Verifica que el Realtime esté habilitado en Supabase
- Asegúrate de que las políticas RLS permitan las suscripciones

## Personalización

### Cambiar tiempo de descanso
Modifica en `lib/main.dart`, línea ~186:
```dart
final remaining = const Duration(minutes: 30) - elapsed; // Cambiar 30
```

### Cambiar colores
Modifica los colores en el método `build()` del widget principal.

### Agregar campos a empleados
1. Modifica la tabla `employees` en Supabase
2. Actualiza las consultas en `lib/main.dart`
3. Modifica la UI según sea necesario

---

¿Necesitas ayuda? Revisa el README.md completo o crea un issue en GitHub.
