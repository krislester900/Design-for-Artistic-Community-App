-- Table pour les pistes audio du studio de musique
CREATE TABLE IF NOT EXISTS music_tracks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL DEFAULT 'Ma piste',
  audio_url TEXT NOT NULL,
  duration INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_music_tracks_user_id ON music_tracks(user_id);
CREATE INDEX IF NOT EXISTS idx_music_tracks_created_at ON music_tracks(created_at DESC);

-- RLS (Row Level Security)
ALTER TABLE music_tracks ENABLE ROW LEVEL SECURITY;

-- Policy: Les utilisateurs peuvent voir leurs propres pistes
CREATE POLICY "Users can view own tracks" ON music_tracks
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent créer leurs propres pistes
CREATE POLICY "Users can create own tracks" ON music_tracks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent modifier leurs propres pistes
CREATE POLICY "Users can update own tracks" ON music_tracks
  FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Les utilisateurs peuvent supprimer leurs propres pistes
CREATE POLICY "Users can delete own tracks" ON music_tracks
  FOR DELETE USING (auth.uid() = user_id);

-- Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_music_tracks_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_music_tracks_updated_at
  BEFORE UPDATE ON music_tracks
  FOR EACH ROW
  EXECUTE FUNCTION update_music_tracks_updated_at();