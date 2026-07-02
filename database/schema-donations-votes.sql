-- ==========================================================
-- Schéma : Dons & Votes pour Artéïa
-- ==========================================================

-- ==================== DONS ====================

-- Table des dons
CREATE TABLE IF NOT EXISTS donations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  fee DECIMAL(10,2) NOT NULL DEFAULT 0,
  net_amount DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'EUR',
  message TEXT,
  payment_method TEXT NOT NULL DEFAULT 'stripe',
  stripe_payment_intent_id TEXT,
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Index pour les dons
CREATE INDEX IF NOT EXISTS idx_donations_sender ON donations(sender_id);
CREATE INDEX IF NOT EXISTS idx_donations_recipient ON donations(recipient_id);
CREATE INDEX IF NOT EXISTS idx_donations_status ON donations(status);
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON donations(created_at DESC);

-- Table du solde des artistes
CREATE TABLE IF NOT EXISTS artist_balances (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  total_earned DECIMAL(12,2) NOT NULL DEFAULT 0,
  total_withdrawn DECIMAL(12,2) NOT NULL DEFAULT 0,
  current_balance DECIMAL(12,2) NOT NULL DEFAULT 0,
  pending_balance DECIMAL(12,2) NOT NULL DEFAULT 0,
  last_payout_date TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table des retraits
CREATE TABLE IF NOT EXISTS payout_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  fee DECIMAL(10,2) NOT NULL DEFAULT 0,
  net_amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'bank_transfer',
  account_info JSONB,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'rejected')),
  admin_note TEXT,
  requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  processed_by UUID REFERENCES profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_payouts_user ON payout_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON payout_requests(status);

-- ==================== VOTES ====================

-- Table des compétitions (élections par catégorie)
CREATE TABLE IF NOT EXISTS competitions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
  category_name TEXT NOT NULL,
  cover_image_url TEXT,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'active', 'closed', 'cancelled')),
  max_votes_per_user INT NOT NULL DEFAULT 3,
  winner_id UUID REFERENCES posts(id) ON DELETE SET NULL,
  winner_title TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES profiles(id),
  CHECK (end_date > start_date)
);

CREATE INDEX IF NOT EXISTS idx_competitions_category ON competitions(category_id);
CREATE INDEX IF NOT EXISTS idx_competitions_status ON competitions(status);
CREATE INDEX IF NOT EXISTS idx_competitions_dates ON competitions(start_date, end_date);

