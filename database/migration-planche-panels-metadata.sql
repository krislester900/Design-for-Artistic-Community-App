ALTER TABLE ai_planche_panels ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

-- Create storage bucket for planche assets (poses, panels)
INSERT INTO storage.buckets (id, name, public, avif_autodetection)
VALUES ('planche-assets', 'planche-assets', TRUE, FALSE)
ON CONFLICT (id) DO NOTHING;

-- Allow public read access to planche-assets
CREATE POLICY IF NOT EXISTS "Public read planche-assets"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'planche-assets');

-- Allow authenticated uploads to planche-assets
CREATE POLICY IF NOT EXISTS "Authenticated upload planche-assets"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'planche-assets'
    AND auth.role() = 'authenticated'
  );
