-- ============================================================
-- Schéma : Paiements, Autorisations & Demandes de Paiement
-- Système complet de monétisation pour Artéïa
-- ============================================================

-- ==================== AUTORISATIONS ====================

-- Types d'autorisations de paiement
CREATE TABLE IF NOT EXISTS payment_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  permission_type TEXT NOT NULL CHECK (permission_type IN (
    'send_donation',      -- Peut envoyer des dons
    'receive_donation',   -- Peut recevoir des dons (artiste)
    'sell_artwork',       -- Peut vendre des oeuvres
    'buy_artwork',        -- Peut acheter des oeuvres
    'commission_request', -- Peut demander des commissions
    'commission_accept',  -- Peut accepter des commissions
    'withdraw_funds',     -- Peut retirer des fonds
    'deposit_funds',      -- Peut deposer des fonds
    'create_subscription',-- Peut creer un abonnement
    'subscribe_artist'    -- Peut s'abonner a un artiste
  )),
  is_granted BOOLEAN NOT NULL DEFAULT true,
  granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  granted_by UUID REFERENCES profiles(id), -- Admin qui a accorde
  expires_at TIMESTAMPTZ,
  reason TEXT,
  UNIQUE(user_id, permission_type)
);

-- Verification si un utilisateur a une permission
CREATE OR REPLACE FUNCTION has_payment_permission(
  p_user_id UUID,
  p_permission TEXT
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM payment_permissions
    WHERE user_id = p_user_id
    AND permission_type = p_permission
    AND is_granted = true
    AND (expires_at IS NULL OR expires_at > NOW())
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================== DEMANDES DE PAIEMENT ====================

-- Demandes de paiement (commissions, achats)
CREATE TABLE IF NOT EXISTS payment_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  recipient_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  request_type TEXT NOT NULL CHECK (request_type IN (
    'commission',     -- Commission artistique
    'artwork_sale',   -- Achat d'oeuvre
    'custom_order',   -- Commande personnalisee
    'licensing',      -- Licence d'utilisation
    'collaboration',  -- Collaboration payante
    'tutorial',       -- Cours/Tutoriel
    'other'
  )),
  title TEXT NOT NULL,
  description TEXT,
  amount_requested DECIMAL(10,2) NOT NULL CHECK (amount_requested > 0),
  currency TEXT NOT NULL DEFAULT 'FC',
  fee_percentage DECIMAL(3,2) NOT NULL DEFAULT 10.00, -- Commission plateforme (%)
  fee_amount DECIMAL(10,2) GENERATED ALWAYS AS (amount_requested * fee_percentage / 100) STORED,
  net_amount DECIMAL(10,2) GENERATED ALWAYS AS (amount_requested - (amount_requested * fee_percentage / 100)) STORED,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'draft',         -- Brouillon
    'pending',       -- En attente d'acceptation
    'accepted',      -- Accepte
    'in_progress',   -- En cours de realisation
    'delivered',     -- Livre
    'completed',     -- Termine et paye
    'cancelled',     -- Annule
    'disputed',      -- En litige
    'refunded'       -- Rembourse
  )),
  deadline TIMESTAMPTZ,
  delivery_notes TEXT,
  is_urgent BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Index
CREATE INDEX IF NOT EXISTS idx_pr_requester ON payment_requests(requester_id);
CREATE INDEX IF NOT EXISTS idx_pr_recipient ON payment_requests(recipient_id);
CREATE INDEX IF NOT EXISTS idx_pr_status ON payment_requests(status);
CREATE INDEX IF NOT EXISTS idx_pr_type ON payment_requests(request_type);

-- Pieces jointes aux demandes
CREATE TABLE IF NOT EXISTS payment_request_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES payment_requests(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_name TEXT,
  uploaded_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Messages dans les demandes (nego)
CREATE TABLE IF NOT EXISTS payment_request_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES payment_requests(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES profiles(id),
  message TEXT NOT NULL,
  is_auto_reply BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==================== ABONNEMENTS ====================

-- Abonnements aux artistes
CREATE TABLE IF NOT EXISTS artist_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscriber_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  artist_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  tier TEXT NOT NULL CHECK (tier IN ('basic', 'premium', 'vip')),
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'EUR',
  interval TEXT NOT NULL DEFAULT 'monthly' CHECK (interval IN ('weekly', 'monthly', 'yearly')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'cancelled', 'expired')),
  stripe_subscription_id TEXT,
  current_period_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  current_period_end TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(subscriber_id, artist_id)
);