-- Table des inscriptions aux compétitions
CREATE TABLE IF NOT EXISTS competition_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  vote_count INT NOT NULL DEFAULT 0,
  rank INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(competition_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_entries_competition ON competition_entries(competition_id);
CREATE INDEX IF NOT EXISTS idx_entries_user ON competition_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_entries_votes ON competition_entries(vote_count DESC);

-- Table des votes
CREATE TABLE IF NOT EXISTS votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  entry_id UUID NOT NULL REFERENCES competition_entries(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(competition_id, voter_id, entry_id)
);

CREATE INDEX IF NOT EXISTS idx_votes_competition ON votes(competition_id);
CREATE INDEX IF NOT EXISTS idx_votes_voter ON votes(voter_id);
CREATE INDEX IF NOT EXISTS idx_votes_entry ON votes(entry_id);
CREATE INDEX IF NOT EXISTS idx_votes_post ON votes(post_id);

-- Table des prix pour les gagnants
CREATE TABLE IF NOT EXISTS competition_prizes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id UUID NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  rank INT NOT NULL CHECK (rank > 0),
  title TEXT NOT NULL,
  description TEXT,
  badge_icon TEXT,
  badge_color TEXT,
  prize_amount DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_prizes_competition ON competition_prizes(competition_id);

-- ==================== POLICIES RLS ====================

ALTER TABLE donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE artist_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE competitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE competition_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE competition_prizes ENABLE ROW LEVEL SECURITY;

-- Dons : visible par l'expéditeur et le destinataire
CREATE POLICY "donations_select_own" ON donations FOR SELECT
  USING (sender_id = auth.uid() OR recipient_id = auth.uid());

CREATE POLICY "donations_insert" ON donations FOR INSERT
  WITH CHECK (sender_id = auth.uid());

-- Solde artiste : visible seulement par l'artiste
CREATE POLICY "artist_balances_select_own" ON artist_balances FOR SELECT
  USING (user_id = auth.uid());

-- Retraits : visible par l'utilisateur et l'admin
CREATE POLICY "payouts_select_own" ON payout_requests FOR SELECT
  USING (user_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "payouts_insert" ON payout_requests FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Compétitions : tout le monde peut voir
CREATE POLICY "competitions_select" ON competitions FOR SELECT
  USING (true);

CREATE POLICY "competitions_insert_admin" ON competitions FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "competitions_update_admin" ON competitions FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- Inscriptions : visible par tout le monde, inscrit par le propriétaire
CREATE POLICY "entries_select" ON competition_entries FOR SELECT USING (true);

CREATE POLICY "entries_insert" ON competition_entries FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Votes
CREATE POLICY "votes_select" ON votes FOR SELECT USING (true);

CREATE POLICY "votes_insert" ON votes FOR INSERT
  WITH CHECK (voter_id = auth.uid());

-- Prix : visible par tout le monde
CREATE POLICY "prizes_select" ON competition_prizes FOR SELECT USING (true);

-- ==================== FONCTIONS ====================

-- Calculer les frais de donation (4.44% ≈ 5% pour simplification)
CREATE OR REPLACE FUNCTION calculate_donation_fee(amount DECIMAL)
RETURNS DECIMAL AS $$
BEGIN
  RETURN ROUND(amount * 0.05, 2); -- 5% de frais de plateforme
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Fonction pour créer un don et mettre à jour le solde
CREATE OR REPLACE FUNCTION process_donation(
  p_sender_id UUID,
  p_recipient_id UUID,
  p_amount DECIMAL,
  p_message TEXT DEFAULT NULL,
  p_payment_method TEXT DEFAULT 'stripe',
  p_payment_intent_id TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_fee DECIMAL;
  v_net_amount DECIMAL;
  v_donation_id UUID;
BEGIN
  -- Calculer les frais
  v_fee := calculate_donation_fee(p_amount);
  v_net_amount := p_amount - v_fee;

  -- Créer le don
  INSERT INTO donations (
    sender_id, recipient_id, amount, fee, net_amount,
    message, payment_method, stripe_payment_intent_id, status, completed_at
  ) VALUES (
    p_sender_id, p_recipient_id, p_amount, v_fee, v_net_amount,
    p_message, p_payment_method, p_payment_intent_id, 'completed', NOW()
  ) RETURNING id INTO v_donation_id;

  -- Mettre à jour ou créer le solde de l'artiste
  INSERT INTO artist_balances (user_id, total_earned, current_balance, pending_balance, updated_at)
  VALUES (p_recipient_id, v_net_amount, v_net_amount, 0, NOW())
  ON CONFLICT (user_id) DO UPDATE SET
    total_earned = artist_balances.total_earned + v_net_amount,
    current_balance = artist_balances.current_balance + v_net_amount,
    updated_at = NOW();

  RETURN v_donation_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour voter
CREATE OR REPLACE FUNCTION cast_vote(
  p_competition_id UUID,
  p_entry_id UUID,
  p_voter_id UUID,
  p_post_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_max_votes INT;
  v_current_votes INT;
  v_competition_status TEXT;
BEGIN
  -- Vérifier que la compétition est active
  SELECT status, max_votes_per_user INTO v_competition_status, v_max_votes
  FROM competitions WHERE id = p_competition_id;

  IF v_competition_status != 'active' THEN
    RAISE EXCEPTION 'Cette compétition n''est pas active';
  END IF;

  -- Compter les votes déjà émis par cet utilisateur
  SELECT COUNT(*) INTO v_current_votes
  FROM votes WHERE competition_id = p_competition_id AND voter_id = p_voter_id;

  IF v_current_votes >= v_max_votes THEN
    RAISE EXCEPTION 'Vous avez déjà utilisé tous vos votes (%)', v_max_votes;
  END IF;

  -- Ajouter le vote
  INSERT INTO votes (competition_id, entry_id, voter_id, post_id)
  VALUES (p_competition_id, p_entry_id, p_voter_id, p_post_id);

  -- Incrémenter le compteur de votes
  UPDATE competition_entries
  SET vote_count = vote_count + 1
  WHERE id = p_entry_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour clôturer une compétition et déterminer le gagnant
CREATE OR REPLACE FUNCTION close_competition(p_competition_id UUID)
RETURNS UUID AS $$
DECLARE
  v_winner_id UUID;
  v_winner_title TEXT;
BEGIN
  -- Trouver le gagnant (celui avec le plus de votes)
  SELECT post_id, title INTO v_winner_id, v_winner_title
  FROM competition_entries
  WHERE competition_id = p_competition_id
  ORDER BY vote_count DESC
  LIMIT 1;

  -- Mettre à jour la compétition
  UPDATE competitions
  SET status = 'closed',
      winner_id = v_winner_id,
      winner_title = v_winner_title
  WHERE id = p_competition_id;

  -- Mettre à jour les rangs
  UPDATE competition_entries
  SET rank = subquery.rank
  FROM (
    SELECT id, ROW_NUMBER() OVER (ORDER BY vote_count DESC) as rank
    FROM competition_entries
    WHERE competition_id = p_competition_id
  ) subquery
  WHERE competition_entries.id = subquery.id;

  RETURN v_winner_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================== TRIGGERS ====================

-- Mettre à jour le compteur de dons sur le profil
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_donations_received DECIMAL(12,2) NOT NULL DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS donation_count INT NOT NULL DEFAULT 0;

CREATE OR REPLACE FUNCTION update_profile_donation_stats()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET total_donations_received = total_donations_received + NEW.net_amount,
      donation_count = donation_count + 1
  WHERE id = NEW.recipient_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_donation_stats
  AFTER INSERT ON donations
  FOR EACH ROW
  WHEN (NEW.status = 'completed')
  EXECUTE FUNCTION update_profile_donation_stats();