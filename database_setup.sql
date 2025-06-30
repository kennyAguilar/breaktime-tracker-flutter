-- BreakTime Tracker Database Setup
-- Ejecutar estos comandos en el editor SQL de Supabase

-- 1. Crear tabla de empleados
CREATE TABLE IF NOT EXISTS employees (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name VARCHAR NOT NULL,
  card_code VARCHAR UNIQUE NOT NULL,
  department VARCHAR,
  position VARCHAR,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Crear tabla de registros de descanso
CREATE TABLE IF NOT EXISTS break_records (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  employee_id UUID REFERENCES employees(id) ON DELETE CASCADE,
  check_out_time TIMESTAMP WITH TIME ZONE NOT NULL,
  check_in_time TIMESTAMP WITH TIME ZONE,
  duration_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Crear índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_employees_card_code ON employees(card_code);
CREATE INDEX IF NOT EXISTS idx_break_records_employee_id ON break_records(employee_id);
CREATE INDEX IF NOT EXISTS idx_break_records_check_out_time ON break_records(check_out_time);
CREATE INDEX IF NOT EXISTS idx_break_records_active ON break_records(employee_id) WHERE check_in_time IS NULL;

-- 4. Habilitar Row Level Security (RLS)
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE break_records ENABLE ROW LEVEL SECURITY;

-- 5. Crear políticas de seguridad
-- Políticas para employees
CREATE POLICY "Allow public read access on employees" ON employees FOR SELECT USING (true);
CREATE POLICY "Allow public insert on employees" ON employees FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on employees" ON employees FOR UPDATE USING (true);

-- Políticas para break_records
CREATE POLICY "Allow public read access on break_records" ON break_records FOR SELECT USING (true);
CREATE POLICY "Allow public insert on break_records" ON break_records FOR INSERT WITH CHECK (true);
CREATE POLICY "Allow public update on break_records" ON break_records FOR UPDATE USING (true);

-- 6. Crear función para actualizar timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 7. Crear triggers para actualizar timestamps automáticamente
CREATE TRIGGER update_employees_updated_at 
    BEFORE UPDATE ON employees 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_break_records_updated_at 
    BEFORE UPDATE ON break_records 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 8. Crear función para calcular duración del descanso
CREATE OR REPLACE FUNCTION calculate_break_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.check_in_time IS NOT NULL AND OLD.check_in_time IS NULL THEN
        NEW.duration_minutes = EXTRACT(EPOCH FROM (NEW.check_in_time - NEW.check_out_time)) / 60;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 9. Crear trigger para calcular duración automáticamente
CREATE TRIGGER calculate_break_duration_trigger
    BEFORE UPDATE ON break_records
    FOR EACH ROW
    EXECUTE FUNCTION calculate_break_duration();

-- 10. Insertar datos de ejemplo (opcional)
-- NOTA: Descomentar las siguientes líneas si deseas datos de prueba

/*
INSERT INTO employees (name, card_code, department, position) VALUES 
('Juan Pérez', '001', 'Administración', 'Gerente'),
('María García', '002', 'Ventas', 'Vendedora'),
('Carlos López', '003', 'Producción', 'Operario'),
('Ana Martínez', '004', 'Recursos Humanos', 'Coordinadora'),
('Luis Rodríguez', '005', 'Mantenimiento', 'Técnico');
*/

-- 11. Crear vista para reportes (opcional)
CREATE OR REPLACE VIEW break_summary AS
SELECT 
    e.name AS employee_name,
    e.department,
    br.check_out_time,
    br.check_in_time,
    br.duration_minutes,
    CASE 
        WHEN br.check_in_time IS NULL THEN 'En descanso'
        WHEN br.duration_minutes > 30 THEN 'Excedido'
        ELSE 'Completado'
    END AS status,
    DATE(br.check_out_time) AS break_date
FROM break_records br
JOIN employees e ON br.employee_id = e.id
ORDER BY br.check_out_time DESC;

-- Configuración completada
-- Ahora puedes usar la aplicación Flutter con estas tablas
