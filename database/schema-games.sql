-- Table pour stocker les mini-jeux de la communauté
CREATE TABLE IF NOT EXISTS community_games (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  game_url TEXT NOT NULL, -- URL vers le fichier index.html hébergé (ex: Supabase Storage)
  thumbnail_url TEXT,
  is_featured BOOLEAN DEFAULT false,
  play_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour requêtes rapides
CREATE INDEX idx_community_games_author_id ON community_games(author_id);
CREATE INDEX idx_community_games_created_at ON community_games(created_at DESC);

-- Sécurité : RLS
ALTER TABLE community_games ENABLE ROW LEVEL SECURITY;

-- Tout le monde peut voir les jeux
CREATE POLICY "Anyone can view games"
  ON community_games FOR SELECT
  USING (true);

-- Seuls les utilisateurs connectés peuvent ajouter des jeux
CREATE POLICY "Users can insert own games"
  ON community_games FOR INSERT
  WITH CHECK (auth.uid() = author_id);

-- Seul l'auteur peut modifier son jeu
CREATE POLICY "Users can update own games"
  ON community_games FOR UPDATE
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

-- Seul l'auteur peut supprimer son jeu
CREATE POLICY "Users can delete own games"
  ON community_games FOR DELETE
  USING (auth.uid() = author_id);

-- Incrémentation du compteur de vues (fonction)
CREATE OR REPLACE FUNCTION increment_game_play_count(game_id BIGINT)
RETURNS void
LANGUAGE sql
SECURITY DEFINER
AS $$
  UPDATE community_games
  SET play_count = play_count + 1
  WHERE id = game_id;
$$;
