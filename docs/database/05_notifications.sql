-- =====================================================
-- UNIFAZ - Tabela de Notificações
-- =====================================================
-- Esta tabela armazena as notificações do sistema,
-- incluindo solicitações de agendamento e respostas.
-- =====================================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  from_user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('appointmentRequest', 'appointmentApproved', 'appointmentRejected', 'appointmentCancelled')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  appointment_id UUID REFERENCES public.appointments(id) ON DELETE CASCADE,
  service_id UUID REFERENCES public.services(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  read_at TIMESTAMP WITH TIME ZONE
);

-- Índices
CREATE INDEX IF NOT EXISTS notifications_user_id_idx ON public.notifications (user_id);
CREATE INDEX IF NOT EXISTS notifications_from_user_id_idx ON public.notifications (from_user_id);
CREATE INDEX IF NOT EXISTS notifications_appointment_id_idx ON public.notifications (appointment_id);
CREATE INDEX IF NOT EXISTS notifications_service_id_idx ON public.notifications (service_id);
CREATE INDEX IF NOT EXISTS notifications_is_read_idx ON public.notifications (is_read);
CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON public.notifications (created_at DESC);

-- Trigger para atualizar updated_at (se necessário)
-- Notificações não têm updated_at, apenas created_at e read_at

-- Políticas RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Usuários podem visualizar suas próprias notificações
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

-- Sistema pode inserir notificações (qualquer usuário pode criar notificação para outro)
DROP POLICY IF EXISTS "Anyone can create notifications" ON public.notifications;
CREATE POLICY "Anyone can create notifications" ON public.notifications
  FOR INSERT WITH CHECK (true);

-- Usuários podem atualizar suas próprias notificações (marcar como lida)
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

-- Usuários podem excluir suas próprias notificações
DROP POLICY IF EXISTS "Users can delete own notifications" ON public.notifications;
CREATE POLICY "Users can delete own notifications" ON public.notifications
  FOR DELETE USING (auth.uid() = user_id);

-- Função para contar notificações não lidas
CREATE OR REPLACE FUNCTION get_unread_notifications_count(user_uuid UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM public.notifications
    WHERE user_id = user_uuid
      AND is_read = FALSE
  );
END;
$$ LANGUAGE plpgsql;






