-- Script SQL para insertar usuarios de prueba en tu base de datos
-- Ejecutar en Supabase SQL Editor

-- Insertar usuarios de prueba compatibles con la aplicación Flutter
INSERT INTO usuarios (nombre, tarjeta, codigo, turno, activo) VALUES
('Juan Pérez', '001', 'JP001', 'Matutino', true),
('María García', '002', 'MG002', 'Matutino', true),
('Carlos López', '003', 'CL003', 'Vespertino', true),
('Ana Martínez', '004', 'AM004', 'Vespertino', true),
('Usuario Test', 'HP30', 'UT30', 'Matutino', true),
('Demo User', 'VS26', 'DU26', 'Vespertino', true),
('Test Demo', 'CB29', 'TD29', 'Matutino', true)
ON CONFLICT (tarjeta) DO NOTHING;

-- Verificar que se insertaron correctamente
SELECT 
    nombre, 
    tarjeta, 
    codigo, 
    turno, 
    activo,
    created_at
FROM usuarios 
WHERE activo = true 
ORDER BY created_at DESC;

-- Opcional: Limpiar registros de descansos anteriores para pruebas
-- DELETE FROM tiempos_descanso WHERE fecha = CURRENT_DATE;

-- Verificar estructura de tablas
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('usuarios', 'tiempos_descanso', 'descansos')
ORDER BY table_name, ordinal_position;
