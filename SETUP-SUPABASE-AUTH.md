# 🔧 Configuration Auth Supabase — Guide Express

## Le problème
Quand tu crées un compte sur Supabase, il envoie un email de confirmation. Tu dois **désactiver cette vérification** pour que l'auth fonctionne directement.

## Étape 1 : Désactiver la confirmation email

1. Va sur **https://supabase.com/dashboard**
2. Sélectionne ton projet **arteia-app**
3. Va dans **Authentication** (menu de gauche)
4. Clique sur **Settings** (⚙️)
5. Dans la section **"User Signups"** :
   - **Disable email confirmations** → Active cette option (bascule à ON)
   - Ou **Auto-confirm users** → Active cette option
6. Clique **Save**

## Étape 2 : Activer Google Auth (optionnel)

1. Dans le même menu **Authentication → Providers**
2. Clique sur **Google**
3. Active-le (bascule vert)
4. Pour obtenir le Client ID et Secret :
   - Va sur **https://console.cloud.google.com**
   - Crée un projet (ou utilise un existant)
   - Va dans **APIs & Services → Credentials**
   - Clique **"Create Credentials" → "OAuth 2.0 Client ID"**
   - Type : **Web application**
   - Dans **"Authorized redirect URIs"** ajoute :
     ```
     https://wzewlweghntnqyfvhgan.supabase.co/auth/v1/callback
     ```
   - Copie le **Client ID** et **Client Secret**
5. Colle-les dans Supabase → Google Provider → Save

## Étape 3 : Exécuter les schémas SQL

1. Dans Supabase, va dans **SQL Editor** (menu de gauche)
2. Clique **"New query"**
3. Copie le contenu de `database/schema.sql` et colle-le
4. Clique **"Run"** (▶️)
5. Répète avec `database/schema-v2.sql`

## Étape 4 : Tester

1. Lance le site : `npm run dev`
2. Va sur http://localhost:5173/connexion.html
3. Essaie de te connecter avec ton email et mot de passe
4. Si ça marche, tu verras "Connecté ! Bienvenue dans Artéïa."

## ⚠️ Si tu veux utiliser Google Auth

Tu dois d'abord :
1. Créer un projet Google Cloud (https://console.cloud.google.com)
2. Activer l'API "Google+ API" ou "People API"
3. Créer un OAuth 2.0 Client ID
4. Configurer les redirect URIs dans Google Cloud
5. Mettre le Client ID et Secret dans Supabase

## Résumé rapide

| Action | Fichier/URL |
|--------|-------------|
| Désactiver confirmation email | Supabase Dashboard → Authentication → Settings |
| Activer Google Auth | Supabase Dashboard → Authentication → Providers → Google |
| Exécuter SQL | Supabase Dashboard → SQL Editor |
| Tester | http://localhost:5173/connexion.html |