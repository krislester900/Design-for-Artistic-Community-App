# Guide d'intégration des paiements - Artéïa

## Comment obtenir les autorisations des applications de paiement

### 1. STRIPE (Recommandé - International)
**Ce qu'il faut :**
- Compte Stripe gratuit : https://dashboard.stripe.com/register
- Pièces d'identité (passeport, carte d'identité)
- IBAN du compte bancaire professionnel
- Numéro SIRET (si entreprise) ou statut auto-entrepreneur

**Étapes :**
1. Créez un compte Stripe
2. Activez votre compte en fournissant les documents
3. Récupérez vos clés API dans le dashboard :
   - `STRIPE_SECRET_KEY` (côté serveur - dans Supabase secrets)
   - `STRIPE_PUBLISHABLE_KEY` (côté client - dans .env)
4. Configurez le webhook Stripe → votre Edge Function Supabase

**Délai :** 24-48h pour la vérification du compte

### 2. PAYPAL
**Ce qu'il faut :**
- Compte PayPal Business : https://www.paypal.com/business
- Pièces d'identité
- Justificatif de domicile
- Numéro SIRET

**Étapes :**
1. Créez un compte PayPal Business
2. Allez dans "Developer Dashboard" : https://developer.paypal.com
3. Créez une application REST API
4. Récupérez `Client ID` et `Secret`
5. Activez les webhooks pour les notifications de paiement

**Délai :** 24-72h

### 3. WAVE (Afrique de l'Ouest - Sénégal, Côte d'Ivoire)
**Ce qu'il faut :**
- Compte Wave Business : https://wave.com/business
- NINEA / RCCM (numéro d'entreprise)
- Pièces d'identité
- Compte bancaire partenaire

**Étapes :**
1. Créez un compte Wave Business
2. Fournissez les documents d'entreprise
3. Obtenez votre `API Key` et `Secret Key`
4. Configurez l'IPN (Instant Payment Notification) URL

**Délai :** 1-2 semaines

### 4. DJAMO (Côte d'Ivoire)
**Ce qu'il faut :**
- Commerçant Djamo : https://djamo.ci/commercant
- NINEA / RCCM
- Pièces d'identité
- Compte bancaire

**Étapes :**
1. Contactez l'équipe Djamo Pro
2. Signez le contrat de partenariat
3. Intégration via leur API REST

**Délai :** 2-4 semaines

### 5. ORANGE MONEY / MTN MONEY (Afrique)
**Ce qu'il faut :**
- Partenaire agrégateur (ex: Cinetic, InTouch, Thunes)
- Ou directement via l'opérateur (Orange, MTN)
- Contrat commercial

**Étapes :**
1. Choisissez un agrégateur (plus simple) :
   - **Cinetic** : https://cinetic.ci
   - **InTouch** : https://intouch.com
   - **Thunes** : https://thunes.com
2. Créez un compte commerçant
3. Intégration via leur API

**Délai :** 2-6 semaines

---

## Configuration dans Supabase

Une fois les clés obtenues, configurez-les dans Supabase :

```bash
# Stripe
supabase secrets set STRIPE_SECRET_KEY=sk_live_xxxxx
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxxxx

# PayPal
supabase secrets set PAYPAL_CLIENT_ID=xxxxx
supabase secrets set PAYPAL_SECRET=xxxxx

# Wave
supabase secrets set WAVE_API_KEY=xxxxx
supabase secrets set WAVE_SECRET_KEY=xxxxx
```

## Architecture des paiements dans Artéïa

```
[App Flutter] → [Supabase Edge Function] → [Stripe/PayPal/Wave API]
                    ↓
            [Base de données]
        (fatmecoin_transactions)
                    ↓
            [Notifications]
        (paiement reçu, etc.)
```

**Flux utilisateur :**
1. L'utilisateur clique "Acheter 10 FC" dans l'app
2. L'app appelle `create-payment-intent` (Edge Function)
3. L'Edge Function crée un PaymentIntent Stripe
4. L'utilisateur paie via Stripe Checkout (dans l'app)
5. Stripe envoie un webhook à Supabase
6. L'Edge Function `stripe-webhook` crédite le wallet
7. L'utilisateur reçoit une notification "10 FC ajoutés !"

## Recommandation pour Artéïa

**Phase 1 (MVP) :** Stripe uniquement (le plus simple, international)
**Phase 2 :** Ajouter PayPal (couverture mondiale)
**Phase 3 :** Wave + Orange Money (Afrique de l'Ouest)
**Phase 4 :** Djamo (Côte d'Ivoire)

Le code est déjà prêt dans :
- `supabase/functions/create-payment-intent/index.ts`
- `arteia_flutter/lib/services/fatmecoin_service.dart`
- `database/schema-fatmecoin.sql`
- `database/schema-payments-authorization.sql`