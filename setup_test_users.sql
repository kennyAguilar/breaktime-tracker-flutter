-- Script para insertar usuarios de prueba adicionales
-- Ejecutar en el SQL Editor de Supabase

-- Verificar usuarios existentes
SELECT id, usuario, clave, nombre, activo FROM usuarios;

-- Insertar usuarios de prueba adicionales (solo si no existen)
INSERT INTO usuarios (usuario, clave, nombre, activo) VALUES
('juan.perez', '001', 'Juan Pérez', true),
('maria.garcia', '002', 'María García', true),
('carlos.lopez', '003', 'Carlos López', true),
('ana.martinez', '004', 'Ana Martínez', true),
('demo.user', 'VS26', 'Demo User', true),
('test.demo', 'CB29', 'Test Demo', true)
ON CONFLICT (clave) DO NOTHING;

-- Verificar que se insertaron correctamente
SELECT id, usuario, clave, nombre, activo FROM usuarios WHERE activo = true;

-- Verificar estructura de tabla descansos
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'descansos' 
ORDER BY ordinal_position;
