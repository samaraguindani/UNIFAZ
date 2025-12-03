-- =====================================================
-- UNIFAZ - Tabela de Horários de Disponibilidade
-- =====================================================
-- Esta tabela armazena os horários de disponibilidade
-- para cada serviço, permitindo um calendário mais
-- preciso e flexível.
-- =====================================================

CREATE TABLE IF NOT EXISTS public.service_availability (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  service_id UUID REFERENCES public.services(id) ON DELETE CASCADE NOT NULL,
  time_slots JSONB NOT NULL, -- Array de objetos {day_of_week, start_time, end_time}
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(service_id) -- Um serviço tem apenas um schedule
);

-- Índices
CREATE INDEX IF NOT EXISTS service_availability_service_id_idx 
  ON public.service_availability (service_id);

-- Trigger para atualizar updated_at
DROP TRIGGER IF EXISTS update_service_availability_updated_at 
  ON public.service_availability;
CREATE TRIGGER update_service_availability_updated_at 
  BEFORE UPDATE ON public.service_availability
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Políticas RLS
ALTER TABLE public.service_availability ENABLE ROW LEVEL SECURITY;

-- Qualquer um pode visualizar horários de disponibilidade
DROP POLICY IF EXISTS "Anyone can view availability" ON public.service_availability;
CREATE POLICY "Anyone can view availability" ON public.service_availability
  FOR SELECT USING (true);

-- Usuários podem inserir horários para seus próprios serviços
DROP POLICY IF EXISTS "Users can insert own availability" ON public.service_availability;
CREATE POLICY "Users can insert own availability" ON public.service_availability
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.services 
      WHERE services.id = service_availability.service_id 
      AND services.user_id = auth.uid()
    )
  );

-- Usuários podem atualizar horários de seus próprios serviços
DROP POLICY IF EXISTS "Users can update own availability" ON public.service_availability;
CREATE POLICY "Users can update own availability" ON public.service_availability
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.services 
      WHERE services.id = service_availability.service_id 
      AND services.user_id = auth.uid()
    )
  );

-- Usuários podem excluir horários de seus próprios serviços
DROP POLICY IF EXISTS "Users can delete own availability" ON public.service_availability;
CREATE POLICY "Users can delete own availability" ON public.service_availability
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.services 
      WHERE services.id = service_availability.service_id 
      AND services.user_id = auth.uid()
    )
  );






