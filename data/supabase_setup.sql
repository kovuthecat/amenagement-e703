-- =============================================================
-- SETUP SUPABASE — Agencement E703
-- À exécuter une seule fois dans le SQL Editor du dashboard
-- https://btzceyixpzyiumvygykq.supabase.co
-- =============================================================

-- 1. TABLE ÉTAT (une seule ligne partagée, clé fixe 'e703')
-- ---------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_state (
  id            text        PRIMARY KEY DEFAULT 'e703',
  state         jsonb       NOT NULL,
  last_modified timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.app_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon read"
  ON public.app_state FOR SELECT TO anon
  USING (id = 'e703');

CREATE POLICY "anon insert"
  ON public.app_state FOR INSERT TO anon
  WITH CHECK (id = 'e703');

CREATE POLICY "anon update"
  ON public.app_state FOR UPDATE TO anon
  USING (id = 'e703') WITH CHECK (id = 'e703');


-- 2. TRIGGER updated_at (détection de sync multi-terminaux)
-- ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  new.updated_at = now();
  RETURN new;
END;
$$;

CREATE TRIGGER trg_app_state_touch
  BEFORE UPDATE ON public.app_state
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


-- 3. BUCKET STORAGE (images d'inspiration + plans)
-- ---------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('e703-images', 'e703-images', true)
ON CONFLICT (id) DO NOTHING;


-- 4. POLICIES STORAGE — rôle anon peut uploader et supprimer
-- ---------------------------------------------------------------
CREATE POLICY "anon images insert"
  ON storage.objects FOR INSERT TO anon
  WITH CHECK (bucket_id = 'e703-images');

CREATE POLICY "anon images delete"
  ON storage.objects FOR DELETE TO anon
  USING (bucket_id = 'e703-images');

-- Lecture publique : couverte automatiquement par le bucket public.
-- Aucune policy SELECT nécessaire pour storage.objects sur un bucket public.