CREATE INDEX IF NOT EXISTS idx_sub_subscriber ON artist_subscriptions(subscriber_id);
CREATE INDEX IF NOT EXISTS idx_sub_artist ON artist_subscriptions(artist_id);
CREATE INDEX IF NOT EXISTS idx_sub_status ON artist_subscriptions(status);

-- ==================== RETRAITS ====================

-- Demandes de retrait (artistes -> leur compte bancaire)
CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  fee DECIMAL(10,2) NOT NULL DEFAULT 0,
  net_amount DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'EUR',
  bank_account_name TEXT NOT NULL,
  bank_iban TEXT NOT NULL,
  bank_bic TEXT,
  bank_country TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
    'pending',      -- En attente
    'processing',   -- En cours
    'completed',    -- Effectue
    'failed',       -- Echec
    'cancelled'     -- Annule
  )),
  processed_by UUID REFERENCES profiles(id), -- Admin
  processed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_wr_user ON withdrawal_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_wr_status ON withdrawal_requests(status);

-- ==================== FACTURES ====================

-- Factures generees
CREATE TABLE IF NOT EXISTS invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES profiles(id),
  type TEXT NOT NULL CHECK (type IN ('purchase', 'donation', 'subscription', 'commission', 'withdrawal')),
  reference_id UUID, -- ID de la transaction/paiement associe
  amount DECIMAL(10,2) NOT NULL,
  tax_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'EUR',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'cancelled', 'refunded')),
  pdf_url TEXT,
  sent_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==================== LITIGES ====================

-- Litiges sur les paiements
CREATE TABLE IF NOT EXISTS payment_disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES payment_requests(id) ON DELETE CASCADE,
  opened_by UUID NOT NULL REFERENCES profiles(id),
  reason TEXT NOT NULL,
  description TEXT,
  evidence_urls TEXT[],
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN (
    'open',          -- Ouvert
    'investigating', -- En cours d'investigation
    'resolved',      -- Resolu
    'dismissed'      -- Rejete
  )),
  resolution TEXT,
  resolved_by UUID REFERENCES profiles(id), -- Admin
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==================== FONCTIONS RPC ====================

-- Creer une demande de paiement
CREATE OR REPLACE FUNCTION create_payment_request(
  p_requester_id UUID,
  p_recipient_id UUID,
  p_request_type TEXT,
  p_title TEXT,
  p_description TEXT,
  p_amount DECIMAL,
  p_deadline TIMESTAMPTZ
) RETURNS UUID AS $$
DECLARE
  v_request_id UUID;
BEGIN
  -- Verifier les permissions
  IF NOT has_payment_permission(p_requester_id, 'commission_request') THEN
    RAISE EXCEPTION 'Vous navez pas lautorisation de creer des demandes de paiement';
  END IF;

  INSERT INTO payment_requests (
    requester_id, recipient_id, request_type, title,
    description, amount_requested, deadline, status
  ) VALUES (
    p_requester_id, p_recipient_id, p_request_type, p_title,
    p_description, p_amount, p_deadline, 'pending'
  ) RETURNING id INTO v_request_id;

  -- Notification
  INSERT INTO notifications (user_id, type, title, data)
  VALUES (
    p_recipient_id,
    'payment_request',
    'Nouvelle demande de paiement',
    jsonb_build_object('request_id', v_request_id, 'requester_id', p_requester_id)
  );

  RETURN v_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Accepter/Refuser une demande
