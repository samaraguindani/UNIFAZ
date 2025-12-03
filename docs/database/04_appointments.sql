-- =====================================================
-- UNIFAZ - Tabela de Agendamentos
-- =====================================================
-- Esta tabela armazena os agendamentos feitos pelos
-- clientes para os serviços dos prestadores.
-- =====================================================

CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
  client_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  provider_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  appointment_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  notes TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS appointments_service_id_idx ON public.appointments (service_id);
CREATE INDEX IF NOT EXISTS appointments_client_id_idx ON public.appointments (client_id);
CREATE INDEX IF NOT EXISTS appointments_provider_id_idx ON public.appointments (provider_id);
CREATE INDEX IF NOT EXISTS appointments_appointment_date_idx ON public.appointments (appointment_date);
CREATE INDEX IF NOT EXISTS appointments_status_idx ON public.appointments (status);
CREATE INDEX IF NOT EXISTS appointments_date_time_idx ON public.appointments (appointment_date, start_time, end_time);

-- Trigger para atualizar updated_at
DROP TRIGGER IF EXISTS update_appointments_updated_at ON public.appointments;
CREATE TRIGGER update_appointments_updated_at 
  BEFORE UPDATE ON public.appointments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Políticas RLS
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- Qualquer um pode visualizar agendamentos (para verificar disponibilidade)
DROP POLICY IF EXISTS "Anyone can view appointments" ON public.appointments;
CREATE POLICY "Anyone can view appointments" ON public.appointments
  FOR SELECT USING (true);

-- Clientes podem inserir seus próprios agendamentos
DROP POLICY IF EXISTS "Clients can insert own appointments" ON public.appointments;
CREATE POLICY "Clients can insert own appointments" ON public.appointments
  FOR INSERT WITH CHECK (auth.uid() = client_id);

-- Clientes podem atualizar seus próprios agendamentos
DROP POLICY IF EXISTS "Clients can update own appointments" ON public.appointments;
CREATE POLICY "Clients can update own appointments" ON public.appointments
  FOR UPDATE USING (auth.uid() = client_id);

-- Prestadores podem atualizar agendamentos de seus serviços
DROP POLICY IF EXISTS "Providers can update service appointments" ON public.appointments;
CREATE POLICY "Providers can update service appointments" ON public.appointments
  FOR UPDATE USING (auth.uid() = provider_id);

-- Clientes podem excluir seus próprios agendamentos
DROP POLICY IF EXISTS "Clients can delete own appointments" ON public.appointments;
CREATE POLICY "Clients can delete own appointments" ON public.appointments
  FOR DELETE USING (auth.uid() = client_id);

-- Prestadores podem excluir agendamentos de seus serviços
DROP POLICY IF EXISTS "Providers can delete service appointments" ON public.appointments;
CREATE POLICY "Providers can delete service appointments" ON public.appointments
  FOR DELETE USING (auth.uid() = provider_id);

-- Função para verificar conflitos de horário
CREATE OR REPLACE FUNCTION check_appointment_conflict(
  p_service_id UUID,
  p_appointment_date DATE,
  p_start_time TIME,
  p_end_time TIME,
  p_exclude_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.appointments
    WHERE service_id = p_service_id
      AND appointment_date = p_appointment_date
      AND status NOT IN ('cancelled', 'completed')
      AND (id != p_exclude_id OR p_exclude_id IS NULL)
      AND (
        (start_time < p_end_time AND end_time > p_start_time)
      )
  );
END;
$$ LANGUAGE plpgsql;






