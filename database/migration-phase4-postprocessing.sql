-- Phase 4: Post-processing columns for planche compositing & upscaling

ALTER TABLE ai_planches ADD COLUMN IF NOT EXISTS upscaled_url TEXT;

ALTER TABLE ai_planche_panels ADD COLUMN IF NOT EXISTS upscaled_url TEXT;

-- Allow service role to manage composites in planche-assets
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE policyname = 'Service role all planche-assets'
  ) THEN
    CREATE POLICY "Service role all planche-assets"
      ON storage.objects FOR ALL
      USING (bucket_id = 'planche-assets')
      WITH CHECK (bucket_id = 'planche-assets');
  END IF;
END $$;
