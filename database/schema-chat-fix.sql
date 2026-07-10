-- ============================================================
-- Artéïa - Migration de rattrapage chat
-- Ajoute les tables/colonnes/buckets manquants référencés
-- par le frontend mais absents des migrations SQL
-- ============================================================

-- ============================================================
-- 1. TABLE : chat_message_reactions
-- ============================================================
CREATE TABLE IF NOT EXISTS public.chat_message_reactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id uuid NOT NULL REFERENCES public.chat_messages(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  emoji text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (message_id, user_id, emoji)
);

ALTER TABLE public.chat_message_reactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members read reactions" ON public.chat_message_reactions;
CREATE POLICY "Members read reactions" ON public.chat_message_reactions FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chat_channel_members cm
    JOIN public.chat_messages m ON m.channel_id = cm.channel_id
    WHERE m.id = message_id AND cm.user_id = auth.uid())
);

DROP POLICY IF EXISTS "Authenticated users add reactions" ON public.chat_message_reactions;
CREATE POLICY "Authenticated users add reactions" ON public.chat_message_reactions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users delete own reactions" ON public.chat_message_reactions;
CREATE POLICY "Users delete own reactions" ON public.chat_message_reactions FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================
-- 2. TABLE : typing_indicators
-- ============================================================
CREATE TABLE IF NOT EXISTS public.typing_indicators (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  channel_id uuid NOT NULL REFERENCES public.chat_channels(id) ON DELETE CASCADE,
  started_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, channel_id)
);

ALTER TABLE public.typing_indicators ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members read typing indicators" ON public.typing_indicators;
CREATE POLICY "Members read typing indicators" ON public.typing_indicators FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chat_channel_members WHERE channel_id = typing_indicators.channel_id AND user_id = auth.uid())
);

DROP POLICY IF EXISTS "Members upsert own typing" ON public.typing_indicators;
CREATE POLICY "Members upsert own typing" ON public.typing_indicators FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Members update own typing" ON public.typing_indicators;
CREATE POLICY "Members update own typing" ON public.typing_indicators FOR UPDATE TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Members delete own typing" ON public.typing_indicators;
CREATE POLICY "Members delete own typing" ON public.typing_indicators FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================
-- 3. COLONNES MANQUANTES SUR chat_messages
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'chat_messages' AND column_name = 'message_type') THEN
    ALTER TABLE public.chat_messages ADD COLUMN message_type text NOT NULL DEFAULT 'text';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'chat_messages' AND column_name = 'voice_url') THEN
    ALTER TABLE public.chat_messages ADD COLUMN voice_url text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'chat_messages' AND column_name = 'voice_duration') THEN
    ALTER TABLE public.chat_messages ADD COLUMN voice_duration integer;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'chat_messages' AND column_name = 'sticker_id') THEN
    ALTER TABLE public.chat_messages ADD COLUMN sticker_id text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'chat_messages' AND column_name = 'is_pinned') THEN
    ALTER TABLE public.chat_messages ADD COLUMN is_pinned boolean NOT NULL DEFAULT false;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'chat_messages' AND column_name = 'is_read') THEN
    ALTER TABLE public.chat_messages ADD COLUMN is_read boolean NOT NULL DEFAULT false;
  END IF;
END $$;

-- ============================================================
-- 4. STORAGE BUCKET : chat-attachments
-- ============================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat-attachments',
  'chat-attachments',
  true,
  52428800, -- 50 MB max per file
  NULL       -- tous les types MIME autorisés
)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public read chat attachments" ON storage.objects;
CREATE POLICY "Public read chat attachments" ON storage.objects
  FOR SELECT USING (bucket_id = 'chat-attachments');

DROP POLICY IF EXISTS "Auth upload chat attachments" ON storage.objects;
CREATE POLICY "Auth upload chat attachments" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (
    bucket_id = 'chat-attachments' AND auth.role() = 'authenticated'
  );

DROP POLICY IF EXISTS "Users delete own chat attachments" ON storage.objects;
CREATE POLICY "Users delete own chat attachments" ON storage.objects
  FOR DELETE TO authenticated USING (
    bucket_id = 'chat-attachments' AND auth.uid() = owner
  );

-- ============================================================
-- 5. POLITIQUES RLS MANQUANTES : user_relationships
-- ============================================================
DROP POLICY IF EXISTS "Users update own relationships" ON public.user_relationships;
CREATE POLICY "Users update own relationships" ON public.user_relationships FOR UPDATE TO authenticated
  USING (auth.uid() = requester_id OR auth.uid() = target_id)
  WITH CHECK (auth.uid() = requester_id OR auth.uid() = target_id);

DROP POLICY IF EXISTS "Users delete own relationships" ON public.user_relationships;
CREATE POLICY "Users delete own relationships" ON public.user_relationships FOR DELETE TO authenticated
  USING (auth.uid() = requester_id OR auth.uid() = target_id);

-- ============================================================
-- 6. MIGRATION NOTIFICATIONS : Schema A → Schema B
--    Ajoute les colonnes manquantes à la table notifications
--    pour correspondre à ce que le frontend attend
-- ============================================================
DO $$
BEGIN
  -- actor_id (remplace from_user_id)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'actor_id') THEN
    ALTER TABLE public.notifications ADD COLUMN actor_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
  -- title (nouveau champ)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'title') THEN
    ALTER TABLE public.notifications ADD COLUMN title text NOT NULL DEFAULT '';
  END IF;
  -- body (remplace message)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'body') THEN
    ALTER TABLE public.notifications ADD COLUMN body text NOT NULL DEFAULT '';
  END IF;
  -- link
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'link') THEN
    ALTER TABLE public.notifications ADD COLUMN link text;
  END IF;
  -- is_read (remplace read)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'is_read') THEN
    ALTER TABLE public.notifications ADD COLUMN is_read boolean NOT NULL DEFAULT false;
  END IF;
END $$;

-- ============================================================
-- 6. Ajout du type 'self' dans channel_type (notes personnelles)
-- ============================================================
ALTER TYPE public.channel_type ADD VALUE IF NOT EXISTS 'self';
