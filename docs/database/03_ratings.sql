-- =====================================================
-- UNIFAZ - Tabela de Avaliações
-- =====================================================
-- Esta tabela armazena as avaliações entre usuários,
-- permitindo que prestadores e clientes se avaliem
-- mutuamente.
-- =====================================================

CREATE TABLE IF NOT EXISTS public.ratings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  from_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  to_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  service_id UUID REFERENCES public.services(id) ON DELETE SET NULL,
  request_id UUID REFERENCES public.requests(id) ON DELETE SET NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- Evitar avaliações duplicadas do mesmo usuário para o mesmo serviço/demanda
  UNIQUE(from_user_id, to_user_id, COALESCE(service_id, '00000000-0000-0000-0000-000000000000'::uuid), COALESCE(request_id, '00000000-0000-0000-0000-000000000000'::uuid))
);

-- Índices
CREATE INDEX IF NOT EXISTS ratings_from_user_id_idx ON public.ratings (from_user_id);
CREATE INDEX IF NOT EXISTS ratings_to_user_id_idx ON public.ratings (to_user_id);
CREATE INDEX IF NOT EXISTS ratings_service_id_idx ON public.ratings (service_id);
CREATE INDEX IF NOT EXISTS ratings_request_id_idx ON public.ratings (request_id);
CREATE INDEX IF NOT EXISTS ratings_rating_idx ON public.ratings (rating);

-- Trigger para atualizar updated_at
DROP TRIGGER IF EXISTS update_ratings_updated_at ON public.ratings;
CREATE TRIGGER update_ratings_updated_at 
  BEFORE UPDATE ON public.ratings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Políticas RLS
ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

-- Qualquer um pode visualizar avaliações
DROP POLICY IF EXISTS "Anyone can view ratings" ON public.ratings;
CREATE POLICY "Anyone can view ratings" ON public.ratings
  FOR SELECT USING (true);

-- Usuários podem inserir suas próprias avaliações
DROP POLICY IF EXISTS "Users can insert own ratings" ON public.ratings;
CREATE POLICY "Users can insert own ratings" ON public.ratings
  FOR INSERT WITH CHECK (auth.uid() = from_user_id);

-- Usuários podem atualizar suas próprias avaliações
DROP POLICY IF EXISTS "Users can update own ratings" ON public.ratings;
CREATE POLICY "Users can update own ratings" ON public.ratings
  FOR UPDATE USING (auth.uid() = from_user_id);

-- Usuários podem excluir suas próprias avaliações
DROP POLICY IF EXISTS "Users can delete own ratings" ON public.ratings;
CREATE POLICY "Users can delete own ratings" ON public.ratings
  FOR DELETE USING (auth.uid() = from_user_id);

-- Função para calcular média de avaliações de um usuário
CREATE OR REPLACE FUNCTION get_user_average_rating(user_uuid UUID)
RETURNS NUMERIC AS $$
BEGIN
  RETURN (
    SELECT COALESCE(AVG(rating), 0)
    FROM public.ratings
    WHERE to_user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql;

-- Função para contar total de avaliações de um usuário
CREATE OR REPLACE FUNCTION get_user_total_ratings(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM public.ratings
    WHERE to_user_id = user_uuid
  );
END;
$$ LANGUAGE plpgsql;






