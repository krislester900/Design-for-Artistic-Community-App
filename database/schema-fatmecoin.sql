-- ==========================================================
-- Schéma : Système Fatmécoin (FC) - Monnaie virtuelle Artéïa
-- 1 Fatmécoin = 1€
-- ==========================================================

-- ==================== WALLETS ====================

-- Portefeuille Fatmécoin pour chaque utilisateur
CREATE TABLE IF NOT EXISTS fatmecoin_wallets (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  balance DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
  lifetime_earned DECIMAL(12,2) NOT NULL DEFAULT 0,
  lifetime_spent DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Transactions Fatmécoin
CREATE TABLE IF NOT EXISTS fatmecoin_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN (
    'deposit',        -- Rechargement par carte/PayPal/Wave
    'withdrawal',     -- Retrait vers compte bancaire
    'donation_sent',  -- Don envoyé à un artiste
    'donation_received', -- Don reçu d'un fan
    'purchase',       -- Achat sur la plateforme
    'refund',         -- Remboursement
    'bonus',          -- Bonus / Récompense
    'commission'      -- Commission plateforme prélevée
  )),
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  fee DECIMAL(10,2) NOT NULL DEFAULT 0,
  net_amount DECIMAL(10,2) NOT NULL,
  balance_before DECIMAL(12,2) NOT NULL,
  balance_after DECIMAL(12,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'FC',
  description TEXT,
  reference_id UUID,           -- ID de la donation/purchase associée
  reference_type TEXT,         -- 'donation', 'purchase', 'deposit'
  payment_provider TEXT,       -- 'stripe', 'paypal', 'wave', 'djamo', 'bank'
  payment_provider_tx_id TEXT, -- ID de transaction chez le fournisseur
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_fc_tx_user ON fatmecoin_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_fc_tx_type ON fatmecoin_transactions(type);
CREATE INDEX IF NOT EXISTS idx_fc_tx_status ON fatmecoin_transactions(status);
CREATE INDEX IF NOT EXISTS idx_fc_tx_created ON fatmecoin_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_fc_tx_provider ON fatmecoin_transactions(payment_provider);

-- ==================== PRODUITS D'ACHAT ====================

-- Packs de Fatmécoins disponibles à l'achat
CREATE TABLE IF NOT EXISTS fatmecoin_packs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  fc_amount DECIMAL(10,2) NOT NULL CHECK (fc_amount > 0),
  price_eur DECIMAL(10,2) NOT NULL CHECK (price_eur > 0),
  bonus_fc DECIMAL(10,2) NOT NULL DEFAULT 0, -- FC bonus offerts
  is_popular BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Packs par défaut
INSERT INTO fatmecoin_packs (name, description, fc_amount, price_eur, bonus_fc, is_popular, sort_order) VALUES
  ('Découverte', 'Commencez doucement', 5, 5, 0, false, 1),
  ('Petit pack', 'Pour un petit soutien', 10, 10, 1, false, 2),
  ('Pack populaire', 'Le plus choisi !', 20, 20, 3, true, 3),
  ('Grand pack', 'Pour les généreux', 50, 50, 8, false, 4),
  ('Pack premium', 'Pour les vrais mécènes', 100, 100, 20, false, 5)
ON CONFLICT DO NOTHING;

-- ==================== FOURNISSEURS DE PAIEMENT ====================

-- Configuration des fournisseurs de paiement
CREATE TABLE IF NOT EXISTS payment_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,          -- 'stripe', 'paypal', 'wave', 'djamo'
  display_name TEXT NOT NULL,
  icon TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  fee_percentage DECIMAL(5,2) NOT NULL DEFAULT 0, -- Frais additionnels
  min_amount DECIMAL(10,2) NOT NULL DEFAULT 1,
  max_amount DECIMAL(10,2) NOT NULL DEFAULT 1000,
  countries TEXT[],                   -- Pays supportés
  currencies TEXT[] NOT NULL DEFAULT '{EUR}',
  config JSONB,                      -- Configuration spécifique (clés API, etc.)
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Fournisseurs par défaut
INSERT INTO payment_providers (name, display_name, icon, fee_percentage, min_amount, max_amount, countries, currencies, sort_order) VALUES
  ('stripe', 'Carte bancaire (Visa/MC)', 'credit_card', 0, 1, 1000, '{FR,BE,CH,CA,US,UK,DE,ES,IT,NL,PT}', '{EUR,USD,GBP}', 1),
  ('paypal', 'PayPal', 'paypal', 0, 1, 500, '{FR,BE,CH,CA,US,UK,DE,ES,IT,NL,PT}', '{EUR,USD,GBP}', 2),
  ('wave', 'Wave', 'wave', 0, 0.5, 200, '{CI,SN,ML,BF,NE,BJ,TG}', '{XOF}', 3),
  ('djamo', 'Djamo', 'djamo', 0, 0.5, 200, '{CI,SN,ML,BF}', '{XOF}', 4)
ON CONFLICT (name) DO NOTHING;

-- ==================== CONVERSION ====================

-- Historique des taux de conversion FC → devise
CREATE TABLE IF NOT EXISTS conversion_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_currency TEXT NOT NULL DEFAULT 'FC',
  to_currency TEXT NOT NULL,
  rate DECIMAL(10,6) NOT NULL, -- 1 FC = X devise
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Taux par défaut (1 FC = 1€ toujours)
INSERT INTO conversion_rates (from_currency, to_currency, rate) VALUES
  ('FC', 'EUR', 1.0),
  ('FC', 'USD', 1.08),
  ('FC', 'GBP', 0.86),
  ('FC', 'XOF', 655.96)
ON CONFLICT DO NOTHING;

-- ==================== POLICIES RLS ====================

ALTER TABLE fatmecoin_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE fatmecoin_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE fatmecoin_packs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversion_rates ENABLE ROW LEVEL SECURITY;

-- Wallet : visible seulement par le propriétaire
CREATE POLICY "fc_wallet_select_own" ON fatmecoin_wallets FOR SELECT
  USING (user_id = auth.uid());

-- Transactions : visible par le propriétaire
CREATE POLICY "fc_tx_select_own" ON fatmecoin_transactions FOR SELECT
  USING (user_id = auth.uid() OR reference_id IN (SELECT id FROM donations WHERE sender_id = auth.uid() OR recipient_id = auth.uid()));

-- Packs : visible par tout le monde
CREATE POLICY "fc_packs_select" ON fatmecoin_packs FOR SELECT USING (true);

-- Fournisseurs : visible par tout le monde
CREATE POLICY "providers_select" ON payment_providers FOR SELECT USING (true);

-- Taux : visible par tout le monde
CREATE POLICY "rates_select" ON conversion_rates FOR SELECT USING (true);

-- ==================== FONCTIONS ====================

-- Créer un wallet pour un nouvel utilisateur
CREATE OR REPLACE FUNCTION create_fatmecoin_wallet()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO fatmecoin_wallets (user_id, balance, lifetime_earned, lifetime_spent)
  VALUES (NEW.id, 0, 0, 0);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_create_wallet_on_signup
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION create_fatmecoin_wallet();

-- Recharger le wallet (dépôt)
CREATE OR REPLACE FUNCTION deposit_fatmecoins(
  p_user_id UUID,
  p_amount DECIMAL,
  p_provider TEXT DEFAULT 'stripe',
  p_provider_tx_id TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_balance_before DECIMAL;
  v_balance_after DECIMAL;
  v_tx_id UUID;
BEGIN
  -- Récupérer le solde actuel
  SELECT balance INTO v_balance_before
  FROM fatmecoin_wallets WHERE user_id = p_user_id;

  IF v_balance_before IS NULL THEN
    RAISE EXCEPTION 'Wallet non trouvé pour cet utilisateur';
  END IF;

  v_balance_after := v_balance_before + p_amount;

  -- Créer la transaction
  INSERT INTO fatmecoin_transactions (
    user_id, type, amount, fee, net_amount,
    balance_before, balance_after,
    description, payment_provider, payment_provider_tx_id,
    status, completed_at
  ) VALUES (
    p_user_id, 'deposit', p_amount, 0, p_amount,
    v_balance_before, v_balance_after,
    COALESCE(p_description, 'Rechargement Fatmécoins'),
    p_provider, p_provider_tx_id,
    'completed', NOW()
  ) RETURNING id INTO v_tx_id;

  -- Mettre à jour le solde
  UPDATE fatmecoin_wallets
  SET balance = v_balance_after,
      lifetime_earned = lifetime_earned + p_amount,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  RETURN v_tx_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Envoyer des Fatmécoins (don)
CREATE OR REPLACE FUNCTION send_fatmecoins(
  p_sender_id UUID,
  p_recipient_id UUID,
  p_amount DECIMAL,
  p_donation_id UUID DEFAULT NULL,
  p_description TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_sender_balance DECIMAL;
  v_recipient_balance DECIMAL;
  v_fee DECIMAL;
  v_net_amount DECIMAL;
BEGIN
  -- Vérifier le solde de l'expéditeur
  SELECT balance INTO v_sender_balance
  FROM fatmecoin_wallets WHERE user_id = p_sender_id;

  IF v_sender_balance IS NULL OR v_sender_balance < p_amount THEN
    RAISE EXCEPTION 'Solde Fatmécoins insuffisant';
  END IF;

  -- Calculer les frais (5%)
  v_fee := ROUND(p_amount * 0.05, 2);
  v_net_amount := p_amount - v_fee;

  -- Nouveaux soldes
  v_sender_balance := v_sender_balance - p_amount;
  SELECT balance INTO v_recipient_balance
  FROM fatmecoin_wallets WHERE user_id = p_recipient_id;

  IF v_recipient_balance IS NULL THEN
    -- Créer automatiquement un wallet pour le destinataire
    INSERT INTO fatmecoin_wallets (user_id, balance) VALUES (p_recipient_id, 0);
    v_recipient_balance := 0;
  END IF;
  v_recipient_balance := v_recipient_balance + v_net_amount;

  -- Transaction expéditeur
  INSERT INTO fatmecoin_transactions (
    user_id, type, amount, fee, net_amount,
    balance_before, balance_after,
    description, reference_id, reference_type,
    status, completed_at
  ) VALUES (
    p_sender_id, 'donation_sent', p_amount, v_fee, v_net_amount,
    v_sender_balance + p_amount, v_sender_balance,
    COALESCE(p_description, 'Don Fatmécoins à un artiste'),
    p_donation_id, 'donation',
    'completed', NOW()
  );

  -- Transaction destinataire
  INSERT INTO fatmecoin_transactions (
    user_id, type, amount, fee, net_amount,
    balance_before, balance_after,
    description, reference_id, reference_type,
    status, completed_at
  ) VALUES (
    p_recipient_id, 'donation_received', v_net_amount, 0, v_net_amount,
    v_recipient_balance - v_net_amount, v_recipient_balance,
    'Don Fatmécoins reçu',
    p_donation_id, 'donation',
    'completed', NOW()
  );

  -- Mettre à jour les soldes
  UPDATE fatmecoin_wallets
  SET balance = v_sender_balance,
      lifetime_spent = lifetime_spent + p_amount,
      updated_at = NOW()
  WHERE user_id = p_sender_id;

  UPDATE fatmecoin_wallets
  SET balance = v_recipient_balance,
      lifetime_earned = lifetime_earned + v_net_amount,
      updated_at = NOW()
  WHERE user_id = p_recipient_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;