CREATE OR REPLACE FUNCTION respond_payment_request(
  p_request_id UUID,
  p_accept BOOLEAN,
  p_message TEXT DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
  v_request payment_requests;
BEGIN
  SELECT * INTO v_request FROM payment_requests WHERE id = p_request_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Demande introuvable';
  END IF;

  IF p_accept THEN
    UPDATE payment_requests SET status = 'accepted', updated_at = NOW()
    WHERE id = p_request_id;

    INSERT INTO payment_request_messages (request_id, sender_id, message, is_auto_reply)
    VALUES (p_request_id, v_request.recipient_id, 'Demande acceptee !', true);
  ELSE
    UPDATE payment_requests SET status = 'cancelled', updated_at = NOW()
    WHERE id = p_request_id;
  END IF;

  -- Notification
  INSERT INTO notifications (user_id, type, title, data)
  VALUES (
    v_request.requester_id,
    CASE WHEN p_accept THEN 'payment_accepted' ELSE 'payment_rejected' END,
    CASE WHEN p_accept THEN 'Votre demande a ete acceptee' ELSE 'Votre demande a ete refusee' END,
    jsonb_build_object('request_id', p_request_id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Confirmer le paiement et transferer les fonds
CREATE OR REPLACE FUNCTION confirm_payment(
  p_request_id UUID,
  p_payment_provider TEXT DEFAULT 'stripe'
) RETURNS VOID AS $$
DECLARE
  v_request payment_requests;
  v_sender_wallet DECIMAL;
  v_receiver_wallet DECIMAL;
BEGIN
  SELECT * INTO v_request FROM payment_requests WHERE id = p_request_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Demande introuvable';
  END IF;

  IF v_request.status NOT IN ('accepted', 'delivered') THEN
    RAISE EXCEPTION 'La demande doit etre acceptee avant le paiement';
  END IF;

  -- Verifier le solde du payeur (si paiement en FC)
  SELECT balance INTO v_sender_wallet
  FROM fatmecoin_wallets WHERE user_id = v_request.requester_id;
  IF v_sender_wallet < v_request.amount_requested THEN
    RAISE EXCEPTION 'Solde insuffisant';
  END IF;

  -- Debiter le payeur
  UPDATE fatmecoin_wallets SET
    balance = balance - v_request.amount_requested,
    lifetime_spent = lifetime_spent + v_request.amount_requested,
    updated_at = NOW()
  WHERE user_id = v_request.requester_id;

  -- Crediter le receveur (net apres commission)
  UPDATE fatmecoin_wallets SET
    balance = balance + v_request.net_amount,
    lifetime_earned = lifetime_earned + v_request.net_amount,
    updated_at = NOW()
  WHERE user_id = v_request.recipient_id;

  -- Enregistrer la transaction du payeur
  INSERT INTO fatmecoin_transactions (
    user_id, type, amount, fee, net_amount,
    balance_before, balance_after, description,
    reference_id, reference_type, status
  ) VALUES (
    v_request.requester_id, 'purchase', v_request.amount_requested, v_request.fee_amount,
    v_request.net_amount, v_sender_wallet,
    v_sender_wallet - v_request.amount_requested,
    'Paiement: ' || v_request.title, v_request.id, 'payment_request', 'completed'
  );

  -- Mettre a jour le statut
  UPDATE payment_requests SET
    status = 'completed',
    completed_at = NOW(),
    updated_at = NOW()
  WHERE id = p_request_id;

  -- Notification
  INSERT INTO notifications (user_id, type, title, data)
  VALUES (
    v_request.recipient_id, 'payment_received',
    'Paiement recu : ' || v_request.amount_requested || ' FC',
    jsonb_build_object('request_id', p_request_id, 'amount', v_request.amount_requested)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==================== RLS POLICIES ====================

-- Payment requests: les participants voient leurs demandes
ALTER TABLE payment_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY pr_select ON payment_requests FOR SELECT
  USING (requester_id = auth.uid() OR recipient_id = auth.uid());

CREATE POLICY pr_insert ON payment_requests FOR INSERT
  WITH CHECK (requester_id = auth.uid());

-- Withdrawals: les users voient leurs propres retraits
ALTER TABLE withdrawal_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY wr_select ON withdrawal_requests FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY wr_insert ON withdrawal_requests FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Invoices: les users voient leurs factures
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;

CREATE POLICY inv_select ON invoices FOR SELECT
  USING (user_id = auth.uid());

-- Disputes: les participants voient les litiges
ALTER TABLE payment_disputes ENABLE ROW LEVEL SECURITY;

CREATE POLICY disp_select ON payment_disputes FOR SELECT
  USING (
    opened_by = auth.uid() OR
    EXISTS (SELECT 1 FROM payment_requests pr
            WHERE pr.id = request_id
            AND (pr.requester_id = auth.uid() OR pr.recipient_id = auth.uid()))
  );